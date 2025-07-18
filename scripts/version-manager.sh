#!/bin/bash
# Version management for template project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    case $status in
        "success") echo -e "${GREEN}✓${NC} $message" ;;
        "error") echo -e "${RED}✗${NC} $message" ;;
        "warning") echo -e "${YELLOW}⚠${NC} $message" ;;
        "info") echo -e "${BLUE}ℹ${NC} $message" ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  tag <version>        Create a new version tag"
    echo "  list                 List all version tags"
    echo "  deploy <version>     Deploy specific version to projects"
    echo "  current              Show current version"
    echo "  changelog            Generate changelog"
    echo ""
    echo "Options:"
    echo "  -c, --config FILE    Use specific config file (default: batch-config.yml)"
    echo "  -m, --message MSG    Tag message (for tag command)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 tag v1.0.0 -m 'Initial release'"
    echo "  $0 deploy v1.0.0"
    echo "  $0 list"
}

# Default values
CONFIG_FILE="batch-config.yml"
TAG_MESSAGE=""
TEMPLATE_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse command line arguments
COMMAND=""
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        tag|list|deploy|current|changelog)
            COMMAND="$1"
            if [ "$COMMAND" = "tag" ] || [ "$COMMAND" = "deploy" ]; then
                VERSION="$2"
                shift 2
            else
                shift
            fi
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -m|--message)
            TAG_MESSAGE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_status "error" "Not in a git repository"
    exit 1
fi

# Change to template project directory
cd "$TEMPLATE_PROJECT" || exit 1

case $COMMAND in
    "tag")
        if [ -z "$VERSION" ]; then
            print_status "error" "Version required for tag command"
            show_usage
            exit 1
        fi
        
        # Validate version format
        if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            print_status "error" "Invalid version format. Use vX.Y.Z (e.g., v1.0.0)"
            exit 1
        fi
        
        # Check if tag already exists
        if git tag -l | grep -q "^$VERSION$"; then
            print_status "error" "Tag $VERSION already exists"
            exit 1
        fi
        
        # Check for uncommitted changes
        if ! git diff --quiet || ! git diff --cached --quiet; then
            print_status "error" "Working directory has uncommitted changes"
            exit 1
        fi
        
        # Create tag
        if [ -n "$TAG_MESSAGE" ]; then
            git tag -a "$VERSION" -m "$TAG_MESSAGE"
        else
            git tag -a "$VERSION" -m "Release $VERSION"
        fi
        
        print_status "success" "Created tag: $VERSION"
        print_status "info" "Run 'git push origin $VERSION' to push the tag"
        ;;
        
    "list")
        print_status "info" "Available version tags:"
        git tag -l | sort -V
        ;;
        
    "deploy")
        if [ -z "$VERSION" ]; then
            print_status "error" "Version required for deploy command"
            show_usage
            exit 1
        fi
        
        # Check if tag exists
        if ! git tag -l | grep -q "^$VERSION$"; then
            print_status "error" "Tag $VERSION does not exist"
            exit 1
        fi
        
        # Check if config file exists
        if [ ! -f "$CONFIG_FILE" ]; then
            print_status "error" "Config file not found: $CONFIG_FILE"
            exit 1
        fi
        
        print_status "info" "Deploying version $VERSION to projects..."
        
        # Simple YAML parser to extract project paths
        while IFS= read -r line; do
            if [[ $line =~ ^[[:space:]]*-[[:space:]]*path:[[:space:]]*[\'\"]*([^\'\"]*)[\'\"]* ]]; then
                local path="${BASH_REMATCH[1]}"
                if [[ $path =~ ^[\'\"](.*)[\'\"]*$ ]]; then
                    path="${BASH_REMATCH[1]}"
                fi
                
                # Expand relative paths
                if [[ $path =~ ^\.\. ]]; then
                    path="$(cd "$TEMPLATE_PROJECT" && cd "$path" && pwd)"
                fi
                
                print_status "info" "Updating $(basename "$path") to $VERSION..."
                
                # Check if project has template_project
                if [ ! -d "$path/template_project" ]; then
                    print_status "warning" "Template project not found in: $path"
                    continue
                fi
                
                # Update to specific version
                cd "$path" || continue
                if git subtree pull --prefix=template_project "$TEMPLATE_PROJECT" "$VERSION" --squash; then
                    print_status "success" "Updated $(basename "$path") to $VERSION"
                else
                    print_status "error" "Failed to update $(basename "$path")"
                fi
                cd "$TEMPLATE_PROJECT" || exit 1
            fi
        done < "$CONFIG_FILE"
        
        print_status "success" "Deployment completed"
        ;;
        
    "current")
        # Show current version (latest tag)
        CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
        if [ -n "$CURRENT_TAG" ]; then
            print_status "info" "Current version: $CURRENT_TAG"
        else
            print_status "info" "No version tags found"
        fi
        
        # Show commit info
        COMMIT_HASH=$(git rev-parse --short HEAD)
        COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")
        print_status "info" "Current commit: $COMMIT_HASH - $COMMIT_MESSAGE"
        ;;
        
    "changelog")
        print_status "info" "Generating changelog..."
        
        # Get all tags sorted by version
        TAGS=($(git tag -l | sort -V))
        
        if [ ${#TAGS[@]} -eq 0 ]; then
            print_status "warning" "No tags found"
            exit 0
        fi
        
        echo "# Changelog"
        echo ""
        
        # Generate changelog for each version
        for i in "${!TAGS[@]}"; do
            TAG="${TAGS[$i]}"
            TAG_DATE=$(git log -1 --format="%ai" "$TAG" | cut -d' ' -f1)
            
            echo "## $TAG ($TAG_DATE)"
            echo ""
            
            # Get range for git log
            if [ $i -eq 0 ]; then
                # First tag, show all commits up to it
                RANGE="$TAG"
            else
                # Show commits between previous tag and current tag
                PREV_TAG="${TAGS[$((i-1))]}"
                RANGE="$PREV_TAG..$TAG"
            fi
            
            # Show commits in this range
            git log --pretty=format:"- %s (%h)" "$RANGE" --reverse
            echo ""
            echo ""
        done
        
        # Show unreleased changes
        LATEST_TAG="${TAGS[-1]}"
        UNRELEASED=$(git log --pretty=format:"- %s (%h)" "$LATEST_TAG..HEAD" --reverse)
        
        if [ -n "$UNRELEASED" ]; then
            echo "## Unreleased"
            echo ""
            echo "$UNRELEASED"
            echo ""
        fi
        ;;
        
    *)
        print_status "error" "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac