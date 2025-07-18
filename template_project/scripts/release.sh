#!/bin/bash
# Complete release automation script
# This script handles: version upgrade, testing, building, and release

# Load shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/project-utils.sh"
source "$SCRIPT_DIR/lib/build-utils.sh"
source "$SCRIPT_DIR/lib/github-utils.sh"
source "$SCRIPT_DIR/lib/venv-utils.sh"

# Initialize common environment
init_common_environment

# Configuration
PROJECT_ROOT="$1"
NEW_VERSION="$2"
VERSION_TYPE="$3"  # patch, minor, major
SKIP_TESTS="false"
SKIP_UPLOAD="false"

TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Release stages
STAGE_VERSION_UPGRADE="version_upgrade"
STAGE_TESTING="testing"
STAGE_BUILD="build"
STAGE_GITHUB_RELEASE="github_release"
STAGE_UPLOAD="upload"

# Status tracking
CURRENT_STAGE=""
FAILED_STAGE=""
RELEASE_REPORT=""

# Show usage
show_usage() {
    echo "Usage: $0 <project_root> [version|version_type] [options]"
    echo ""
    echo "Arguments:"
    echo "  project_root          Path to the Python project"
    echo "  version               Specific version (e.g., 1.2.3) or version type"
    echo "  version_type          auto-increment type: patch, minor, major"
    echo ""
    echo "Options:"
    echo "  --skip-tests         Skip running tests"
    echo "  --skip-upload        Skip PyPI upload (only create GitHub release)"
    echo "  --dry-run            Show what would be done without executing"
    echo "  --verbose, -v        Enable verbose output"
    echo "  --quiet, -q          Suppress non-error output"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/project 1.2.3                    # Release specific version"
    echo "  $0 /path/to/project patch                     # Auto-increment patch version"
    echo "  $0 /path/to/project minor --skip-tests       # Minor version, skip tests"
    echo "  $0 /path/to/project major --skip-upload      # Major version, no PyPI upload"
    echo ""
    echo "Release Process:"
    echo "  1. Version upgrade (update version files)"
    echo "  2. Run tests (pytest)"
    echo "  3. Build wheel package"
    echo "  4. Create GitHub release"
    echo "  5. Upload to PyPI (if not skipped)"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS="true"
                shift
                ;;
            --skip-upload)
                SKIP_UPLOAD="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --verbose|-v)
                VERBOSE="true"
                shift
                ;;
            --quiet|-q)
                QUIET="true"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    print_status "info" "Checking prerequisites..."
    
    # Use shared utility to validate project structure
    if ! validate_project_structure "$PROJECT_ROOT"; then
        return 1
    fi
    
    # Check if template project is available
    if [ ! -d "$TEMPLATE_ROOT" ]; then
        print_status "error" "Template project not found: $TEMPLATE_ROOT"
        return 1
    fi
    
    print_status "success" "Prerequisites check passed"
    return 0
}

