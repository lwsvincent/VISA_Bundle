#!/bin/bash
# Check if project is ready for release
# Usage: ./check-release-ready.sh

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
    echo -e "${BLUE}  發布準備狀態檢查${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo ""
}

# Check results
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Functions
check_git_status() {
    print_status "info" "檢查 Git 狀態..."
    
    # Check if in git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_status "error" "不在 Git 儲存庫中"
        ((CHECKS_FAILED++))
        return 1
    fi
    
    # Check current branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "develop" ]; then
        print_status "warning" "當前分支是 '$current_branch'，建議在 'develop' 分支發布"
        ((WARNINGS++))
    else
        print_status "success" "在 develop 分支"
        ((CHECKS_PASSED++))
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_status "warning" "有未提交的變更"
        git status --porcelain | head -5
        ((WARNINGS++))
    else
        print_status "success" "沒有未提交的變更"
        ((CHECKS_PASSED++))
    fi
    
    # Check if up to date with remote
    if git remote > /dev/null 2>&1; then
        git fetch > /dev/null 2>&1
        local_commit=$(git rev-parse HEAD)
        remote_commit=$(git rev-parse @{u} 2>/dev/null || echo "no_remote")
        
        if [ "$remote_commit" = "no_remote" ]; then
            print_status "warning" "沒有設定遠端分支"
            ((WARNINGS++))
        elif [ "$local_commit" != "$remote_commit" ]; then
            print_status "warning" "本地分支與遠端不同步"
            ((WARNINGS++))
        else
            print_status "success" "與遠端同步"
            ((CHECKS_PASSED++))
        fi
    fi
}

check_project_structure() {
    print_status "info" "檢查專案結構..."
    
    # Check for Python project files
    local python_files=("setup.py" "pyproject.toml")
    local found_python=false
    
    for file in "${python_files[@]}"; do
        if [ -f "$file" ]; then
            print_status "success" "找到 Python 專案文件: $file"
            found_python=true
            break
        fi
    done
    
    if [ "$found_python" = false ]; then
        print_status "error" "找不到 Python 專案文件 (setup.py 或 pyproject.toml)"
        ((CHECKS_FAILED++))
        return 1
    fi
    ((CHECKS_PASSED++))
    
    # Check for CHANGELOG.md
    if [ -f "CHANGELOG.md" ]; then
        print_status "success" "找到 CHANGELOG.md"
        ((CHECKS_PASSED++))
    else
        print_status "error" "找不到 CHANGELOG.md"
        ((CHECKS_FAILED++))
    fi
    
    # Check for tests
    if [ -d "tests" ] || [ -d "test" ]; then
        print_status "success" "找到測試目錄"
        ((CHECKS_PASSED++))
    else
        print_status "warning" "找不到測試目錄"
        ((WARNINGS++))
    fi
}

