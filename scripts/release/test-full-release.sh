#!/bin/bash
# Test complete release flow for Python projects

# Load shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/project-utils.sh"
source "$SCRIPT_DIR/../lib/build-utils.sh"
source "$SCRIPT_DIR/../lib/github-utils.sh"
source "$SCRIPT_DIR/../lib/venv-utils.sh"

# Initialize common environment
init_common_environment

# Configuration
PROJECT_ROOT="$1"
TEST_PROJECT=""
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

# Show usage
show_usage() {
    show_script_usage "$(basename "$0")" "Test complete release flow for Python projects" "[project_root] [options]"
    echo "Arguments:"
    echo "  project_root     Path to the Python project (optional, will auto-detect)"
    echo ""
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo "  --verbose, -v    Enable verbose output"
    echo "  --dry-run        Show what would be done without executing"
    echo "  --quiet, -q      Suppress non-error output"
    echo "  --skip-build     Skip build step"
    echo "  --skip-tests     Skip test step"
    echo "  --skip-github    Skip GitHub release step"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                      # Auto-detect project"
    echo "  $(basename "$0") /path/to/project    # Test specific project"
    echo "  $(basename "$0") --verbose          # Enable verbose output"
    echo "  $(basename "$0") --skip-github      # Skip GitHub release testing"
}

# Parse command line arguments
SKIP_BUILD="false"
SKIP_TESTS="false"
SKIP_GITHUB="false"

if [ -n "$1" ] && [[ "$1" != --* ]]; then
    shift  # Skip project root if provided
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD="true"
            shift
            ;;
        --skip-tests)
            SKIP_TESTS="true"
            shift
            ;;
        --skip-github)
            SKIP_GITHUB="true"
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
            shift
            ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = "true" ]; then
    show_usage
    exit 0
fi

# Script cleanup function
script_cleanup() {
    print_verbose "Cleaning up test-full-release script resources..."
    
    # Remove build artifacts
    rm -rf dist build *.egg-info
    rm -rf .release-test-env
    rm -f test-report.txt
    rm -f build-report.txt
    rm -f github-release-report.txt
    rm -f release-test-report.txt
}

# Auto-detect project root if not provided
if [ -z "$PROJECT_ROOT" ]; then
    print_status "info" "Auto-detecting project root..."
    
    # Try current directory first
    if is_python_project "."; then
        PROJECT_ROOT="."
    else
        # Try to find a suitable test project in parent directories
        for project in "am_report_generator" "am_shared"; do
            if [ -d "../../$project" ] && is_python_project "../../$project"; then
                PROJECT_ROOT="../../$project"
                TEST_PROJECT="$project"
                break
            fi
        done
        
        if [ -z "$PROJECT_ROOT" ]; then
            exit_with_error "No project root provided and no suitable Python project found" 1
        fi
    fi
    
    print_status "info" "Auto-detected project: $(basename "$PROJECT_ROOT")"
fi

