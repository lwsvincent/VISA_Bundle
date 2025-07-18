# Git Flow Release Guide

## 概述
本指南說明如何使用Template Project的標準Git Flow release流程，提供完整的自動化部署和發布功能。

## Git Flow 分支策略

### 🌳 標準分支結構
- **`main`**: 生產環境穩定版本
- **`develop`**: 開發主分支，整合各功能分支  
- **`release`**: 單一發布分支（遵循Git Flow標準）
- **`feature/功能名`**: 功能開發分支
- **`hotfix/修復名`**: 緊急修復分支

### 🔄 Release 分支生命週期
1. **創建**: 從 `develop` 分支創建單一 `release` 分支
2. **準備**: 更新版本號和變更日誌
3. **測試**: 自動化測試和品質檢查
4. **發布**: 自動創建GitHub release和標籤
5. **合併**: 合併回 `main` 和 `develop` 
6. **清理**: 刪除 `release` 分支，保留Git標籤追蹤版本

## 功能特色

### 🔄 自動化流程
- **智能分支檢測**: 自動識別release分支並觸發檢查
- **版本同步驗證**: 確保CHANGELOG.md與專案版本一致
- **清潔環境測試**: 在隔離的虛擬環境中進行測試
- **自動GitHub發布**: 創建標籤、release並上傳資產

### 📋 完整檢查
- Changelog版本檢查
- Wheel包構建和驗證
- 虛擬環境測試
- GitHub release創建
- 資產自動上傳

## 設置需求

### 1. 基本需求
- Python 3.8+
- Git 2.7+
- Template Project已集成到專案中

### 2. 依賴工具
```bash
# 必需工具
pip install build wheel pytest

# 可選工具（推薦）
pip install twine  # 用於包驗證
```

### 3. GitHub認證
選擇以下任一方式進行GitHub認證：

#### 方式1: GitHub CLI（推薦）
```bash
# 安裝GitHub CLI
# Windows: winget install GitHub.cli
# macOS: brew install gh
# Linux: 參考 https://github.com/cli/cli#installation

# 認證
gh auth login
```

#### 方式2: Personal Access Token
```bash
# 創建token: https://github.com/settings/tokens
# 需要的權限: repo, write:packages
export GITHUB_TOKEN="your_token_here"
```

## 使用方法

### 完整 Git Flow Release 流程

#### 1. 創建Release分支
```bash
# 從develop分支創建release分支
git checkout develop
git pull origin develop
git checkout -b release
```

#### 2. 準備Release
```bash
# 1. 更新版本號
# 在 setup.py, __init__.py 中更新版本

# 2. 更新CHANGELOG.md
# 添加新版本的更改記錄

# 3. 提交變更
git add .
git commit -m "Prepare release v1.0.3"
```

#### 3. 推送觸發自動化
```bash
# 推送到release分支（會自動觸發檢查和GitHub發布）
git push origin release
```

#### 4. 完成Release（手動）
```bash
# 自動化完成後，手動合併回主分支
git checkout main
git merge release
git tag -a v1.0.3 -m "Release 1.0.3"

# 合併回開發分支
git checkout develop
git merge release

# 清理：刪除release分支
git branch -d release

# 推送所有變更
git push origin main develop v1.0.3
```

### 3. 自動化流程
推送到release分支後，系統會自動執行：

1. **分支檢測**: 確認是release分支
2. **版本檢查**: 驗證changelog與專案版本一致
3. **構建Wheel**: 創建distribution包
4. **測試驗證**: 在清潔環境中測試
5. **GitHub發布**: 創建標籤和release
6. **資產上傳**: 上傳wheel、changelog等文件

## 配置選項

### 1. Release配置文件
編輯 `template_project/config/release-config.yml`:

```yaml
release:
  # Git Flow標準分支模式 - 僅使用單一release分支
  branch_patterns:
    - "release"  # 標準Git Flow release分支
    - "main"     # 生產環境主分支
    - "master"   # 舊版主分支（向後相容）
  # 注意：不再支援 release/* 模式以避免多分支混亂
    
  # 版本檢查設定
  version_check:
    enabled: true
    changelog_file: "CHANGELOG.md"
    
  # 構建設定
  build:
    enabled: true
    clean_before_build: true
    
  # 測試設定
  testing:
    enabled: true
    test_command: "pytest"
    test_args: "--tb=short -v"
    
  # GitHub設定
  github:
    enabled: true
    create_tag: true
    create_release: true
    upload_assets:
      - "dist/*.whl"
      - "CHANGELOG.md"
      - "README.md"
```

### 2. 專案特定配置
可以在專案根目錄創建 `release-config.yml` 覆蓋默認設定：

```yaml
# 只覆蓋需要修改的部分
release:
  testing:
    test_args: "--tb=short -v --cov=my_package"
  github:
    upload_assets:
      - "dist/*.whl"
      - "dist/*.tar.gz"
      - "CHANGELOG.md"
      - "README.md"
      - "LICENSE"
```

