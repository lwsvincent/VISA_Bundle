#!/bin/bash
# Project utilities for release scripts
# This file should be sourced by other scripts: source scripts/lib/project-utils.sh

# Ensure common.sh is loaded
if ! declare -f print_status > /dev/null; then
    echo "Error: common.sh must be sourced before project-utils.sh"
    exit 1
fi

# Find template directory (handles both standalone and integrated scenarios)
find_template_dir() {
    local search_root=${1:-"."}
    
    # Check current directory structure
    if [ -f "$search_root/template_project/scripts/utils/version-utils.py" ]; then
        echo "$search_root/template_project"
        return 0
    fi
    
    # Check if we're in template project
    if [ -f "$search_root/scripts/utils/version-utils.py" ]; then
        echo "$search_root"
        return 0
    fi
    
    # Check parent directories
    local current_dir="$search_root"
    for i in {1..5}; do
        current_dir="$current_dir/.."
        if [ -f "$current_dir/scripts/utils/version-utils.py" ]; then
            echo "$current_dir"
            return 0
        fi
    done
    
    return 1
}

# Get template directory with error handling
get_template_dir() {
    local template_dir
    template_dir=$(find_template_dir)
    
    if [ $? -ne 0 ] || [ -z "$template_dir" ]; then
        print_status "error" "Template project not found"
        return 1
    fi
    
    print_verbose "Template directory: $template_dir"
    echo "$template_dir"
    return 0
}

# Check if project is a Python project
is_python_project() {
    local project_root=$1
    
    if [ -f "$project_root/setup.py" ] || [ -f "$project_root/pyproject.toml" ]; then
        return 0
    fi
    
    return 1
}

# Detect Python project type
detect_python_project_type() {
    local project_root=$1
    
    if [ -f "$project_root/pyproject.toml" ]; then
        # Check for Poetry
        if grep -q "tool.poetry" "$project_root/pyproject.toml"; then
            echo "poetry"
            return 0
        fi
        
        # Check for setuptools with pyproject.toml
        if grep -q "build-system" "$project_root/pyproject.toml"; then
            echo "setuptools-pyproject"
            return 0
        fi
        
        echo "pyproject"
        return 0
    elif [ -f "$project_root/setup.py" ]; then
        echo "setuptools"
        return 0
    else
        echo "unknown"
        return 1
    fi
}

# Get project version using version utils
get_project_version() {
    local project_root=$1
    local template_dir
    
    template_dir=$(get_template_dir)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local version_utils="$template_dir/scripts/utils/version-utils.py"
    if [ ! -f "$version_utils" ]; then
        print_status "error" "Version utils not found: $version_utils"
        return 1
    fi
    
    local version
    version=$(python "$version_utils" "$project_root" 2>/dev/null | grep "Project version:" | cut -d':' -f2 | tr -d ' ')
    
    if [ -z "$version" ]; then
        print_status "error" "Could not determine project version"
        return 1
    fi
    
    echo "$version"
    return 0
}

# Set project version using version utils
set_project_version() {
    local project_root=$1
    local new_version=$2
    local template_dir
    
    if [ -z "$new_version" ]; then
        print_status "error" "New version not provided"
        return 1
    fi
    
    template_dir=$(get_template_dir)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local version_utils="$template_dir/scripts/utils/version-utils.py"
    if [ ! -f "$version_utils" ]; then
        print_status "error" "Version utils not found: $version_utils"
        return 1
    fi
    
    if python "$version_utils" "$project_root" --set "$new_version"; then
        print_status "success" "Version updated to $new_version"
        return 0
    else
        print_status "error" "Failed to update version"
        return 1
    fi
}