# Determine new version
determine_version() {
    print_status "info" "Determining new version..."
    
    if [ -n "$NEW_VERSION" ]; then
        # Check if it's a version type or specific version
        if [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            print_status "info" "Using specific version: $NEW_VERSION"
            return 0
        elif [[ "$NEW_VERSION" =~ ^(patch|minor|major)$ ]]; then
            VERSION_TYPE="$NEW_VERSION"
            print_status "info" "Using version type: $VERSION_TYPE"
            
            # Use shared utility to calculate new version
            NEW_VERSION=$(increment_version "$PROJECT_ROOT" "$VERSION_TYPE")
            if [ $? -eq 0 ] && [ -n "$NEW_VERSION" ]; then
                print_status "success" "Calculated new version: $NEW_VERSION"
                return 0
            else
                print_status "error" "Failed to calculate new version"
                return 1
            fi
        else
            print_status "error" "Invalid version format: $NEW_VERSION"
            return 1
        fi
    else
        print_status "error" "Version not specified"
        return 1
    fi
}

# Stage 1: Version upgrade
stage_version_upgrade() {
    CURRENT_STAGE="$STAGE_VERSION_UPGRADE"
    print_header "Stage 1: Version Upgrade"
    
    print_status "info" "Upgrading version to $NEW_VERSION..."
    
    # Update version files using shared utility
    if ! set_project_version "$PROJECT_ROOT" "$NEW_VERSION"; then
        print_status "error" "Failed to update version files"
        return 1
    fi
    
    # Update CHANGELOG.md using shared utility
    if ! update_changelog "$PROJECT_ROOT" "$NEW_VERSION"; then
        print_status "warning" "Failed to update changelog, but continuing..."
    fi
    
    # Commit version changes
    print_status "info" "Committing version changes..."
    if execute_command "git add -A" "Stage version changes"; then
        if execute_command "git commit -m 'Bump version to $NEW_VERSION'" "Commit version changes"; then
            print_status "success" "Version changes committed"
        else
            print_status "error" "Failed to commit version changes"
            return 1
        fi
    else
        print_status "error" "Failed to stage version changes"
        return 1
    fi
    
    # Create version tag
    print_status "info" "Creating version tag..."
    if execute_command "git tag -a 'v$NEW_VERSION' -m 'Release $NEW_VERSION'" "Create version tag"; then
        print_status "success" "Version tag created: v$NEW_VERSION"
    else
        print_status "error" "Failed to create version tag"
        return 1
    fi
    
    return 0
}

# Stage 2: Testing
stage_testing() {
    CURRENT_STAGE="$STAGE_TESTING"
    print_header "Stage 2: Testing"
    
    if [ "$SKIP_TESTS" = "true" ]; then
        print_status "warning" "Tests skipped by user request"
        return 0
    fi
    
    print_status "info" "Running tests..."
    
    # Run tests using test-release.sh
    if [ -f "$TEMPLATE_ROOT/scripts/release/test-release.sh" ]; then
        if execute_command "bash '$TEMPLATE_ROOT/scripts/release/test-release.sh' '$PROJECT_ROOT'" "Run release tests"; then
            print_status "success" "All tests passed"
        else
            print_status "error" "Tests failed"
            return 1
        fi
    else
        # Fallback to direct testing
        print_status "info" "Using direct testing..."
        local test_dir
        test_dir=$(find_test_directory "$PROJECT_ROOT")
        if [ -n "$test_dir" ]; then
            if execute_command "pytest --tb=short -v '$test_dir'" "Run tests with pytest"; then
                print_status "success" "Tests passed"
            else
                print_status "error" "Tests failed"
                return 1
            fi
        else
            print_status "warning" "No tests found, skipping tests"
        fi
    fi
    
    return 0
}

# Stage 3: Build
stage_build() {
    CURRENT_STAGE="$STAGE_BUILD"
    print_header "Stage 3: Build Package"
    
    print_status "info" "Building wheel package..."
    
    # Build wheel using shared utility
    if ! build_project "$PROJECT_ROOT"; then
        print_status "error" "Wheel build failed"
        return 1
    fi
    
    # Verify wheel file exists
    local wheel_file
    wheel_file=$(find_wheel_file "$PROJECT_ROOT")
    if [ $? -ne 0 ]; then
        print_status "error" "Wheel file not found after build"
        return 1
    fi
    
    print_status "info" "Wheel file: $wheel_file"
    
    return 0
}

# Stage 4: GitHub Release
stage_github_release() {
    CURRENT_STAGE="$STAGE_GITHUB_RELEASE"
    print_header "Stage 4: GitHub Release"
    
    print_status "info" "Creating GitHub release..."
    
    # Create GitHub release using shared utility
    if ! create_github_release "$PROJECT_ROOT" "$NEW_VERSION"; then
        print_status "error" "GitHub release creation failed"
        return 1
    fi
    
    return 0
}

# Stage 5: Upload to PyPI
stage_upload() {
    CURRENT_STAGE="$STAGE_UPLOAD"
    print_header "Stage 5: Upload to PyPI"
    
    if [ "$SKIP_UPLOAD" = "true" ]; then
        print_status "warning" "PyPI upload skipped by user request"
        return 0
    fi
    
    print_status "info" "Uploading to PyPI..."
    
    # Check if twine is installed
    if ! command_exists twine; then
        print_status "error" "twine not found. Install with: pip install twine"
        return 1
    fi
    
    # Upload to PyPI
    if execute_command "twine upload dist/*" "Upload to PyPI"; then
        print_status "success" "Package uploaded to PyPI successfully"
    else
        print_status "error" "PyPI upload failed"
        return 1
    fi
    
    return 0
}

# Generate release report
generate_release_report() {
    print_status "info" "Generating release report..."
    
    local report_file="$PROJECT_ROOT/release-report.txt"
    
    cat > "$report_file" << EOF
Release Report
==============

Date: $(date)
Project: $PROJECT_ROOT
Version: $NEW_VERSION
Tag: v$NEW_VERSION

Release Stages:
===============
1. Version Upgrade: $([ "$CURRENT_STAGE" != "$STAGE_VERSION_UPGRADE" ] && echo "[SUCCESS]" || echo "[FAILED]")
2. Testing: $([ "$SKIP_TESTS" = "true" ] && echo "[SKIPPED]" || ([ "$CURRENT_STAGE" != "$STAGE_TESTING" ] && echo "[SUCCESS]" || echo "[FAILED]"))
3. Build: $([ "$CURRENT_STAGE" != "$STAGE_BUILD" ] && echo "[SUCCESS]" || echo "[FAILED]")
4. GitHub Release: $([ "$CURRENT_STAGE" != "$STAGE_GITHUB_RELEASE" ] && echo "[SUCCESS]" || echo "[FAILED]")
5. PyPI Upload: $([ "$SKIP_UPLOAD" = "true" ] && echo "[SKIPPED]" || ([ "$CURRENT_STAGE" != "$STAGE_UPLOAD" ] && echo "[SUCCESS]" || echo "[FAILED]"))

Failed Stage: ${FAILED_STAGE:-"None"}

Release Assets:
===============
EOF
    
    if [ -d "$PROJECT_ROOT/dist" ]; then
        echo "Distribution Files:" >> "$report_file"
        ls -la "$PROJECT_ROOT/dist/" >> "$report_file" 2>/dev/null || echo "None" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    echo "Git Status:" >> "$report_file"
    git log -1 --oneline >> "$report_file" 2>/dev/null || echo "Unknown" >> "$report_file"
    git tag -l | tail -5 >> "$report_file" 2>/dev/null || echo "No tags" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Status: $([ -n "$FAILED_STAGE" ] && echo "FAILED" || echo "SUCCESS")" >> "$report_file"
    
    print_status "success" "Release report generated: $report_file"
}

# Script cleanup function
script_cleanup() {
    print_verbose "Cleaning up release script resources..."
    
    # Generate final report if we have a failed stage
    if [ -n "$FAILED_STAGE" ]; then
        generate_release_report
    fi
}

# Cleanup on failure
cleanup_on_failure() {
    print_status "error" "Release failed at stage: $CURRENT_STAGE"
    
    # Remove tag if created
    if git tag -l | grep -q "v$NEW_VERSION"; then
        print_status "info" "Removing created tag: v$NEW_VERSION"
        execute_command "git tag -d 'v$NEW_VERSION'" "Remove version tag"
    fi
    
    # Reset to previous commit if version was committed
    if [ "$CURRENT_STAGE" != "$STAGE_VERSION_UPGRADE" ]; then
        print_status "info" "Resetting version changes..."
        execute_command "git reset --hard HEAD~1" "Reset version changes"
    fi
    
    FAILED_STAGE="$CURRENT_STAGE"
    generate_release_report
}

# Main release process
main() {
    print_header "Python Package Release Automation"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Check if help requested
    if [ -z "$PROJECT_ROOT" ] || [ -z "$NEW_VERSION" ]; then
        show_usage
        exit 1
    fi
    
    print_unless_quiet "info" "Starting release process..."
    print_unless_quiet "info" "Project: $PROJECT_ROOT"
    print_unless_quiet "info" "Version: $NEW_VERSION"
    print_unless_quiet "info" "Skip Tests: ${SKIP_TESTS:-false}"
    print_unless_quiet "info" "Skip Upload: ${SKIP_UPLOAD:-false}"
    
    # Set error handling
    trap cleanup_on_failure ERR
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Determine version
    if ! determine_version; then
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
    
    # Execute release stages
    stage_version_upgrade
    stage_testing
    stage_build
    stage_github_release
    stage_upload
    
    # Generate final report
    generate_release_report
    
    print_header "Release Completed Successfully!"
    print_status "success" "Version $NEW_VERSION released successfully"
    print_status "info" "Release tag: v$NEW_VERSION"
    
    # Push changes
    print_status "info" "Pushing changes to remote..."
    if execute_command "git push origin main" "Push changes to main branch"; then
        if execute_command "git push origin 'v$NEW_VERSION'" "Push version tag"; then
            print_status "success" "Changes pushed to remote successfully"
        else
            print_status "warning" "Failed to push version tag, but release completed"
        fi
    else
        print_status "warning" "Failed to push changes to remote, but release completed"
    fi
    
    print_status "success" "Release process completed!"
    
    return 0
}

# Run main function
main "$@"