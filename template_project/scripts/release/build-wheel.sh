#!/bin/bash
# Build wheel package for release

# Load shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/project-utils.sh"
source "$SCRIPT_DIR/../lib/build-utils.sh"
source "$SCRIPT_DIR/../lib/venv-utils.sh"

# Initialize common environment
init_common_environment

# Configuration
PROJECT_ROOT="$1"
WHEEL_FILE=""
BUILD_SYSTEM=""

# Show usage
show_usage() {
    show_script_usage "$(basename "$0")" "Build wheel package for Python project" "<project_root> [options]"
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo "  --verbose, -v    Enable verbose output"
    echo "  --dry-run        Show what would be done without executing"
    echo "  --quiet, -q      Suppress non-error output"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") /path/to/project"
    echo "  $(basename "$0") /path/to/project --verbose"
}

# Parse command line arguments
parse_common_flags "$@"

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
    print_verbose "Cleaning up build script resources..."
    # Add any script-specific cleanup here
}


# Main build function
main() {
    print_unless_quiet "info" "Starting wheel build process..."
    
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
    
    # Build the project using shared utilities
    if ! build_project "$PROJECT_ROOT"; then
        exit_with_error "Build failed" 1
    fi
    
    # Find the wheel file
    WHEEL_FILE=$(find_wheel_file "$PROJECT_ROOT")
    if [ $? -ne 0 ]; then
        exit_with_error "Wheel file not found" 1
    fi
    
    print_unless_quiet "success" "Wheel build completed successfully!"
    print_unless_quiet "info" "Wheel file: $WHEEL_FILE"
    
    return 0
}

# Run main function
main "$@"