#!/bin/bash
# GitHub utilities for release scripts
# This file should be sourced by other scripts: source scripts/lib/github-utils.sh

# Ensure common.sh is loaded
if ! declare -f print_status > /dev/null; then
    echo "Error: common.sh must be sourced before github-utils.sh"
    exit 1
fi

# Check if GitHub token is available
check_github_token() {
    print_status "info" "Checking GitHub authentication..."
    
    # Check environment variable
    if [ -n "$GITHUB_TOKEN" ]; then
        print_status "success" "GitHub token found in environment variable"
        return 0
    fi
    
    # Check if GitHub CLI is authenticated
    if command_exists gh; then
        if gh auth status &> /dev/null; then
            print_status "success" "GitHub CLI is authenticated"
            return 0
        fi
    fi
    
    print_status "error" "GitHub authentication not found. Set GITHUB_TOKEN environment variable or authenticate with GitHub CLI"
    return 1
}

# Get GitHub repository information
get_github_repo_info() {
    local project_root=${1:-"."}
    
    cd "$project_root" || return 1
    
    # Get remote origin URL
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    
    if [ -z "$remote_url" ]; then
        print_status "error" "No git remote origin found"
        return 1
    fi
    
    # Extract owner and repo from URL
    local owner_repo
    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)\.git ]]; then
        owner_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    elif [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
        owner_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        print_status "error" "Cannot parse GitHub repository from remote URL: $remote_url"
        return 1
    fi
    
    echo "$owner_repo"
    return 0
}

# Check if release exists
check_release_exists() {
    local project_root=${1:-"."}
    local tag=$2
    
    if [ -z "$tag" ]; then
        print_status "error" "Release tag not provided"
        return 1
    fi
    
    cd "$project_root" || return 1
    
    print_status "info" "Checking if release $tag exists..."
    
    if command_exists gh; then
        # Use GitHub CLI
        if gh release view "$tag" &> /dev/null; then
            print_status "warning" "Release $tag already exists"
            return 0
        else
            print_status "info" "Release $tag does not exist"
            return 1
        fi
    else
        # Use git to check if tag exists
        if git tag -l | grep -q "^$tag$"; then
            print_status "warning" "Tag $tag exists locally"
            return 0
        else
            print_status "info" "Tag $tag does not exist"
            return 1
        fi
    fi
}

# Extract changelog section for release
extract_changelog_section() {
    local project_root=${1:-"."}
    local version=$2
    
    if [ -z "$version" ]; then
        print_status "error" "Version not provided for changelog extraction"
        return 1
    fi
    
    local changelog_path="$project_root/CHANGELOG.md"
    
    if [ ! -f "$changelog_path" ]; then
        print_status "warning" "CHANGELOG.md not found"
        echo "Release $version"
        return 0
    fi
    
    # Extract changelog section for the version
    local changelog_section
    changelog_section=$(awk "/^## \\[$version\\]/{flag=1; next} /^## \\[/{flag=0} flag" "$changelog_path")
    
    if [ -z "$changelog_section" ]; then
        print_status "warning" "No changelog section found for version $version"
        echo "Release $version"
        return 0
    fi
    
    # Clean up the changelog section
    echo "$changelog_section" | sed '/^$/d' | head -20  # Remove empty lines and limit to 20 lines
    return 0
}

# Create GitHub release with CLI
create_release_with_cli() {
    local project_root=${1:-"."}
    local version=$2
    local prerelease=${3:-false}
    
    if [ -z "$version" ]; then
        print_status "error" "Version not provided"
        return 1
    fi
    
    cd "$project_root" || return 1
    
    local tag="v$version"
    local title="Release $version"
    local notes
    
    print_status "info" "Creating GitHub release $tag with CLI..."
    
    # Extract changelog section
    notes=$(extract_changelog_section "$project_root" "$version")
    
    # Create release command
    local release_cmd="gh release create \"$tag\" --title \"$title\" --notes \"$notes\""
    
    if [ "$prerelease" = "true" ]; then
        release_cmd="$release_cmd --prerelease"
    fi
    
    # Debug: Print the command being executed
    print_verbose "Executing GitHub CLI command: $release_cmd"
    
    # Execute release creation
    if eval "$release_cmd"; then
        print_status "success" "Release created successfully"
        
        # Get release URL
        local release_url
        release_url=$(gh release view "$tag" --json url -q '.url' 2>/dev/null)
        if [ -n "$release_url" ]; then
            print_status "info" "Release URL: $release_url"
        fi
        
        return 0
    else
        print_status "error" "Failed to create release"
        return 1
    fi
}

