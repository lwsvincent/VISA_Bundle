#!/bin/bash
# Unified subtree manager for template project
# Supports add, pull, push operations

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

print_header() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Template Project Subtree Manager${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo ""
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <operation> <target-project-path> [template-project-path]"
    echo ""
    echo "Operations:"
    echo "  add     Add template project as subtree to target project"
    echo "  pull    Pull updates from template project to target project"
    echo "  push    Push changes from target project back to template project"
    echo ""
    echo "Arguments:"
    echo "  target-project-path    Path to the target project"
    echo "  template-project-path  Path to template project (optional, defaults to current directory)"
    echo ""
    echo "Examples:"
    echo "  $0 add ../my_project                    # Add template as subtree"
    echo "  $0 pull ../my_project                   # Pull template updates"
    echo "  $0 push ../my_project                   # Push changes back to template"
    echo "  $0 add /path/to/project /path/to/template"
    echo ""
    echo "Notes:"
    echo "  - For 'add': Target project must be a git repository"
    echo "  - For 'pull'/'push': Subtree must already exist in target project"
    echo "  - Template project will be added/accessed as 'template_project/' subdirectory"
}

# Validate arguments
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
if [[ ! "$OPERATION" =~ ^(add|pull|push)$ ]]; then
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

# Get absolute paths
TARGET_ABS_PATH=$(cd "$TARGET_PROJECT" && pwd)
TEMPLATE_ABS_PATH=$(cd "$TEMPLATE_PROJECT" && pwd)

print_header
print_status "info" "Operation: $OPERATION"
print_status "info" "Target project: $TARGET_ABS_PATH"
print_status "info" "Template project: $TEMPLATE_ABS_PATH"
echo ""

# Check if target is a git repository
cd "$TARGET_PROJECT" || {
    print_status "error" "Cannot change to target project directory"
    exit 1
}

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_status "error" "Target directory is not a git repository"
    exit 1
fi

# Function to determine main branch
get_main_branch() {
    local repo_path="$1"
    cd "$repo_path" || return 1
    
    # Try to get main branch from remote
    local main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    
    # If no remote, check for common main branch names
    if [ -z "$main_branch" ]; then
        if git show-ref --verify --quiet "refs/heads/main"; then
            main_branch="main"
        elif git show-ref --verify --quiet "refs/heads/master"; then
            main_branch="master"
        else
            main_branch=$(git branch --show-current)
        fi
    fi
    
    echo "$main_branch"
}

# Function to initialize template project as git repo if needed
init_template_git() {
    if [ ! -d "$TEMPLATE_ABS_PATH/.git" ]; then
        print_status "info" "Initializing template project as git repository..."
        cd "$TEMPLATE_ABS_PATH" || return 1
        git init
        git add .
        git commit -m "Initial commit of template project"
        print_status "success" "Template project initialized as git repository"
    fi
}

# Function to check git status and warn about uncommitted changes
check_git_status() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_status "warning" "Working directory has uncommitted changes"
        git status --porcelain | head -5
        echo ""
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "info" "Operation aborted by user"
            exit 0
        fi
        echo ""
    fi
}

# ADD operation
if [ "$OPERATION" == "add" ]; then
    print_status "info" "Adding template project as subtree..."
    
    # Check if template project has expected structure
    if [ ! -f "$TEMPLATE_PROJECT/.git-hooks/pre-push" ]; then
        print_status "error" "Template project does not have expected structure (missing .git-hooks/pre-push)"
        exit 1
    fi
    
    # Check if subtree already exists
    if [ -d "$SUBTREE_DIR" ]; then
        print_status "warning" "Subtree directory already exists: $SUBTREE_DIR"
        read -p "Do you want to remove it and re-add? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$SUBTREE_DIR"
            print_status "info" "Removed existing subtree directory"
        else
            print_status "info" "Operation aborted by user"
            exit 0
        fi
    fi
    
    # Initialize template project as git repository if needed
    init_template_git
    
    # Get main branch from template project
    MAIN_BRANCH=$(get_main_branch "$TEMPLATE_ABS_PATH")
    cd "$TARGET_PROJECT" || exit 1
    
    print_status "info" "Adding subtree from branch: $MAIN_BRANCH"
    
    # Add template project as subtree
    if git subtree add --prefix="$SUBTREE_DIR" --squash "$TEMPLATE_ABS_PATH" "$MAIN_BRANCH"; then
        print_status "success" "Template project added as subtree successfully"
        
        # Verify subtree was added correctly
        if [ -f "$SUBTREE_DIR/.git-hooks/pre-push" ]; then
            print_status "success" "Subtree structure verified"
        else
            print_status "warning" "Subtree structure verification failed"
        fi
        
        echo ""
        print_status "info" "Next steps:"
        echo "  1. Run: cd $TARGET_ABS_PATH/$SUBTREE_DIR && ./scripts/setup-project.sh"
        echo "  2. Customize config/pre-push-rules.yml for your project"
        echo "  3. Start using the template project features"
        echo ""
        print_status "success" "🎉 Template project subtree setup completed!"
        
    else
        print_status "error" "Failed to add subtree"
        exit 1
    fi

