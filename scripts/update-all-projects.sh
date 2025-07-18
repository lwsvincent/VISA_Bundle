#!/bin/bash
# Update template project across all configured projects

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
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c, --config FILE    Use specific config file (default: batch-config.yml)"
    echo "  -p, --parallel       Run updates in parallel"
    echo "  -n, --dry-run        Show what would be done without executing"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "This script updates the template project in all configured projects."
}

# Default values
CONFIG_FILE="batch-config.yml"
PARALLEL=false
DRY_RUN=false
VERBOSE=false
TEMPLATE_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -p|--parallel)
            PARALLEL=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
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

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_status "error" "Config file not found: $CONFIG_FILE"
    print_status "info" "Run batch-setup.sh first to create the config file"
    exit 1
fi

# Simple YAML parser to extract project paths
parse_yaml() {
    local file="$1"
    local projects=()
    
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*-[[:space:]]*path:[[:space:]]*[\'\"]*([^\'\"]*)[\'\"]* ]]; then
            local path="${BASH_REMATCH[1]}"
            if [[ $path =~ ^[\'\"](.*)[\'\"]*$ ]]; then
                path="${BASH_REMATCH[1]}"
            fi
            projects+=("$path")
        fi
    done < "$file"
    
    printf '%s\n' "${projects[@]}"
}

# Function to update a single project
update_project() {
    local project_path="$1"
    local project_name=$(basename "$project_path")
    
    # Expand relative paths
    if [[ $project_path =~ ^\.\. ]]; then
        project_path="$(cd "$TEMPLATE_PROJECT" && cd "$project_path" && pwd)"
    fi
    
    print_status "info" "Updating $project_name..."
    
    # Check if project exists
    if [ ! -d "$project_path" ]; then
        print_status "error" "Project directory not found: $project_path"
        return 1
    fi
    
    # Check if template project exists in the project
    if [ ! -d "$project_path/template_project" ]; then
        print_status "warning" "Template project not found in: $project_path"
        print_status "info" "Run batch-setup.sh to add template project first"
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "info" "Would update template project in: $project_path"
        return 0
    fi
    
    # Perform the update
    if "$TEMPLATE_PROJECT/scripts/subtree-sync.sh" pull "$project_path"; then
        print_status "success" "Updated $project_name"
        
        # Re-run setup to apply any new configurations
        if (cd "$project_path/template_project" && ./scripts/setup-project.sh > /dev/null 2>&1); then
            print_status "success" "Re-setup completed for $project_name"
        else
            print_status "warning" "Re-setup had issues for $project_name"
        fi
        
        return 0
    else
        print_status "error" "Failed to update $project_name"
        return 1
    fi
}

# Read projects from config
PROJECTS=($(parse_yaml "$CONFIG_FILE"))

if [ ${#PROJECTS[@]} -eq 0 ]; then
    print_status "error" "No projects found in config file"
    exit 1
fi

print_status "info" "Updating template project in ${#PROJECTS[@]} projects..."

# Track results
SUCCESSFUL_UPDATES=0
FAILED_UPDATES=0

if [ "$PARALLEL" = true ]; then
    print_status "info" "Running updates in parallel..."
    
    # Create temporary directory for parallel processing
    TEMP_DIR=$(mktemp -d)
    
    # Start all updates in background
    for project_path in "${PROJECTS[@]}"; do
        (
            update_project "$project_path"
            echo $? > "$TEMP_DIR/$(basename "$project_path").result"
        ) &
    done
    
    # Wait for all processes to complete
    wait
    
    # Collect results
    for project_path in "${PROJECTS[@]}"; do
        project_name=$(basename "$project_path")
        result_file="$TEMP_DIR/$project_name.result"
        
        if [ -f "$result_file" ]; then
            result=$(cat "$result_file")
            if [ "$result" -eq 0 ]; then
                ((SUCCESSFUL_UPDATES++))
            else
                ((FAILED_UPDATES++))
            fi
        else
            ((FAILED_UPDATES++))
        fi
    done
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
else
    print_status "info" "Running updates sequentially..."
    
    # Process each project sequentially
    for project_path in "${PROJECTS[@]}"; do
        if update_project "$project_path"; then
            ((SUCCESSFUL_UPDATES++))
        else
            ((FAILED_UPDATES++))
        fi
        echo ""
    done
fi

# Summary
print_status "success" "Update completed!"
print_status "info" "Results:"
echo "  - Successful updates: $SUCCESSFUL_UPDATES"
echo "  - Failed updates: $FAILED_UPDATES"
echo "  - Total projects: ${#PROJECTS[@]}"

if [ $FAILED_UPDATES -gt 0 ]; then
    print_status "warning" "Some updates failed. Check the output above for details."
    exit 1
else
    print_status "success" "All projects updated successfully!"
fi