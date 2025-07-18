#!/bin/bash
# Virtual environment utilities for release scripts
# This file should be sourced by other scripts: source scripts/lib/venv-utils.sh

# Ensure common.sh is loaded
if ! declare -f print_status > /dev/null; then
    echo "Error: common.sh must be sourced before venv-utils.sh"
    exit 1
fi

# Create virtual environment
create_virtual_environment() {
    local venv_path=$1
    local python_version=${2:-"python"}
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    print_status "info" "Creating virtual environment: $venv_path"
    
    # Remove existing virtual environment if it exists
    if [ -d "$venv_path" ]; then
        print_status "info" "Removing existing virtual environment"
        rm -rf "$venv_path"
    fi
    
    # Create virtual environment
    if execute_command "$python_version -m venv \"$venv_path\"" "Create virtual environment"; then
        print_status "success" "Virtual environment created successfully"
        return 0
    else
        print_status "error" "Failed to create virtual environment"
        return 1
    fi
}

# Activate virtual environment
activate_virtual_environment() {
    local venv_path=$1
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ ! -d "$venv_path" ]; then
        print_status "error" "Virtual environment not found: $venv_path"
        return 1
    fi
    
    # Determine activation script path
    local activate_script=""
    if [ -f "$venv_path/bin/activate" ]; then
        activate_script="$venv_path/bin/activate"
    elif [ -f "$venv_path/Scripts/activate" ]; then
        activate_script="$venv_path/Scripts/activate"
    else
        print_status "error" "Virtual environment activation script not found"
        return 1
    fi
    
    print_verbose "Activating virtual environment: $activate_script"
    
    # Source the activation script
    source "$activate_script"
    
    # Verify activation
    if [ -n "$VIRTUAL_ENV" ]; then
        print_status "success" "Virtual environment activated: $(basename "$VIRTUAL_ENV")"
        return 0
    else
        print_status "error" "Failed to activate virtual environment"
        return 1
    fi
}

# Deactivate virtual environment
deactivate_virtual_environment() {
    if [ -n "$VIRTUAL_ENV" ]; then
        print_status "info" "Deactivating virtual environment: $(basename "$VIRTUAL_ENV")"
        deactivate 2>/dev/null || true
        print_status "success" "Virtual environment deactivated"
    else
        print_verbose "No virtual environment to deactivate"
    fi
}

# Check if virtual environment is active
is_virtual_environment_active() {
    [ -n "$VIRTUAL_ENV" ]
}

# Get virtual environment python executable
get_venv_python() {
    local venv_path=$1
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ -f "$venv_path/bin/python" ]; then
        echo "$venv_path/bin/python"
        return 0
    elif [ -f "$venv_path/Scripts/python.exe" ]; then
        echo "$venv_path/Scripts/python.exe"
        return 0
    else
        print_status "error" "Python executable not found in virtual environment"
        return 1
    fi
}

# Get virtual environment pip executable
get_venv_pip() {
    local venv_path=$1
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ -f "$venv_path/bin/pip" ]; then
        echo "$venv_path/bin/pip"
        return 0
    elif [ -f "$venv_path/Scripts/pip.exe" ]; then
        echo "$venv_path/Scripts/pip.exe"
        return 0
    else
        print_status "error" "Pip executable not found in virtual environment"
        return 1
    fi
}