check_version_consistency() {
    print_status "info" "檢查版本一致性..."
    
    local versions=()
    
    # Check setup.py
    if [ -f "setup.py" ]; then
        setup_version=$(grep -oP 'version\s*=\s*["\'"'"']\K[^"'"'"']+' setup.py 2>/dev/null || echo "not_found")
        if [ "$setup_version" != "not_found" ]; then
            versions+=("setup.py:$setup_version")
            print_status "info" "setup.py 版本: $setup_version"
        fi
    fi
    
    # Check pyproject.toml
    if [ -f "pyproject.toml" ]; then
        pyproject_version=$(grep -oP 'version\s*=\s*["\'"'"']\K[^"'"'"']+' pyproject.toml 2>/dev/null || echo "not_found")
        if [ "$pyproject_version" != "not_found" ]; then
            versions+=("pyproject.toml:$pyproject_version")
            print_status "info" "pyproject.toml 版本: $pyproject_version"
        fi
    fi
    
    # Check __init__.py files
    while IFS= read -r -d '' init_file; do
        init_version=$(grep -oP '__version__\s*=\s*["\'"'"']\K[^"'"'"']+' "$init_file" 2>/dev/null || echo "not_found")
        if [ "$init_version" != "not_found" ]; then
            versions+=("$init_file:$init_version")
            print_status "info" "$init_file 版本: $init_version"
        fi
    done < <(find . -name "__init__.py" -not -path "./build/*" -not -path "./dist/*" -not -path "./.git/*" -print0)
    
    # Check CHANGELOG.md latest version
    if [ -f "CHANGELOG.md" ]; then
        changelog_version=$(grep -oP '## \[\K[^\]]+' CHANGELOG.md | head -1 2>/dev/null || echo "not_found")
        if [ "$changelog_version" != "not_found" ]; then
            versions+=("CHANGELOG.md:$changelog_version")
            print_status "info" "CHANGELOG.md 最新版本: $changelog_version"
        fi
    fi
    
    # Check consistency
    if [ ${#versions[@]} -eq 0 ]; then
        print_status "error" "找不到任何版本號"
        ((CHECKS_FAILED++))
        return 1
    fi
    
    # Extract unique versions
    unique_versions=$(printf '%s\n' "${versions[@]}" | cut -d: -f2 | sort -u)
    version_count=$(echo "$unique_versions" | wc -l)
    
    if [ "$version_count" -eq 1 ]; then
        print_status "success" "所有版本號一致: $(echo "$unique_versions" | tr -d '\n')"
        ((CHECKS_PASSED++))
    else
        print_status "error" "版本號不一致:"
        for version_info in "${versions[@]}"; do
            echo "  - $version_info"
        done
        ((CHECKS_FAILED++))
    fi
}

check_tests() {
    print_status "info" "檢查測試..."
    
    # Check if pytest is available
    if command -v pytest > /dev/null 2>&1; then
        print_status "success" "pytest 可用"
        
        # Try to run tests
        if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -d "tests" ]; then
            print_status "info" "嘗試執行測試..."
            if pytest --tb=no -q > /dev/null 2>&1; then
                test_count=$(pytest --collect-only -q 2>/dev/null | grep "test session starts" -A 1 | tail -1 | grep -oP '\d+' | head -1 || echo "0")
                print_status "success" "測試通過 ($test_count 個測試)"
                ((CHECKS_PASSED++))
            else
                print_status "error" "測試失敗"
                print_status "info" "執行 'pytest -v' 查看詳細錯誤"
                ((CHECKS_FAILED++))
            fi
        else
            print_status "warning" "找不到測試配置"
            ((WARNINGS++))
        fi
    else
        print_status "warning" "pytest 未安裝"
        ((WARNINGS++))
    fi
}

check_code_quality() {
    print_status "info" "檢查代碼品質..."
    
    # Check flake8
    if command -v flake8 > /dev/null 2>&1; then
        if flake8 . --exclude=build,dist,.git --max-line-length=100 > /dev/null 2>&1; then
            print_status "success" "flake8 檢查通過"
            ((CHECKS_PASSED++))
        else
            print_status "warning" "flake8 檢查有問題"
            ((WARNINGS++))
        fi
    else
        print_status "info" "flake8 未安裝（跳過）"
    fi
    
    # Check black
    if command -v black > /dev/null 2>&1; then
        if black --check . --exclude='(build|dist|\.git)' > /dev/null 2>&1; then
            print_status "success" "black 格式檢查通過"
            ((CHECKS_PASSED++))
        else
            print_status "warning" "black 格式檢查有問題"
            print_status "info" "執行 'black .' 自動格式化"
            ((WARNINGS++))
        fi
    else
        print_status "info" "black 未安裝（跳過）"
    fi
}

check_github_auth() {
    print_status "info" "檢查 GitHub 認證..."
    
    # Check GitHub CLI
    if command -v gh > /dev/null 2>&1; then
        if gh auth status > /dev/null 2>&1; then
            print_status "success" "GitHub CLI 已認證"
            ((CHECKS_PASSED++))
        else
            print_status "warning" "GitHub CLI 未認證"
            print_status "info" "執行 'gh auth login' 進行認證"
            ((WARNINGS++))
        fi
    elif [ -n "$GITHUB_TOKEN" ]; then
        print_status "success" "GITHUB_TOKEN 環境變數已設定"
        ((CHECKS_PASSED++))
    else
        print_status "warning" "找不到 GitHub 認證"
        print_status "info" "請安裝 GitHub CLI 或設定 GITHUB_TOKEN"
        ((WARNINGS++))
    fi
}

# Main execution
main() {
    print_header
    
    check_git_status
    echo ""
    check_project_structure
    echo ""
    check_version_consistency
    echo ""
    check_tests
    echo ""
    check_code_quality
    echo ""
    check_github_auth
    
    # Summary
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  檢查摘要${NC}"
    echo -e "${BLUE}══════════════════════════════════════════${NC}"
    
    print_status "success" "通過檢查: $CHECKS_PASSED"
    if [ $CHECKS_FAILED -gt 0 ]; then
        print_status "error" "失敗檢查: $CHECKS_FAILED"
    fi
    if [ $WARNINGS -gt 0 ]; then
        print_status "warning" "警告項目: $WARNINGS"
    fi
    
    echo ""
    if [ $CHECKS_FAILED -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            print_status "success" "🎉 專案已準備好發布！"
            echo ""
            print_status "info" "您現在可以說：「請參考發布流程，請你發布最新版」"
        else
            print_status "warning" "⚠️  專案基本準備就緒，但有警告項目"
            echo ""
            print_status "info" "建議處理警告後再發布，或直接發布"
        fi
        exit 0
    else
        print_status "error" "❌ 專案尚未準備好發布"
        echo ""
        print_status "info" "請先解決上述錯誤後再嘗試發布"
        exit 1
    fi
}

# Run main function
main "$@"