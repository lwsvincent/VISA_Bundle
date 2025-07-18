#!/bin/bash
# Build utilities for release scripts
# This file should be sourced by other scripts: source scripts/lib/build-utils.sh

# Ensure common.sh is loaded
if ! declare -f print_status > /dev/null; then
    echo "Error: common.sh must be sourced before build-utils.sh"
    exit 1
fi

# Build system detection
detect_build_system() {
    local project_root=${1:-"."}
    
    print_verbose "Detecting build system in $project_root..."
    
    # Check for Poetry
    if [ -f "$project_root/pyproject.toml" ] && command_exists poetry; then
        if grep -q "tool.poetry" "$project_root/pyproject.toml"; then
            echo "poetry"
            return 0
        fi
    fi
    
    # Check for modern Python build system (PEP 517/518)
    if [ -f "$project_root/pyproject.toml" ]; then
        if grep -q "build-system" "$project_root/pyproject.toml"; then
            echo "build"
            return 0
        fi
    fi
    
    # Check for setuptools
    if [ -f "$project_root/setup.py" ]; then
        echo "setuptools"
        return 0
    fi
    
    # No supported build system found
    echo "unknown"
    return 1
}

# Get build system with validation
get_build_system() {
    local project_root=${1:-"."}
    local build_system
    
    build_system=$(detect_build_system "$project_root")
    
    if [ "$build_system" = "unknown" ]; then
        print_status "error" "No supported build system found" >&2
        return 1
    fi
    
    case $build_system in
        "poetry")
            print_status "info" "Detected Poetry build system" >&2
            ;;
        "build")
            print_status "info" "Detected modern Python build system (pyproject.toml)" >&2
            ;;
        "setuptools")
            print_status "info" "Detected setuptools build system (setup.py)" >&2
            ;;
    esac
    
    echo "$build_system"
    return 0
}

# Clean build artifacts
clean_build_artifacts() {
    local project_root=${1:-"."}
    
    print_status "info" "Cleaning previous build artifacts..."
    
    # Remove dist directory
    if [ -d "$project_root/dist" ]; then
        rm -rf "$project_root/dist"
        print_verbose "Removed dist directory"
    fi
    
    # Remove build directory
    if [ -d "$project_root/build" ]; then
        rm -rf "$project_root/build"
        print_verbose "Removed build directory"
    fi
    
    # Remove egg-info directories
    find "$project_root" -name "*.egg-info" -type d -exec rm -rf {} + 2>/dev/null
    
    # Remove __pycache__ directories
    find "$project_root" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    
    # Remove .pyc files
    find "$project_root" -name "*.pyc" -type f -delete 2>/dev/null
    
    print_status "success" "Build artifacts cleaned"
}

# Check build dependencies
check_build_dependencies() {
    local build_system=$1
    
    print_status "info" "Checking build dependencies..."
    
    case $build_system in
        "poetry")
            if ! command_exists poetry; then
                print_status "error" "Poetry not found. Install from https://python-poetry.org/"
                return 1
            fi
            print_status "success" "Poetry is available"
            ;;
        "build")
            if ! python -c "import build" 2>/dev/null; then
                print_status "error" "build package not installed. Install with: pip install build"
                return 1
            fi
            print_status "success" "build package is available"
            ;;
        "setuptools")
            # Check for modern build package first (preferred)
            if python -c "import build" 2>/dev/null; then
                print_status "success" "build package is available (preferred)"
            # Fall back to setuptools + wheel
            elif python -c "import setuptools" 2>/dev/null && python -c "import wheel" 2>/dev/null; then
                print_status "success" "setuptools and wheel are available (fallback)"
            else
                print_status "error" "Neither 'build' package nor 'setuptools+wheel' found. Install with: pip install build"
                return 1
            fi
            ;;
        *)
            print_status "error" "Unknown build system: $build_system"
            return 1
            ;;
    esac
    
    return 0
}