# Install packages in virtual environment
install_packages() {
    local venv_path=$1
    shift
    local packages=("$@")
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ ${#packages[@]} -eq 0 ]; then
        print_status "error" "No packages to install"
        return 1
    fi
    
    local pip_cmd
    pip_cmd=$(get_venv_pip "$venv_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_status "info" "Installing packages: ${packages[*]}"
    
    # Install packages
    if execute_command "$pip_cmd install ${packages[*]}" "Install packages"; then
        print_status "success" "Packages installed successfully"
        return 0
    else
        print_status "error" "Failed to install packages"
        return 1
    fi
}

# Install requirements file in virtual environment
install_requirements() {
    local venv_path=$1
    local requirements_file=$2
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ -z "$requirements_file" ]; then
        print_status "error" "Requirements file not provided"
        return 1
    fi
    
    if [ ! -f "$requirements_file" ]; then
        print_status "error" "Requirements file not found: $requirements_file"
        return 1
    fi
    
    local pip_cmd
    pip_cmd=$(get_venv_pip "$venv_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_status "info" "Installing requirements from: $requirements_file"
    
    # Install requirements
    if execute_command "$pip_cmd install -r \"$requirements_file\"" "Install requirements"; then
        print_status "success" "Requirements installed successfully"
        return 0
    else
        print_status "error" "Failed to install requirements"
        return 1
    fi
}

# Install wheel package in virtual environment
install_wheel_package() {
    local venv_path=$1
    local wheel_file=$2
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ -z "$wheel_file" ]; then
        print_status "error" "Wheel file not provided"
        return 1
    fi
    
    if [ ! -f "$wheel_file" ]; then
        print_status "error" "Wheel file not found: $wheel_file"
        return 1
    fi
    
    local pip_cmd
    pip_cmd=$(get_venv_pip "$venv_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_status "info" "Installing wheel package: $(basename "$wheel_file")"
    
    # Install wheel
    if execute_command "$pip_cmd install \"$wheel_file\"" "Install wheel package"; then
        print_status "success" "Wheel package installed successfully"
        return 0
    else
        print_status "error" "Failed to install wheel package"
        return 1
    fi
}

# Run command in virtual environment
run_in_venv() {
    local venv_path=$1
    local command=$2
    local description=${3:-"Run command in virtual environment"}
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ -z "$command" ]; then
        print_status "error" "Command not provided"
        return 1
    fi
    
    if [ ! -d "$venv_path" ]; then
        print_status "error" "Virtual environment not found: $venv_path"
        return 1
    fi
    
    # Get Python executable
    local python_cmd
    python_cmd=$(get_venv_python "$venv_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_verbose "Running command in virtual environment: $command"
    
    # Execute command with virtual environment Python
    if execute_command "$python_cmd -c \"$command\"" "$description"; then
        return 0
    else
        return 1
    fi
}

# Run tests in virtual environment
run_tests_in_venv() {
    local venv_path=$1
    local test_dir=${2:-"tests"}
    local test_args=${3:-""}
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ ! -d "$venv_path" ]; then
        print_status "error" "Virtual environment not found: $venv_path"
        return 1
    fi
    
    # Get Python executable
    local python_cmd
    python_cmd=$(get_venv_python "$venv_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_status "info" "Running tests in virtual environment..."
    
    # Check if pytest is available
    if "$python_cmd" -c "import pytest" 2>/dev/null; then
        local test_command="$python_cmd -m pytest"
        
        # Add test directory if it exists
        if [ -d "$test_dir" ]; then
            test_command="$test_command \"$test_dir\""
        fi
        
        # Add additional arguments
        if [ -n "$test_args" ]; then
            test_command="$test_command $test_args"
        fi
        
        if execute_command "$test_command" "Run tests with pytest"; then
            print_status "success" "Tests passed"
            return 0
        else
            print_status "error" "Tests failed"
            return 1
        fi
    else
        # Fallback to unittest
        if execute_command "$python_cmd -m unittest discover -s \"$test_dir\" -v" "Run tests with unittest"; then
            print_status "success" "Tests passed"
            return 0
        else
            print_status "error" "Tests failed"
            return 1
        fi
    fi
}

# List installed packages in virtual environment
list_venv_packages() {
    local venv_path=$1
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    local pip_cmd
    pip_cmd=$(get_venv_pip "$venv_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_status "info" "Installed packages in virtual environment:"
    "$pip_cmd" list
}

# Clean up virtual environment
cleanup_virtual_environment() {
    local venv_path=$1
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ -d "$venv_path" ]; then
        print_status "info" "Cleaning up virtual environment: $venv_path"
        
        # Deactivate if currently active
        if [ "$VIRTUAL_ENV" = "$(realpath "$venv_path")" ]; then
            deactivate_virtual_environment
        fi
        
        # Remove virtual environment directory
        if rm -rf "$venv_path"; then
            print_status "success" "Virtual environment cleaned up"
            return 0
        else
            print_status "error" "Failed to clean up virtual environment"
            return 1
        fi
    else
        print_verbose "Virtual environment not found, nothing to clean up"
        return 0
    fi
}

# Get virtual environment info
get_venv_info() {
    local venv_path=$1
    
    if [ -z "$venv_path" ]; then
        print_status "error" "Virtual environment path not provided"
        return 1
    fi
    
    if [ ! -d "$venv_path" ]; then
        print_status "error" "Virtual environment not found: $venv_path"
        return 1
    fi
    
    local python_cmd
    python_cmd=$(get_venv_python "$venv_path")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_status "info" "Virtual environment information:"
    echo "  Path: $venv_path"
    echo "  Python: $("$python_cmd" --version 2>&1)"
    echo "  Pip: $("$python_cmd" -m pip --version 2>&1)"
    
    # Show if currently active
    if [ "$VIRTUAL_ENV" = "$(realpath "$venv_path")" ]; then
        echo "  Status: Currently active"
    else
        echo "  Status: Inactive"
    fi
}

# Create test environment with project and dependencies
create_test_environment() {
    local project_root=${1:-"."}
    local venv_path=${2:-".test-env"}
    
    print_status "info" "Creating test environment..."
    
    # Create virtual environment
    if ! create_virtual_environment "$venv_path"; then
        return 1
    fi
    
    # Install basic packages
    if ! install_packages "$venv_path" "pip" "setuptools" "wheel"; then
        cleanup_virtual_environment "$venv_path"
        return 1
    fi
    
    # Install requirements if available
    local requirements_files
    requirements_files=$(find_requirements_files "$project_root")
    
    if [ -n "$requirements_files" ]; then
        while IFS= read -r req_file; do
            if ! install_requirements "$venv_path" "$req_file"; then
                print_status "warning" "Failed to install requirements from: $req_file"
            fi
        done <<< "$requirements_files"
    fi
    
    # Install test dependencies
    if ! install_packages "$venv_path" "pytest" "pytest-cov"; then
        print_status "warning" "Failed to install test dependencies"
    fi
    
    print_status "success" "Test environment created successfully"
    return 0
}

# Full test cycle in virtual environment
test_in_isolated_environment() {
    local project_root=${1:-"."}
    local wheel_file=$2
    local venv_path=${3:-".test-wheel"}
    
    if [ -z "$wheel_file" ]; then
        print_status "error" "Wheel file not provided"
        return 1
    fi
    
    print_header "Testing in Isolated Environment"
    
    # Create test environment
    if ! create_test_environment "$project_root" "$venv_path"; then
        return 1
    fi
    
    # Install wheel package
    if ! install_wheel_package "$venv_path" "$wheel_file"; then
        cleanup_virtual_environment "$venv_path"
        return 1
    fi
    
    # Run tests
    local test_dir
    test_dir=$(find_test_directory "$project_root")
    
    if [ -n "$test_dir" ]; then
        if ! run_tests_in_venv "$venv_path" "$test_dir" "--tb=short -v"; then
            cleanup_virtual_environment "$venv_path"
            return 1
        fi
    else
        print_status "warning" "No test directory found, skipping tests"
    fi
    
    # Clean up
    cleanup_virtual_environment "$venv_path"
    
    print_status "success" "Isolated environment testing completed successfully"
    return 0
}