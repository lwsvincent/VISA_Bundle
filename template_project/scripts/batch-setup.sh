#!/bin/bash
# Batch setup template project across multiple projects

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
    echo "  -n, --dry-run        Show what would be done without executing"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Config file format (batch-config.yml):"
    echo "projects:"
    echo "  - path: '/path/to/project1'"
    echo "    name: 'project1'"
    echo "    type: 'python'"
    echo "  - path: '/path/to/project2'"
    echo "    name: 'project2'"
    echo "    type: 'javascript'"
}

# Default values
CONFIG_FILE="batch-config.yml"
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
    
    # Create example config file
    print_status "info" "Creating example config file: $CONFIG_FILE"
    cat > "$CONFIG_FILE" << 'EOF'
# Batch setup configuration
projects:
  - path: '../am_report_generator'
    name: 'am_report_generator'
    type: 'python'
    enabled: true
    
  - path: '../am_shared'
    name: 'am_shared'
    type: 'python'
    enabled: true
    
  - path: '../gui_export_single_report'
    name: 'gui_export_single_report'
    type: 'javascript'
    enabled: true
    
  - path: '../testmatrix_repo'
    name: 'testmatrix_repo'
    type: 'mixed'
    enabled: false

# Global settings
settings:
  backup_before_setup: true
  continue_on_error: true
  parallel_processing: false
  
# Per-project type settings
python_settings:
  install_dev_dependencies: true
  setup_virtual_env: false
  
javascript_settings:
  install_dev_dependencies: true
  setup_package_json: false
EOF
    
    print_status "info" "Please edit $CONFIG_FILE and run again"
    exit 1
fi

# Simple YAML parser (basic functionality)
parse_yaml() {
    local file="$1"
    local projects=()
    
    # Extract project paths (simple parsing)
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

# Read projects from config
PROJECTS=($(parse_yaml "$CONFIG_FILE"))

if [ ${#PROJECTS[@]} -eq 0 ]; then
    print_status "error" "No projects found in config file"
    exit 1
fi

print_status "info" "Found ${#PROJECTS[@]} projects in config"

# Process each project
for project_path in "${PROJECTS[@]}"; do
    print_status "info" "Processing project: $project_path"
    
    # Expand relative paths
    if [[ $project_path =~ ^\.\. ]]; then
        project_path="$(cd "$TEMPLATE_PROJECT" && cd "$project_path" && pwd)"
    fi
    
    # Check if project exists
    if [ ! -d "$project_path" ]; then
        print_status "error" "Project directory not found: $project_path"
        continue
    fi
    
    # Check if it's a git repository
    if [ ! -d "$project_path/.git" ]; then
        print_status "warning" "Not a git repository: $project_path"
        continue
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "info" "Would setup template project in: $project_path"
        continue
    fi
    
    # Backup if requested
    if [ "$VERBOSE" = true ]; then
        print_status "info" "Setting up template project in: $project_path"
    fi
    
    # Check if template project already exists
    if [ -d "$project_path/template_project" ]; then
        print_status "warning" "Template project already exists in: $project_path"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Update existing installation
            if "$TEMPLATE_PROJECT/scripts/subtree-sync.sh" pull "$project_path"; then
                print_status "success" "Updated template project in: $project_path"
            else
                print_status "error" "Failed to update template project in: $project_path"
            fi
        else
            print_status "info" "Skipped: $project_path"
        fi
    else
        # Fresh installation
        if "$TEMPLATE_PROJECT/scripts/subtree-add.sh" "$project_path"; then
            print_status "success" "Added template project to: $project_path"
            
            # Setup the project
            if (cd "$project_path/template_project" && ./scripts/setup-project.sh); then
                print_status "success" "Setup completed for: $project_path"
            else
                print_status "error" "Setup failed for: $project_path"
            fi
        else
            print_status "error" "Failed to add template project to: $project_path"
        fi
    fi
    
    echo ""
done

print_status "success" "Batch setup completed!"
print_status "info" "Next steps for each project:"
echo "1. Review and customize template_project/config/pre-push-rules.yml"
echo "2. Test the setup with: git push"
echo "3. Explore AI prompts in template_project/.ai-prompts/"