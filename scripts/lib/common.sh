#!/bin/bash
# Common functions and utilities for release scripts
# This file should be sourced by other scripts: source scripts/lib/common.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print status messages with color coding
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

# Print formatted header
print_header() {
    local message=$1
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $message${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Print section separator
print_section() {
    local message=$1
    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────${NC}"
    echo -e "${BLUE}  $message${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────${NC}"
    echo ""
}

# Validate project root directory
validate_project_root() {
    local project_root=$1
    
    if [ -z "$project_root" ]; then
        print_status "error" "Project root not provided"
        return 1
    fi
    
    if [ ! -d "$project_root" ]; then
        print_status "error" "Project root not found: $project_root"
        return 1
    fi
    
    return 0
}

# Change to project directory with error handling
change_to_project_root() {
    local project_root=$1
    
    if ! validate_project_root "$project_root"; then
        return 1
    fi
    
    cd "$project_root" || {
        print_status "error" "Cannot change to project directory: $project_root"
        return 1
    }
    
    return 0
}

# Check if a command exists
command_exists() {
    local cmd=$1
    command -v "$cmd" &> /dev/null
}

# Check if we're in a git repository
is_git_repository() {
    git rev-parse --git-dir > /dev/null 2>&1
}

# Check for uncommitted changes
has_uncommitted_changes() {
    ! git diff --quiet || ! git diff --cached --quiet
}

# Get current git branch
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "unknown"
}

# Generate timestamp for logging
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log message with timestamp
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(get_timestamp)
    echo "[$timestamp] [$level] $message" >&2
}

# Exit with error message
exit_with_error() {
    local message=$1
    local exit_code=${2:-1}
    print_status "error" "$message"
    exit $exit_code
}

# Show usage information
show_script_usage() {
    local script_name=$1
    local description=$2
    local usage=$3
    
    echo "Usage: $script_name $usage"
    echo ""
    echo "Description: $description"
    echo ""
}

# Parse common command line flags
parse_common_flags() {
    while [[ $# -gt 0 ]]; do
        case $1 in
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
                # Unknown option, pass back to caller
                break
                ;;
        esac
    done
}

# Print verbose message if verbose mode is enabled
print_verbose() {
    local message=$1
    if [ "$VERBOSE" = "true" ]; then
        print_status "info" "[VERBOSE] $message"
    fi
}

# Print message unless quiet mode is enabled
print_unless_quiet() {
    local status=$1
    local message=$2
    if [ "$QUIET" != "true" ]; then
        print_status "$status" "$message"
    fi
}

# Execute command with dry-run support
execute_command() {
    local cmd=$1
    local description=$2
    
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "[DRY RUN] $description"
        print_status "info" "Would execute: $cmd"
        return 0
    else
        print_verbose "Executing: $cmd"
        eval "$cmd"
        return $?
    fi
}

# Check if file exists and is readable
check_file_exists() {
    local file_path=$1
    local description=${2:-"File"}
    
    if [ ! -f "$file_path" ]; then
        print_status "error" "$description not found: $file_path"
        return 1
    fi
    
    if [ ! -r "$file_path" ]; then
        print_status "error" "$description not readable: $file_path"
        return 1
    fi
    
    return 0
}

# Check if directory exists and is accessible
check_directory_exists() {
    local dir_path=$1
    local description=${2:-"Directory"}
    
    if [ ! -d "$dir_path" ]; then
        print_status "error" "$description not found: $dir_path"
        return 1
    fi
    
    if [ ! -r "$dir_path" ]; then
        print_status "error" "$description not accessible: $dir_path"
        return 1
    fi
    
    return 0
}

# Cleanup function that can be called on script exit
cleanup_on_exit() {
    local exit_code=$?
    
    # Override this function in scripts that need custom cleanup
    if declare -f script_cleanup > /dev/null; then
        script_cleanup
    fi
    
    exit $exit_code
}

# Set up signal handlers for cleanup
setup_signal_handlers() {
    trap cleanup_on_exit EXIT
    trap 'exit_with_error "Script interrupted by user" 130' INT
    trap 'exit_with_error "Script terminated" 143' TERM
}

# Initialize common script environment
init_common_environment() {
    # Set up error handling
    set -e
    set -o pipefail
    
    # Set up signal handlers
    setup_signal_handlers
    
    # Initialize variables
    VERBOSE=${VERBOSE:-false}
    QUIET=${QUIET:-false}
    DRY_RUN=${DRY_RUN:-false}
    SHOW_HELP=${SHOW_HELP:-false}
}

# Print library version info
print_common_lib_info() {
    print_status "info" "Common library loaded - version 1.0.0"
}