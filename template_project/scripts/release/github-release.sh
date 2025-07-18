#!/bin/bash
# Create GitHub release and upload assets

# Load shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/project-utils.sh"
source "$SCRIPT_DIR/../lib/github-utils.sh"

# Initialize common environment
init_common_environment

# Configuration
PROJECT_ROOT="$1"
VERSION=""
PRERELEASE="false"

# Show usage
show_usage() {
    show_script_usage "$(basename "$0")" "Create GitHub release and upload assets" "<project_root> [version] [options]"
    echo "Arguments:"
    echo "  project_root     Path to the Python project"
    echo "  version          Version to release (optional, will auto-detect)"
    echo ""
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo "  --verbose, -v    Enable verbose output"
    echo "  --dry-run        Show what would be done without executing"
    echo "  --quiet, -q      Suppress non-error output"
    echo "  --prerelease     Mark release as prerelease"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") /path/to/project"
    echo "  $(basename "$0") /path/to/project 1.2.3"
    echo "  $(basename "$0") /path/to/project --prerelease"
}

# Parse command line arguments
shift  # Skip project root
while [[ $# -gt 0 ]]; do
    case $1 in
        --prerelease)
            PRERELEASE="true"
            shift
            ;;
        --help|-h)
            SHOW_HELP="true"
            shift
            ;;
        --verbose|-v)
            VERBOSE="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --quiet|-q)
            QUIET="true"
            shift
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$1"
            fi
            shift
            ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = "true" ]; then
    show_usage
    exit 0
fi

# Check if project root is provided
if [ -z "$PROJECT_ROOT" ]; then
    print_status "error" "Project root not provided"
    show_usage
    exit 1
fi

# Script cleanup function
script_cleanup() {
    print_verbose "Cleaning up github-release script resources..."
    # Add any script-specific cleanup here
}

# Get or validate version
get_release_version() {
    if [ -z "$VERSION" ]; then
        print_status "info" "Auto-detecting project version..."
        VERSION=$(get_project_version "$PROJECT_ROOT")
        if [ $? -ne 0 ]; then
            return 1
        fi
    else
        print_status "info" "Using provided version: $VERSION"
    fi
    
    print_status "success" "Release version: $VERSION"
    return 0
}







# Main function
main() {
    print_unless_quiet "info" "Starting GitHub release process..."
    
    # Validate project root
    if ! validate_project_root "$PROJECT_ROOT"; then
        exit 1
    fi
    
    # Change to project directory
    if ! change_to_project_root "$PROJECT_ROOT"; then
        exit 1
    fi
    
    # Show project info in verbose mode
    if [ "$VERBOSE" = "true" ]; then
        print_project_info "$PROJECT_ROOT"
    fi
    
    # Get or validate version
    if ! get_release_version; then
        exit_with_error "Failed to determine release version" 1
    fi
    
    # Create GitHub release using shared utilities
    if ! create_github_release "$PROJECT_ROOT" "$VERSION" "$PRERELEASE"; then
        exit_with_error "GitHub release creation failed" 1
    fi
    
    print_unless_quiet "success" "GitHub release process completed successfully!"
    
    return 0
}

# Run main function
main "$@"