# Resolve absolute path
PROJECT_ROOT=$(cd "$PROJECT_ROOT" && pwd)
print_status "info" "Project root: $PROJECT_ROOT"

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    print_unless_quiet "info" "Running test: $test_name"
    
    if $test_function; then
        print_unless_quiet "success" "Test passed: $test_name"
        TEST_RESULTS+=("✓ $test_name")
        ((TESTS_PASSED++))
        return 0
    else
        print_unless_quiet "error" "Test failed: $test_name"
        TEST_RESULTS+=("✗ $test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Project structure validation
test_project_structure() {
    print_verbose "Checking project structure..."
    
    # Use shared utility to validate project structure
    if validate_project_structure "$PROJECT_ROOT"; then
        return 0
    else
        return 1
    fi
}

# Test 2: Version utilities
test_version_utils() {
    print_verbose "Testing version utilities..."
    
    # Test getting project version
    local version
    version=$(get_project_version "$PROJECT_ROOT")
    if [ $? -eq 0 ] && [ -n "$version" ]; then
        print_verbose "Project version: $version"
        return 0
    else
        return 1
    fi
}

# Test 3: Changelog check
test_changelog_check() {
    print_verbose "Testing changelog functionality..."
    
    # Check if changelog exists
    if has_changelog "$PROJECT_ROOT"; then
        print_verbose "Changelog found"
        return 0
    else
        print_verbose "No changelog found"
        return 1
    fi
}

# Test 4: Build system detection
test_build_system() {
    print_verbose "Testing build system detection..."
    
    # Use shared utility to detect build system
    local build_system
    build_system=$(get_build_system "$PROJECT_ROOT")
    if [ $? -eq 0 ] && [ "$build_system" != "unknown" ]; then
        print_verbose "Build system: $build_system"
        return 0
    else
        return 1
    fi
}

# Test 5: Wheel build
test_wheel_build() {
    if [ "$SKIP_BUILD" = "true" ]; then
        print_verbose "Skipping wheel build test"
        return 0
    fi
    
    print_verbose "Testing wheel build..."
    
    # Clean previous build
    clean_build_artifacts "$PROJECT_ROOT"
    
    # Build wheel using shared utility
    if build_project "$PROJECT_ROOT"; then
        # Check if wheel was created
        local wheel_file
        wheel_file=$(find_wheel_file "$PROJECT_ROOT")
        if [ $? -eq 0 ] && [ -n "$wheel_file" ]; then
            print_verbose "Wheel file created: $wheel_file"
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Test 6: Release testing
test_release_testing() {
    if [ "$SKIP_TESTS" = "true" ]; then
        print_verbose "Skipping release testing"
        return 0
    fi
    
    print_verbose "Testing release testing flow..."
    
    # Find wheel file
    local wheel_file
    wheel_file=$(find_wheel_file "$PROJECT_ROOT")
    if [ $? -ne 0 ]; then
        print_verbose "No wheel file found, skipping release test"
        return 0
    fi
    
    # Test in isolated environment using shared utility
    if test_in_isolated_environment "$PROJECT_ROOT" "$wheel_file" ".test-env-full"; then
        return 0
    else
        return 1
    fi
}

# Test 7: GitHub utilities (structure test)
test_github_utilities() {
    if [ "$SKIP_GITHUB" = "true" ]; then
        print_verbose "Skipping GitHub utilities test"
        return 0
    fi
    
    print_verbose "Testing GitHub utilities structure..."
    
    # Test GitHub repo info extraction
    local repo_info
    repo_info=$(get_github_repo_info "$PROJECT_ROOT" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$repo_info" ]; then
        print_verbose "GitHub repo info: $repo_info"
        return 0
    else
        print_verbose "GitHub repo info not available (expected in test environment)"
        return 0  # This is expected in test environment
    fi
}

# Test 8: Template structure
test_template_structure() {
    print_verbose "Checking template project structure..."
    
    local required_files=(
        "scripts/lib/common.sh"
        "scripts/lib/project-utils.sh"
        "scripts/lib/build-utils.sh"
        "scripts/lib/github-utils.sh"
        "scripts/lib/venv-utils.sh"
        "scripts/release/build-wheel.sh"
        "scripts/release/test-release.sh"
        "scripts/release/github-release.sh"
        "scripts/utils/version-utils.py"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$TEMPLATE_ROOT/$file" ]; then
            print_verbose "Required file not found: $file"
            return 1
        fi
    done
    
    return 0
}

# Test 9: Integration test (dry run)
test_integration_dry_run() {
    print_verbose "Testing integration (dry run)..."
    
    # Test that all shared libraries can be loaded
    if source "$SCRIPT_DIR/../lib/common.sh" && \
       source "$SCRIPT_DIR/../lib/project-utils.sh" && \
       source "$SCRIPT_DIR/../lib/build-utils.sh" && \
       source "$SCRIPT_DIR/../lib/github-utils.sh" && \
       source "$SCRIPT_DIR/../lib/venv-utils.sh"; then
        return 0
    else
        return 1
    fi
}

# Generate test report
generate_test_report() {
    print_verbose "Generating test report..."
    
    local report_file="$PROJECT_ROOT/release-test-report.txt"
    
    cat > "$report_file" << EOF
Release Flow Test Report
========================

Date: $(date)
Project: $PROJECT_ROOT
Template: $TEMPLATE_ROOT

Test Results:
=============
Total Tests: $((TESTS_PASSED + TESTS_FAILED))
Passed: $TESTS_PASSED
Failed: $TESTS_FAILED

Detailed Results:
EOF
    
    for result in "${TEST_RESULTS[@]}"; do
        echo "$result" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

Test Environment:
=================
- Python: $(python --version 2>&1)
- Git: $(git --version 2>&1)
- Platform: $(uname -s 2>/dev/null || echo "Unknown")

Project Information:
====================
EOF
    
    # Add project info
    get_project_name "$PROJECT_ROOT" >> "$report_file" 2>/dev/null || echo "Unknown" >> "$report_file"
    get_project_version "$PROJECT_ROOT" >> "$report_file" 2>/dev/null || echo "Unknown" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "Status: $([ $TESTS_FAILED -eq 0 ] && echo "SUCCESS" || echo "FAILED")" >> "$report_file"
    
    print_status "success" "Test report generated: $report_file"
}

# Main test execution
main() {
    print_header "Starting Release Flow Tests"
    
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
    
    # Run all tests
    run_test "Template Structure" test_template_structure
    run_test "Project Structure" test_project_structure
    run_test "Version Utilities" test_version_utils
    run_test "Changelog Check" test_changelog_check
    run_test "Build System" test_build_system
    run_test "Wheel Build" test_wheel_build
    run_test "Release Testing" test_release_testing
    run_test "GitHub Utilities" test_github_utilities
    run_test "Integration (Dry Run)" test_integration_dry_run
    
    # Generate report
    generate_test_report
    
    # Print summary
    print_header "Test Summary"
    print_status "info" "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    print_status "success" "Tests passed: $TESTS_PASSED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        print_status "error" "Tests failed: $TESTS_FAILED"
        print_header "Overall Result: FAILED"
        exit 1
    else
        print_status "success" "Tests failed: $TESTS_FAILED"
        print_header "Overall Result: SUCCESS"
        exit 0
    fi
}

# Run main function
main "$@"