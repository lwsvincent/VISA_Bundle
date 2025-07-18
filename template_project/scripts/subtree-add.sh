#!/bin/bash
# Add template project as subtree to target project

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
    echo "Usage: $0 <target-project-path> [template-project-path]"
    echo ""
    echo "Arguments:"
    echo "  target-project-path    Path to the target project where template will be added"
    echo "  template-project-path  Path to template project (optional, defaults to current directory)"
    echo ""
    echo "Examples:"
    echo "  $0 ../am_report_generator"
    echo "  $0 /path/to/target/project /path/to/template/project"
}

# Check arguments
if [ $# -lt 1 ]; then
    print_status "error" "Missing required argument: target-project-path"
    show_usage
    exit 1
fi

TARGET_PROJECT="$1"
TEMPLATE_PROJECT="${2:-$(pwd)}"
SUBTREE_DIR="template_project"

# Validate paths
if [ ! -d "$TARGET_PROJECT" ]; then
    print_status "error" "Target project directory does not exist: $TARGET_PROJECT"
    exit 1
fi

if [ ! -d "$TEMPLATE_PROJECT" ]; then
    print_status "error" "Template project directory does not exist: $TEMPLATE_PROJECT"
    exit 1
fi

# Check if template project has the expected structure
if [ ! -f "$TEMPLATE_PROJECT/.git-hooks/pre-push" ]; then
    print_status "error" "Template project does not have expected structure (missing .git-hooks/pre-push)"
    exit 1
fi

print_status "info" "Adding template project as subtree to target project..."
print_status "info" "Target project: $TARGET_PROJECT"
print_status "info" "Template project: $TEMPLATE_PROJECT"

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

# Check if subtree already exists
if [ -d "$SUBTREE_DIR" ]; then
    print_status "warning" "Subtree directory already exists: $SUBTREE_DIR"
    read -p "Do you want to remove it and re-add? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$SUBTREE_DIR"
        print_status "info" "Removed existing subtree directory"
    else
        print_status "info" "Aborted"
        exit 0
    fi
fi

# Get absolute path to template project
TEMPLATE_ABS_PATH=$(cd "$TEMPLATE_PROJECT" && pwd)

# Initialize template project as git repository if it's not already
if [ ! -d "$TEMPLATE_ABS_PATH/.git" ]; then
    print_status "info" "Initializing template project as git repository..."
    cd "$TEMPLATE_ABS_PATH" || exit 1
    git init
    git add .
    git commit -m "Initial commit of template project"
    cd "$TARGET_PROJECT" || exit 1
fi

# Add template project as subtree
print_status "info" "Adding subtree..."
if git subtree add --prefix="$SUBTREE_DIR" --squash "$TEMPLATE_ABS_PATH" master 2>/dev/null || \
   git subtree add --prefix="$SUBTREE_DIR" --squash "$TEMPLATE_ABS_PATH" main 2>/dev/null; then
    print_status "success" "Template project added as subtree successfully"
else
    print_status "error" "Failed to add subtree"
    exit 1
fi

# Verify subtree was added correctly
if [ -f "$SUBTREE_DIR/.git-hooks/pre-push" ]; then
    print_status "success" "Subtree structure verified"
else
    print_status "error" "Subtree structure verification failed"
    exit 1
fi

print_status "info" "Next steps:"
echo "1. Run: cd $TARGET_PROJECT/$SUBTREE_DIR && ./scripts/setup-project.sh"
echo "2. Customize config/pre-push-rules.yml for your project"
echo "3. Start using the template project features"

print_status "success" "Template project subtree setup completed!"