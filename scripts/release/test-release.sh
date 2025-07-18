#!/bin/bash
# Test release in clean virtual environment

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
VENV_DIR=".release-test-env"
WHEEL_FILE=""
TEST_RESULTS=""

# Show usage
show_usage() {
    show_script_usage "$(basename "$0")" "Test Python package release in clean virtual environment" "<project_root> [options]"
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo "  --verbose, -v    Enable verbose output"
    echo "  --dry-run        Show what would be done without executing"
    echo "  --quiet, -q      Suppress non-error output"
    echo "  --venv-dir DIR   Virtual environment directory (default: .release-test-env)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") /path/to/project"
    echo "  $(basename "$0") /path/to/project --verbose"
    echo "  $(basename "$0") /path/to/project --venv-dir /tmp/test-env"
}

# Parse command line arguments
shift  # Skip project root
while [[ $# -gt 0 ]]; do
    case $1 in
        --venv-dir)
            VENV_DIR="$2"
            shift 2
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
    print_verbose "Cleaning up test-release script resources..."
    
    # Clean up test environment
    if [ -d "$VENV_DIR" ]; then
        cleanup_virtual_environment "$VENV_DIR"
    fi
    
    # Remove temporary files
    rm -f pytest.log test-report.txt
}











# Main test function
main() {
    print_unless_quiet "info" "Starting release test process..."
    
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
    
    # Find wheel file
    WHEEL_FILE=$(find_wheel_file "$PROJECT_ROOT")
    if [ $? -ne 0 ]; then
        exit_with_error "Wheel file not found. Build wheel first." 1
    fi
    
    print_unless_quiet "info" "Found wheel file: $WHEEL_FILE"
    
    # Test in isolated environment using shared utilities
    if ! test_in_isolated_environment "$PROJECT_ROOT" "$WHEEL_FILE" "$VENV_DIR"; then
        exit_with_error "Release test failed" 1
    fi
    
    print_unless_quiet "success" "Release test completed successfully!"
    
    return 0
}

# Run main function
main "$@"