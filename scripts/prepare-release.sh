#!/bin/bash
# Prepare release (update versions, CHANGELOG) but don't push
# Usage: ./prepare-release.sh [patch|minor|major] "Release description"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  準備發布 (不推送)${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo ""
}

# Usage information
show_usage() {
    echo "Usage: $0 [patch|minor|major] \"Release description\""
    echo ""
    echo "Examples:"
    echo "  $0 patch \"Fix calculator division bug\""
    echo "  $0 minor \"Add new export feature\""
    echo "  $0 major \"Complete rewrite with new architecture\""
    echo ""
    echo "Version types:"
    echo "  patch: 1.0.4 → 1.0.5 (bug fixes)"
    echo "  minor: 1.0.4 → 1.1.0 (new features)"
    echo "  major: 1.0.4 → 2.0.0 (breaking changes)"
}

# Parse command line arguments
VERSION_TYPE="$1"
RELEASE_DESCRIPTION="$2"

if [ -z "$VERSION_TYPE" ] || [ -z "$RELEASE_DESCRIPTION" ]; then
    show_usage
    exit 1
fi

if [[ ! "$VERSION_TYPE" =~ ^(patch|minor|major)$ ]]; then
    print_status "error" "Invalid version type: $VERSION_TYPE"
    show_usage
    exit 1
fi

# Increment version number
increment_version() {
    local version="$1"
    local type="$2"
    
    # Extract major, minor, patch
    IFS='.' read -r major minor patch <<< "$version"
    
    case "$type" in
        "patch")
            ((patch++))
            ;;
        "minor")
            ((minor++))
            patch=0
            ;;
        "major")
            ((major++))
            minor=0
            patch=0
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Get current version from setup.py
get_current_version() {
    if [ -f "setup.py" ]; then
        grep -oP 'version\s*=\s*["\'"'"']\K[^"'"'"']+' setup.py 2>/dev/null
    elif [ -f "pyproject.toml" ]; then
        grep -oP 'version\s*=\s*["\'"'"']\K[^"'"'"']+' pyproject.toml 2>/dev/null
    else
        echo ""
    fi
}

# Update version in setup.py
update_setup_py() {
    local new_version="$1"
    
    if [ -f "setup.py" ]; then
        if grep -q 'version\s*=' setup.py; then
            sed -i.bak "s/version\s*=\s*[\"'][^\"']*[\"']/version=\"$new_version\"/" setup.py
            rm -f setup.py.bak
            print_status "success" "已更新 setup.py 版本至 $new_version"
            return 0
        fi
    fi
    return 1
}

# Update version in pyproject.toml
update_pyproject_toml() {
    local new_version="$1"
    
    if [ -f "pyproject.toml" ]; then
        if grep -q 'version\s*=' pyproject.toml; then
            sed -i.bak "s/version\s*=\s*[\"'][^\"']*[\"']/version = \"$new_version\"/" pyproject.toml
            rm -f pyproject.toml.bak
            print_status "success" "已更新 pyproject.toml 版本至 $new_version"
            return 0
        fi
    fi
    return 1
}

# Update version in __init__.py files
update_init_files() {
    local new_version="$1"
    local updated_count=0
    
    while IFS= read -r -d '' init_file; do
        if grep -q '__version__\s*=' "$init_file"; then
            sed -i.bak "s/__version__\s*=\s*[\"'][^\"']*[\"']/__version__ = \"$new_version\"/" "$init_file"
            rm -f "${init_file}.bak"
            print_status "success" "已更新 $init_file 版本至 $new_version"
            ((updated_count++))
        fi
    done < <(find . -name "__init__.py" -not -path "./build/*" -not -path "./dist/*" -not -path "./.git/*" -print0)
    
    return $updated_count
}

# Update CHANGELOG.md
update_changelog() {
    local new_version="$1"
    local description="$2"
    local current_date=$(date '+%Y-%m-%d')
    
    if [ ! -f "CHANGELOG.md" ]; then
        print_status "warning" "CHANGELOG.md 不存在，創建新文件"
        cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [$new_version] - $current_date

### Added
- $description

EOF
        print_status "success" "已創建 CHANGELOG.md 並添加 $new_version 條目"
        return 0
    fi
    
    # Create new entry
    local new_entry="## [$new_version] - $current_date

### Added
- $description

"
    
    # Insert after the header (find the first ## and insert before it)
    awk -v new_entry="$new_entry" '
    /^## \[/ && !inserted {
        print new_entry
        inserted = 1
    }
    { print }
    END {
        if (!inserted) {
            print new_entry
        }
    }' CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md
    
    print_status "success" "已更新 CHANGELOG.md 添加 $new_version 條目"
}

# Clean build artifacts
clean_artifacts() {
    print_status "info" "清理構建產物..."
    
    # Directories to clean
    local dirs=("build" "dist" "*.egg-info" "__pycache__" ".pytest_cache")
    
    for dir in "${dirs[@]}"; do
        if find . -name "$dir" -type d 2>/dev/null | grep -q .; then
            find . -name "$dir" -type d -exec rm -rf {} + 2>/dev/null || true
        fi
    done
    
    # Files to clean
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    
    print_status "success" "構建產物已清理"
}

# Generate commit message
generate_commit_message() {
    local new_version="$1"
    local description="$2"
    local version_type="$3"
    
    echo "Prepare release $new_version

$description

Version bump: $version_type release
"
}

# Main execution
main() {
    print_header
    
    # Check if in git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_status "error" "不在 Git 儲存庫中"
        exit 1
    fi
    
    # Get current version
    current_version=$(get_current_version)
    if [ -z "$current_version" ]; then
        print_status "error" "無法找到當前版本號"
        exit 1
    fi
    
    print_status "info" "當前版本: $current_version"
    
    # Calculate new version
    new_version=$(increment_version "$current_version" "$VERSION_TYPE")
    print_status "info" "新版本: $new_version ($VERSION_TYPE release)"
    
    echo ""
    print_status "info" "開始更新版本號..."
    
    # Update version files
    version_updated=false
    
    if update_setup_py "$new_version"; then
        version_updated=true
    fi
    
    if update_pyproject_toml "$new_version"; then
        version_updated=true
    fi
    
    update_init_files "$new_version"
    if [ $? -gt 0 ]; then
        version_updated=true
    fi
    
    if [ "$version_updated" = false ]; then
        print_status "error" "無法更新任何版本文件"
        exit 1
    fi
    
    echo ""
    print_status "info" "更新 CHANGELOG.md..."
    update_changelog "$new_version" "$RELEASE_DESCRIPTION"
    
    echo ""
    print_status "info" "清理環境..."
    clean_artifacts
    
    echo ""
    print_status "info" "準備提交訊息..."
    commit_message=$(generate_commit_message "$new_version" "$RELEASE_DESCRIPTION" "$VERSION_TYPE")
    
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  準備完成${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    print_status "success" "版本已準備: $current_version → $new_version"
    print_status "success" "CHANGELOG.md 已更新"
    print_status "success" "構建產物已清理"
    
    echo ""
    print_status "info" "建議的下一步:"
    echo ""
    echo "1. 檢查變更:"
    echo "   git diff"
    echo ""
    echo "2. 提交變更:"
    echo "   git add -A"
    echo "   git commit -m \"$(echo "$commit_message" | head -1)\""
    echo ""
    echo "3. 或者直接說："
    echo "   「請參考發布流程，請你發布最新版」"
    
    echo ""
    print_status "success" "🎉 發布準備完成！版本 $new_version 已準備就緒"
}

# Run main function
main "$@"