# Upload assets to release
upload_release_assets() {
    local project_root=${1:-"."}
    local version=$2
    shift 2
    local assets=("$@")
    
    if [ -z "$version" ]; then
        print_status "error" "Version not provided"
        return 1
    fi
    
    cd "$project_root" || return 1
    
    local tag="v$version"
    
    print_status "info" "Uploading assets to release $tag..."
    
    if [ ${#assets[@]} -eq 0 ]; then
        print_status "warning" "No assets to upload"
        return 0
    fi
    
    if ! command_exists gh; then
        print_status "error" "GitHub CLI not available for asset upload"
        return 1
    fi
    
    # Upload each asset
    for asset in "${assets[@]}"; do
        if [ -f "$asset" ]; then
            print_status "info" "Uploading $(basename "$asset")..."
            
            if gh release upload "$tag" "$asset"; then
                print_status "success" "Uploaded $(basename "$asset")"
            else
                print_status "error" "Failed to upload $(basename "$asset")"
                return 1
            fi
        else
            print_status "warning" "Asset not found: $asset"
        fi
    done
    
    return 0
}

# Find release assets
find_release_assets() {
    local project_root=${1:-"."}
    local assets=()
    
    # Find wheel files
    if [ -d "$project_root/dist" ]; then
        while IFS= read -r -d '' file; do
            assets+=("$file")
        done < <(find "$project_root/dist" -name "*.whl" -type f -print0)
        
        while IFS= read -r -d '' file; do
            assets+=("$file")
        done < <(find "$project_root/dist" -name "*.tar.gz" -type f -print0)
    fi
    
    # Add documentation files
    for doc in "CHANGELOG.md" "README.md" "LICENSE" "LICENSE.txt"; do
        if [ -f "$project_root/$doc" ]; then
            assets+=("$project_root/$doc")
        fi
    done
    
    # Return found assets
    printf '%s\n' "${assets[@]}"
}

# Verify release
verify_release() {
    local project_root=${1:-"."}
    local version=$2
    
    if [ -z "$version" ]; then
        print_status "error" "Version not provided"
        return 1
    fi
    
    cd "$project_root" || return 1
    
    local tag="v$version"
    
    print_status "info" "Verifying release $tag..."
    
    if ! command_exists gh; then
        print_status "warning" "GitHub CLI not available for verification"
        return 0
    fi
    
    # Check if release exists
    if gh release view "$tag" &> /dev/null; then
        print_status "success" "Release verified successfully"
        
        # Show release info
        print_status "info" "Release information:"
        gh release view "$tag" --json tagName,name,url,publishedAt,assets | jq -r '
            "Tag: \(.tagName)",
            "Name: \(.name)",
            "URL: \(.url)",
            "Published: \(.publishedAt)",
            "Assets: \(if .assets | length > 0 then (.assets | map(.name) | join(", ")) else "None" end)"
        ' 2>/dev/null || {
            echo "  Tag: $tag"
            echo "  Status: Published"
        }
        
        return 0
    else
        print_status "error" "Release verification failed"
        return 1
    fi
}

# Delete release (for cleanup)
delete_release() {
    local project_root=${1:-"."}
    local version=$2
    
    if [ -z "$version" ]; then
        print_status "error" "Version not provided"
        return 1
    fi
    
    cd "$project_root" || return 1
    
    local tag="v$version"
    
    print_status "info" "Deleting release $tag..."
    
    if ! command_exists gh; then
        print_status "error" "GitHub CLI not available for release deletion"
        return 1
    fi
    
    if gh release delete "$tag" --confirm; then
        print_status "success" "Release deleted successfully"
        return 0
    else
        print_status "error" "Failed to delete release"
        return 1
    fi
}

# Generate release report
generate_release_report() {
    local project_root=${1:-"."}
    local version=$2
    
    if [ -z "$version" ]; then
        print_status "error" "Version not provided"
        return 1
    fi
    
    local report_file="$project_root/github-release-report.txt"
    local tag="v$version"
    
    print_status "info" "Generating release report..."
    
    cat > "$report_file" << EOF
GitHub Release Report
=====================

Date: $(date)
Project Root: $project_root
Version: $version
Release Tag: $tag

Repository Information:
$(get_github_repo_info "$project_root" 2>/dev/null || echo "Unknown")

Release Assets:
EOF
    
    # List assets
    local assets
    assets=$(find_release_assets "$project_root")
    
    if [ -n "$assets" ]; then
        echo "$assets" | while read -r asset; do
            if [ -f "$asset" ]; then
                echo "- $(basename "$asset") ($(du -h "$asset" | cut -f1))" >> "$report_file"
            fi
        done
    else
        echo "- No assets found" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    
    # Add release URL if available
    if command_exists gh; then
        local release_url
        release_url=$(gh release view "$tag" --json url -q '.url' 2>/dev/null)
        if [ -n "$release_url" ]; then
            echo "Release URL: $release_url" >> "$report_file"
        fi
    fi
    
    echo "" >> "$report_file"
    echo "Release Status: SUCCESS" >> "$report_file"
    
    print_status "success" "Release report generated: $report_file"
}

# Main GitHub release function
create_github_release() {
    local project_root=${1:-"."}
    local version=$2
    local prerelease=${3:-false}
    
    if [ -z "$version" ]; then
        print_status "error" "Version not provided"
        return 1
    fi
    
    print_header "Creating GitHub Release"
    
    # Validate project root
    if ! validate_project_root "$project_root"; then
        return 1
    fi
    
    # Change to project root
    if ! change_to_project_root "$project_root"; then
        return 1
    fi
    
    # Check GitHub authentication
    if ! check_github_token; then
        return 1
    fi
    
    local tag="v$version"
    
    # Check if release already exists
    if check_release_exists "$project_root" "$tag"; then
        print_status "warning" "Release $tag already exists"
        return 0
    fi
    
    # Create release
    if ! create_release_with_cli "$project_root" "$version" "$prerelease"; then
        return 1
    fi
    
    # Find and upload assets
    local assets
    assets=$(find_release_assets "$project_root")
    
    if [ -n "$assets" ]; then
        local asset_array=()
        while IFS= read -r asset; do
            asset_array+=("$asset")
        done <<< "$assets"
        
        if ! upload_release_assets "$project_root" "$version" "${asset_array[@]}"; then
            print_status "warning" "Asset upload failed, but continuing..."
        fi
    fi
    
    # Verify release
    if ! verify_release "$project_root" "$version"; then
        print_status "warning" "Release verification failed, but continuing..."
    fi
    
    # Generate report
    generate_release_report "$project_root" "$version"
    
    print_status "success" "GitHub release created successfully!"
    
    return 0
}