# Build wheel with Poetry
build_wheel_with_poetry() {
    local project_root=${1:-"."}
    
    print_status "info" "Building wheel with Poetry..."
    
    cd "$project_root" || return 1
    
    if execute_command "poetry build --format wheel" "Build wheel with Poetry"; then
        print_status "success" "Wheel built successfully with Poetry"
        return 0
    else
        print_status "error" "Failed to build wheel with Poetry"
        return 1
    fi
}

# Build wheel with build package
build_wheel_with_build() {
    local project_root=${1:-"."}
    
    print_status "info" "Building wheel with build package..."
    
    cd "$project_root" || return 1
    
    if execute_command "python -m build --wheel" "Build wheel with build package"; then
        print_status "success" "Wheel built successfully with build package"
        return 0
    else
        print_status "error" "Failed to build wheel with build package"
        return 1
    fi
}

# Build wheel with setuptools
build_wheel_with_setuptools() {
    local project_root=${1:-"."}
    
    print_status "info" "Building wheel with setuptools..."
    
    cd "$project_root" || return 1
    
    # Try modern build approach first
    if execute_command "python -m build --wheel" "Build wheel with python -m build"; then
        print_status "success" "Wheel built successfully with python -m build"
        return 0
    # Fall back to setuptools if available
    elif execute_command "python setup.py bdist_wheel" "Build wheel with setuptools"; then
        print_status "success" "Wheel built successfully with setuptools"
        return 0
    else
        print_status "error" "Failed to build wheel with setuptools"
        return 1
    fi
}

# Build wheel (main function)
build_wheel() {
    local project_root=${1:-"."}
    local build_system
    
    # Detect build system
    build_system=$(get_build_system "$project_root")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Check dependencies
    if ! check_build_dependencies "$build_system"; then
        return 1
    fi
    
    # Clean previous artifacts
    clean_build_artifacts "$project_root"
    
    # Build wheel based on detected system
    case $build_system in
        "poetry")
            build_wheel_with_poetry "$project_root"
            ;;
        "build")
            build_wheel_with_build "$project_root"
            ;;
        "setuptools")
            build_wheel_with_setuptools "$project_root"
            ;;
        *)
            print_status "error" "Unknown build system: $build_system"
            return 1
            ;;
    esac
}

# Find wheel file
find_wheel_file() {
    local project_root=${1:-"."}
    local wheel_file
    
    wheel_file=$(find "$project_root/dist" -name "*.whl" -type f | head -1)
    
    if [ -z "$wheel_file" ]; then
        print_status "error" "No wheel file found in $project_root/dist"
        return 1
    fi
    
    echo "$wheel_file"
    return 0
}

# Validate wheel file
validate_wheel_file() {
    local wheel_file=$1
    
    if [ ! -f "$wheel_file" ]; then
        print_status "error" "Wheel file not found: $wheel_file"
        return 1
    fi
    
    print_status "info" "Validating wheel file: $(basename "$wheel_file")"
    
    # Check if wheel file is a valid zip
    if ! python -c "import zipfile; zipfile.ZipFile('$wheel_file').testzip()" 2>/dev/null; then
        print_status "error" "Wheel file is corrupted or not a valid zip"
        return 1
    fi
    
    print_status "success" "Wheel file is valid"
    
    # Show wheel info
    print_status "info" "Wheel file information:"
    echo "  File: $wheel_file"
    echo "  Size: $(du -h "$wheel_file" | cut -f1)"
    
    # Check wheel metadata if wheel tool is available
    if command_exists wheel; then
        if wheel show "$wheel_file" > /dev/null 2>&1; then
            print_status "success" "Wheel metadata is valid"
        else
            print_status "warning" "Wheel metadata validation failed"
        fi
    fi
    
    return 0
}