## 支持的專案結構

### 1. 標準setuptools專案
```
project/
├── setup.py
├── CHANGELOG.md
├── README.md
├── requirements.txt
├── requirements-dev.txt
├── tests/
└── my_package/
    └── __init__.py
```

### 2. 現代Python專案 (pyproject.toml)
```
project/
├── pyproject.toml
├── CHANGELOG.md
├── README.md
├── tests/
└── src/
    └── my_package/
        └── __init__.py
```

### 3. Poetry專案
```
project/
├── pyproject.toml  # with [tool.poetry]
├── CHANGELOG.md
├── README.md
├── tests/
└── my_package/
    └── __init__.py
```

## Changelog格式

### 支持的格式

#### 1. Keep a Changelog格式（推薦）
```markdown
# Changelog

## [1.0.0] - 2024-01-01
### Added
- 新功能描述

### Changed
- 改變的功能

### Fixed
- 修復的問題

## [0.9.0] - 2023-12-01
...
```

#### 2. 簡單格式
```markdown
# Changelog

## v1.0.0 (2024-01-01)
- 新功能描述
- 修復的問題

## v0.9.0 (2023-12-01)
...
```

## 故障排除

### 常見問題

#### 1. 版本不匹配錯誤
```
✗ Version mismatch: project=1.0.0, changelog=0.9.0
```

**解決方案:**
- 確保setup.py/pyproject.toml中的版本與CHANGELOG.md最新版本一致
- 檢查版本號格式是否為語義化版本（如：1.0.0）

#### 2. 構建失敗
```
✗ Failed to build wheel with setuptools
```

**解決方案:**
```bash
# 安裝構建工具
pip install build wheel setuptools

# 檢查setup.py語法
python setup.py check

# 手動測試構建
python setup.py bdist_wheel
```

#### 3. 測試失敗
```
✗ Tests failed (30s)
```

**解決方案:**
```bash
# 本地運行測試
pytest --tb=short -v

# 檢查測試依賴
pip install -r requirements-dev.txt

# 修復測試問題後重新推送
```

#### 4. GitHub認證問題
```
✗ GitHub token not found
```

**解決方案:**
```bash
# 使用GitHub CLI
gh auth login

# 或設置環境變量
export GITHUB_TOKEN="your_token_here"
```

#### 5. 資產上傳失敗
```
⚠ Asset upload failed, but continuing...
```

**解決方案:**
- 檢查GitHub token權限
- 確保文件存在且可訪問
- 檢查網絡連接

### 調試模式

#### 1. 手動運行檢查
```bash
# 進入template_project目錄
cd template_project

# 手動運行版本檢查
python scripts/release/check-changelog.py ../

# 手動運行構建
bash scripts/release/build-wheel.sh ../

# 手動運行測試
bash scripts/release/test-release.sh ../

# 手動運行GitHub發布
bash scripts/release/github-release.sh ../
```

#### 2. 詳細輸出
```bash
# 設置詳細輸出
export VERBOSE=true

# 推送時查看詳細日誌
git push origin release
```

## 高級功能

### 1. 預發布版本
```bash
# 創建預發布版本
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

### 2. 自定義測試
在 `pytest.ini` 中配置測試參數：
```ini
[pytest]
addopts = -v --tb=short --cov=my_package --cov-report=html
testpaths = tests
```

### 3. 多環境支持
```yaml
# 在release-config.yml中
environments:
  development:
    github:
      create_release: false
  production:
    github:
      create_release: true
```

### 4. 自定義資產
```yaml
# 添加自定義資產
github:
  upload_assets:
    - "dist/*.whl"
    - "dist/*.tar.gz"
    - "docs/build/html/*"
    - "CHANGELOG.md"
    - "README.md"
    - "LICENSE"
```

## 最佳實踐

### 1. 版本管理
- 使用語義化版本號（1.0.0）
- 在CHANGELOG.md中詳細記錄變更
- 定期更新依賴版本

### 2. 測試策略
- 保持高測試覆蓋率
- 包含集成測試
- 定期更新測試依賴

### 3. 發布流程
- 在release分支進行最終測試
- 創建release前進行代碼審查
- 保持CHANGELOG.md的更新

### 4. 安全考慮
- 使用最小權限的GitHub token
- 不在代碼中硬編碼敏感信息
- 定期更新依賴以修復安全漏洞

## 支援和貢獻

### 問題報告
如果遇到問題，請：
1. 檢查本文檔的故障排除章節
2. 查看項目的GitHub Issues
3. 提供詳細的錯誤信息和重現步驟

### 功能建議
歡迎提出功能建議或改進意見：
1. 創建GitHub Issue描述需求
2. 提供使用場景和預期行為
3. 考慮向後兼容性

---

*此文檔會持續更新，請定期查看最新版本*