# PULL operation
elif [ "$OPERATION" == "pull" ]; then
    print_status "info" "Pulling updates from template project..."
    
    # Check if subtree exists
    if [ ! -d "$SUBTREE_DIR" ]; then
        print_status "error" "Subtree directory does not exist: $SUBTREE_DIR"
        print_status "info" "Run '$0 add <target-project>' first to add the template project as subtree"
        exit 1
    fi
    
    # Ensure template project is a git repository
    if [ ! -d "$TEMPLATE_ABS_PATH/.git" ]; then
        print_status "error" "Template project is not a git repository"
        exit 1
    fi
    
    # Check git status
    check_git_status
    
    # Get main branch from template project
    MAIN_BRANCH=$(get_main_branch "$TEMPLATE_ABS_PATH")
    
    print_status "info" "Pulling from branch: $MAIN_BRANCH"
    
    # Pull updates from template project
    if git subtree pull --prefix="$SUBTREE_DIR" --squash "$TEMPLATE_ABS_PATH" "$MAIN_BRANCH"; then
        print_status "success" "Updates pulled successfully"
        
        # Check if hooks need to be reinstalled
        if [ -f "$SUBTREE_DIR/.git-hooks/install-hooks.sh" ]; then
            print_status "info" "Reinstalling hooks to apply updates..."
            cd "$SUBTREE_DIR" || exit 1
            bash .git-hooks/install-hooks.sh
            cd "$TARGET_PROJECT" || exit 1
            print_status "success" "Hooks reinstalled"
        fi
        
        echo ""
        print_status "success" "🎉 Template updates pulled successfully!"
        
    else
        print_status "error" "Failed to pull updates"
        print_status "info" "This might be due to merge conflicts. Please resolve manually."
        exit 1
    fi

# PUSH operation
elif [ "$OPERATION" == "push" ]; then
    print_status "info" "Pushing changes to template project..."
    
    # Check if subtree exists
    if [ ! -d "$SUBTREE_DIR" ]; then
        print_status "error" "Subtree directory does not exist: $SUBTREE_DIR"
        print_status "info" "Nothing to push back to template project"
        exit 1
    fi
    
    # Ensure template project is a git repository
    if [ ! -d "$TEMPLATE_ABS_PATH/.git" ]; then
        print_status "error" "Template project is not a git repository"
        exit 1
    fi
    
    # Check git status
    check_git_status
    
    # Get main branch from template project
    MAIN_BRANCH=$(get_main_branch "$TEMPLATE_ABS_PATH")
    
    print_status "info" "Pushing to branch: $MAIN_BRANCH"
    
    # Push changes to template project
    if git subtree push --prefix="$SUBTREE_DIR" "$TEMPLATE_ABS_PATH" "$MAIN_BRANCH"; then
        print_status "success" "Changes pushed successfully"
        echo ""
        print_status "success" "🎉 Changes pushed to template project!"
        
    else
        print_status "error" "Failed to push changes"
        print_status "info" "This might be due to conflicts or permission issues."
        exit 1
    fi
fi

echo ""
print_status "info" "Subtree operation completed"
print_status "info" "Remember to commit any changes in the target project if needed"