# Test wheel installation
test_wheel_installation() {
    local wheel_file=$1
    local project_root=${2:-"."}
    local temp_venv="$project_root/.temp-wheel-test"
    
    print_status "info" "Testing wheel installation..."
    
    # Create temporary virtual environment
    if ! python -m venv "$temp_venv"; then
        print_status "error" "Failed to create temporary virtual environment"
        return 1
    fi
    
    print_verbose "Created temporary virtual environment: $temp_venv"
    
    # Activate virtual environment
    if [ -f "$temp_venv/bin/activate" ]; then
        source "$temp_venv/bin/activate"
    elif [ -f "$temp_venv/Scripts/activate" ]; then
        source "$temp_venv/Scripts/activate"
    else
        print_status "error" "Cannot find virtual environment activation script"
        rm -rf "$temp_venv"
        return 1
    fi
    
    # Install wheel
    if pip install "$wheel_file" > /dev/null 2>&1; then
        print_status "success" "Wheel installed successfully"
        
        # Try to import the package
        local package_name
        package_name=$(python -c "
import pkg_resources
try:
    dist = pkg_resources.get_distribution(pkg_resources.safe_name('$(basename "$wheel_file" .whl | cut -d'-' -f1)'))
    print(dist.project_name)
except:
    pass
" 2>/dev/null)
        
        if [ -n "$package_name" ]; then
            if python -c "import $package_name" 2>/dev/null; then
                print_status "success" "Package can be imported successfully"
            else
                print_status "warning" "Package installation succeeded but import failed"
            fi
        fi
    else
        print_status "error" "Failed to install wheel"
        deactivate
        rm -rf "$temp_venv"
        return 1
    fi
    
    # Clean up
    deactivate
    rm -rf "$temp_venv"
    
    return 0
}

# Generate build report
generate_build_report() {
    local project_root=${1:-"."}
    local build_system=$2
    local wheel_file=$3
    
    local report_file="$project_root/dist/build-report.txt"
    
    print_status "info" "Generating build report..."
    
    # Create dist directory if it doesn't exist
    mkdir -p "$project_root/dist"
    
    cat > "$report_file" << EOF
Build Report
============

Date: $(date)
Build System: $build_system
Project Root: $project_root

Files Generated:
$(ls -la "$project_root/dist/" 2>/dev/null || echo "No files found")

Wheel File: ${wheel_file:-"Not found"}
EOF
    
    if [ -f "$wheel_file" ]; then
        echo "Wheel Size: $(du -h "$wheel_file" | cut -f1)" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

Build Environment:
- Python: $(python --version 2>&1)
- Platform: $(uname -s 2>/dev/null || echo "Unknown")
- Architecture: $(uname -m 2>/dev/null || echo "Unknown")

Build Tools:
EOF
    
    # Add build tool versions
    case $build_system in
        "poetry")
            echo "- poetry: $(poetry --version 2>/dev/null || echo "unknown")" >> "$report_file"
            ;;
        "build")
            echo "- build: $(python -c "import build; print(build.__version__)" 2>/dev/null || echo "unknown")" >> "$report_file"
            ;;
        "setuptools")
            echo "- setuptools: $(python -c "import setuptools; print(setuptools.__version__)" 2>/dev/null || echo "unknown")" >> "$report_file"
            echo "- wheel: $(python -c "import wheel; print(wheel.__version__)" 2>/dev/null || echo "unknown")" >> "$report_file"
            ;;
    esac
    
    echo "" >> "$report_file"
    echo "Build Status: SUCCESS" >> "$report_file"
    
    print_status "success" "Build report generated: $report_file"
}

# Main build process
build_project() {
    local project_root=${1:-"."}
    
    print_header "Building Python Package"
    
    # Validate project root
    if ! validate_project_root "$project_root"; then
        return 1
    fi
    
    # Change to project root
    if ! change_to_project_root "$project_root"; then
        return 1
    fi
    
    # Detect build system
    local build_system
    build_system=$(get_build_system "$project_root")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Build wheel
    if ! build_wheel "$project_root"; then
        return 1
    fi
    
    # Find wheel file
    local wheel_file
    wheel_file=$(find_wheel_file "$project_root")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Validate wheel
    if ! validate_wheel_file "$wheel_file"; then
        return 1
    fi
    
    # Test installation
    if ! test_wheel_installation "$wheel_file" "$project_root"; then
        print_status "warning" "Wheel installation test failed, but continuing..."
    fi
    
    # Generate report
    generate_build_report "$project_root" "$build_system" "$wheel_file"
    
    print_status "success" "Build completed successfully!"
    print_status "info" "Wheel file: $wheel_file"
    
    return 0
}