# Calculate incremented version
increment_version() {
    local project_root=$1
    local increment_type=$2
    local template_dir
    
    if [ -z "$increment_type" ]; then
        print_status "error" "Increment type not provided (patch, minor, major)"
        return 1
    fi
    
    template_dir=$(get_template_dir)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local version_utils="$template_dir/scripts/utils/version-utils.py"
    if [ ! -f "$version_utils" ]; then
        print_status "error" "Version utils not found: $version_utils"
        return 1
    fi
    
    local new_version
    new_version=$(python "$version_utils" "$project_root" --increment "$increment_type" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$new_version" ]; then
        echo "$new_version"
        return 0
    else
        print_status "error" "Failed to calculate new version"
        return 1
    fi
}

# Find requirements files
find_requirements_files() {
    local project_root=$1
    local files=()
    
    # Common requirements file names
    local req_files=(
        "requirements.txt"
        "requirements-dev.txt"
        "requirements/base.txt"
        "requirements/dev.txt"
        "requirements/test.txt"
        "dev-requirements.txt"
        "test-requirements.txt"
    )
    
    for req_file in "${req_files[@]}"; do
        if [ -f "$project_root/$req_file" ]; then
            files+=("$project_root/$req_file")
        fi
    done
    
    # Return found files
    printf '%s\n' "${files[@]}"
}

# Check if project has tests
has_tests() {
    local project_root=$1
    
    if [ -d "$project_root/tests" ] || [ -d "$project_root/test" ]; then
        return 0
    fi
    
    # Check for test files in project structure
    if find "$project_root" -name "*test*.py" -type f | head -1 | grep -q .; then
        return 0
    fi
    
    return 1
}

# Find test directory
find_test_directory() {
    local project_root=$1
    
    if [ -d "$project_root/tests" ]; then
        echo "$project_root/tests"
        return 0
    elif [ -d "$project_root/test" ]; then
        echo "$project_root/test"
        return 0
    else
        return 1
    fi
}

# Check if project has specific file
has_project_file() {
    local project_root=$1
    local filename=$2
    
    [ -f "$project_root/$filename" ]
}

# Get project name from setup.py or pyproject.toml
get_project_name() {
    local project_root=$1
    
    # Try pyproject.toml first
    if [ -f "$project_root/pyproject.toml" ]; then
        local name
        name=$(grep -E "^name\s*=" "$project_root/pyproject.toml" | cut -d'=' -f2 | tr -d ' "'\''')
        if [ -n "$name" ]; then
            echo "$name"
            return 0
        fi
    fi
    
    # Try setup.py
    if [ -f "$project_root/setup.py" ]; then
        local name
        name=$(grep -E "name\s*=" "$project_root/setup.py" | head -1 | cut -d'=' -f2 | tr -d ' "'\'',' | cut -d')' -f1)
        if [ -n "$name" ]; then
            echo "$name"
            return 0
        fi
    fi
    
    # Fallback to directory name
    basename "$project_root"
}

# Check if project has changelog
has_changelog() {
    local project_root=$1
    
    [ -f "$project_root/CHANGELOG.md" ] || [ -f "$project_root/CHANGELOG.rst" ] || [ -f "$project_root/CHANGELOG.txt" ]
}

# Get changelog file path
get_changelog_path() {
    local project_root=$1
    
    if [ -f "$project_root/CHANGELOG.md" ]; then
        echo "$project_root/CHANGELOG.md"
        return 0
    elif [ -f "$project_root/CHANGELOG.rst" ]; then
        echo "$project_root/CHANGELOG.rst"
        return 0
    elif [ -f "$project_root/CHANGELOG.txt" ]; then
        echo "$project_root/CHANGELOG.txt"
        return 0
    else
        return 1
    fi
}

# Update changelog with new version
update_changelog() {
    local project_root=$1
    local new_version=$2
    local changelog_path
    
    changelog_path=$(get_changelog_path "$project_root")
    if [ $? -ne 0 ]; then
        print_status "warning" "CHANGELOG.md not found, skipping update"
        return 0
    fi
    
    print_status "info" "Updating changelog for version $new_version..."
    
    # Check if version already exists
    if grep -q "## \[$new_version\]" "$changelog_path"; then
        print_status "info" "Version $new_version already in changelog"
        return 0
    fi
    
    # Add new version entry
    local date=$(date +%Y-%m-%d)
    local unreleased_line=$(grep -n "## \[Unreleased\]" "$changelog_path" | cut -d: -f1)
    
    if [ -n "$unreleased_line" ]; then
        # Insert new version after Unreleased section
        local insert_line=$((unreleased_line + 2))
        
        # Create temporary file with new content
        local temp_file=$(mktemp)
        {
            head -n $((insert_line - 1)) "$changelog_path"
            echo ""
            echo "## [$new_version] - $date"
            echo ""
            echo "### Added"
            echo "- New features and improvements"
            echo ""
            echo "### Changed"
            echo "- Updated dependencies"
            echo ""
            echo "### Fixed"
            echo "- Bug fixes"
            echo ""
            tail -n +$insert_line "$changelog_path"
        } > "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$changelog_path"
        print_status "success" "Changelog updated"
        return 0
    else
        print_status "warning" "Could not find Unreleased section in changelog"
        return 1
    fi
}

# Validate project structure
validate_project_structure() {
    local project_root=$1
    local errors=0
    
    print_status "info" "Validating project structure..."
    
    # Check if Python project
    if ! is_python_project "$project_root"; then
        print_status "error" "Not a Python project (no setup.py or pyproject.toml)"
        ((errors++))
    fi
    
    # Check git repository
    if ! is_git_repository; then
        print_status "error" "Not a git repository"
        ((errors++))
    fi
    
    # Check for uncommitted changes
    if has_uncommitted_changes; then
        print_status "error" "Working directory has uncommitted changes"
        ((errors++))
    fi
    
    # Check if we can get version
    local version
    version=$(get_project_version "$project_root")
    if [ $? -ne 0 ]; then
        print_status "error" "Cannot determine project version"
        ((errors++))
    else
        print_status "info" "Project version: $version"
    fi
    
    # Check project name
    local name
    name=$(get_project_name "$project_root")
    if [ -n "$name" ]; then
        print_status "info" "Project name: $name"
    else
        print_status "warning" "Could not determine project name"
    fi
    
    if [ $errors -eq 0 ]; then
        print_status "success" "Project structure validation passed"
        return 0
    else
        print_status "error" "Project structure validation failed ($errors errors)"
        return 1
    fi
}

# Print project information
print_project_info() {
    local project_root=$1
    
    print_section "Project Information"
    
    local name=$(get_project_name "$project_root")
    local version=$(get_project_version "$project_root")
    local project_type=$(detect_python_project_type "$project_root")
    
    echo "Project Root: $project_root"
    echo "Project Name: ${name:-"Unknown"}"
    echo "Project Version: ${version:-"Unknown"}"
    echo "Project Type: ${project_type:-"Unknown"}"
    
    # Git information
    if is_git_repository; then
        echo "Git Branch: $(get_current_branch)"
        echo "Git Status: $(has_uncommitted_changes && echo "Uncommitted changes" || echo "Clean")"
    fi
    
    # Test directory
    local test_dir=$(find_test_directory "$project_root")
    echo "Test Directory: ${test_dir:-"Not found"}"
    
    # Changelog
    local changelog_path=$(get_changelog_path "$project_root")
    echo "Changelog: ${changelog_path:-"Not found"}"
    
    echo ""
}