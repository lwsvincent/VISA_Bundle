#!/bin/bash
# Sync template project updates to/from target project

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
    echo "Usage: $0 <operation> <target-project-path> [template-project-path]"
    echo ""
    echo "Operations:"
    echo "  pull    Pull updates from template project to target project"
    echo "  push    Push changes from target project back to template project"
    echo ""
    echo "Arguments:"
    echo "  target-project-path    Path to the target project with subtree"
    echo "  template-project-path  Path to template project (optional, defaults to current directory)"
    echo ""
    echo "Examples:"
    echo "  $0 pull ../am_report_generator"
    echo "  $0 push ../am_report_generator"
    echo "  $0 pull /path/to/target/project /path/to/template/project"
}

# Check arguments
if [ $# -lt 2 ]; then
    print_status "error" "Missing required arguments"
    show_usage
    exit 1
fi

OPERATION="$1"
TARGET_PROJECT="$2"
TEMPLATE_PROJECT="${3:-$(pwd)}"
SUBTREE_DIR="template_project"

# Validate operation
if [ "$OPERATION" != "pull" ] && [ "$OPERATION" != "push" ]; then
    print_status "error" "Invalid operation: $OPERATION"
    show_usage
    exit 1
fi

# Validate paths
if [ ! -d "$TARGET_PROJECT" ]; then
    print_status "error" "Target project directory does not exist: $TARGET_PROJECT"
    exit 1
fi

if [ ! -d "$TEMPLATE_PROJECT" ]; then
    print_status "error" "Template project directory does not exist: $TEMPLATE_PROJECT"
    exit 1
fi

# Change to target project directory
cd "$TARGET_PROJECT" || {
    print_status "error" "Cannot change to target project directory"
    exit 1
}

# Check if target is a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_status "error" "Target directory is not a git repository"
    exit 1
fi

# Check if subtree exists
if [ ! -d "$SUBTREE_DIR" ]; then
    print_status "error" "Subtree directory does not exist: $SUBTREE_DIR"
    print_status "info" "Run subtree-add.sh first to add the template project as subtree"
    exit 1
fi

# Get absolute path to template project
TEMPLATE_ABS_PATH=$(cd "$TEMPLATE_PROJECT" && pwd)

# Ensure template project is a git repository
if [ ! -d "$TEMPLATE_ABS_PATH/.git" ]; then
    print_status "error" "Template project is not a git repository"
    exit 1
fi

# Check git status
if ! git diff --quiet || ! git diff --cached --quiet; then
    print_status "warning" "Working directory has uncommitted changes"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "info" "Aborted"
        exit 0
    fi
fi

if [ "$OPERATION" == "pull" ]; then
    print_status "info" "Pulling updates from template project..."
    print_status "info" "Template project: $TEMPLATE_ABS_PATH"
    
    # Determine the main branch and remote URL
    cd "$TEMPLATE_ABS_PATH" || exit 1
    
    # Get remote origin URL
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)
    if [ -z "$REMOTE_URL" ]; then
        print_status "error" "Template project has no remote origin configured"
        print_status "info" "Please add a remote origin to the template project: git remote add origin <url>"
        exit 1
    fi
    
    MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
        MAIN_BRANCH="master"
    fi
    if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
        MAIN_BRANCH=$(git branch --show-current)
    fi
    
    cd "$TARGET_PROJECT" || exit 1
    
    print_status "info" "Using remote URL: $REMOTE_URL"
    print_status "info" "Using branch: $MAIN_BRANCH"
    
    # Pull updates from template project using remote URL
    print_status "info" "Fetching updates from remote repository..."
    if git subtree pull --prefix="$SUBTREE_DIR" --squash "$REMOTE_URL" "$MAIN_BRANCH" 2>&1; then
        print_status "success" "Updates pulled successfully"
        
        # Check if hooks need to be reinstalled
        if [ -f "$SUBTREE_DIR/.git-hooks/install-hooks.sh" ]; then
            print_status "info" "Reinstalling hooks to apply updates..."
            cd "$SUBTREE_DIR" || exit 1
            bash .git-hooks/install-hooks.sh
            cd "$TARGET_PROJECT" || exit 1
            print_status "success" "Hooks reinstalled"
        fi
        
    else
        print_status "error" "Failed to pull updates from remote repository"
        print_status "info" "This might be due to:"
        print_status "info" "  - Network connectivity issues"
        print_status "info" "  - Missing commit references in the remote repository"
        print_status "info" "  - Authentication issues with the remote repository"
        print_status "info" "  - The subtree was not properly initialized"
        print_status "info" ""
        print_status "info" "Try manually running:"
        print_status "info" "  git subtree pull --prefix=$SUBTREE_DIR --squash $REMOTE_URL $MAIN_BRANCH"
        exit 1
    fi
    
elif [ "$OPERATION" == "push" ]; then
    print_status "info" "Pushing changes to template project..."
    print_status "info" "Template project: $TEMPLATE_ABS_PATH"
    
    # Determine the main branch and remote URL
    cd "$TEMPLATE_ABS_PATH" || exit 1
    
    # Get remote origin URL
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)
    if [ -z "$REMOTE_URL" ]; then
        print_status "error" "Template project has no remote origin configured"
        print_status "info" "Please add a remote origin to the template project: git remote add origin <url>"
        exit 1
    fi
    
    MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
        MAIN_BRANCH="master"
    fi
    if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
        MAIN_BRANCH=$(git branch --show-current)
    fi
    
    cd "$TARGET_PROJECT" || exit 1
    
    print_status "info" "Using remote URL: $REMOTE_URL"
    print_status "info" "Using branch: $MAIN_BRANCH"
    
    # Push changes to template project using remote URL
    print_status "info" "Pushing changes to remote repository..."
    if git subtree push --prefix="$SUBTREE_DIR" "$REMOTE_URL" "$MAIN_BRANCH" 2>&1; then
        print_status "success" "Changes pushed successfully"
    else
        print_status "error" "Failed to push changes to remote repository"
        print_status "info" "This might be due to:"
        print_status "info" "  - Network connectivity issues"
        print_status "info" "  - Authentication issues with the remote repository"
        print_status "info" "  - Permission denied to push to the remote repository"
        print_status "info" "  - The subtree was not properly initialized"
        print_status "info" ""
        print_status "info" "Try manually running:"
        print_status "info" "  git subtree push --prefix=$SUBTREE_DIR $REMOTE_URL $MAIN_BRANCH"
        exit 1
    fi
fi

print_status "info" "Sync operation completed"
print_status "info" "Remember to commit any changes in the target project if needed"