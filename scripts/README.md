# Windows Batch Scripts

這個目錄包含一套完整的Windows批處理腳本，用於自動化Python項目的開發、測試、建構和發布流程。

## 📋 腳本概覽

### 🔧 環境管理
- [`create_venv.bat`](#create_venvbat) - 創建Python虛擬環境
- [`setup_test_env.bat`](#setup_test_envbat) - 設置測試環境
- [`cleanup_build.bat`](#cleanup_buildbat) - 清理構建檔案

### 🧪 測試和品質檢查
- [`run_tests.bat`](#run_testsbat) - 運行測試套件

### 📦 建構和安裝
- [`build_wheel.bat`](#build_wheelbat) - 建構Python wheel包
- [`install_wheel.bat`](#install_wheelbat) - 安裝wheel包

### 🔖 版本管理
- [`get_version.bat`](#get_versionbat) - 獲取版本信息
- [`update_version.bat`](#update_versionbat) - 更新版本號
- [`create_tag.bat`](#create_tagbat) - 創建Git標籤

### 🌿 Git分支管理
- [`change_branch.bat`](#change_branchbat) - 切換或創建分支
- [`delete_branch.bat`](#delete_branchbat) - 刪除分支
- [`merge_to_main.bat`](#merge_to_mainbat) - 合併到主分支

### 🚀 發布管理
- [`release_project.bat`](#release_projectbat) - **完整自動化發布流程** ⭐
- [`push_to_release.bat`](#push_to_releasebat) - 推送到發布分支
- [`release_to_remote.bat`](#release_to_remotebat) - 創建GitHub發布
- [`release_to_testmatrix.bat`](#release_to_testmatrixbat) - 發布到TestMatrix

### 🌲 Subtree管理
- [`subtree_init.bat`](#subtree_initbat) - 初始化Subtree
- [`subtree_pull.bat`](#subtree_pullbat) - 更新Subtree

---

## 📖 詳細文檔

### create_venv.bat

創建Python虛擬環境的多功能腳本。

**語法:**
```batch
create_venv.bat [OPTION]
```

**選項:**
- `-local` - 創建本地開發環境 (.venv)
- `-test` - 創建測試環境 (test-venv)
- `-dev` - 包含開發依賴 ([dev] extras)

**使用示例:**
```batch
REM 創建默認虛擬環境
create_venv.bat

REM 創建本地開發環境
create_venv.bat -local

REM 創建測試環境
create_venv.bat -test

REM 創建包含開發依賴的環境
create_venv.bat -local -dev
create_venv.bat -test -dev
```

**功能特點:**
- 自動檢測現有環境並詢問是否覆蓋
- 支援多種環境類型（開發、測試）
- 自動安裝項目依賴和開發依賴
- UTF-8編碼支持
- 工作目錄保護

---

### setup_test_env.bat

專門用於設置測試環境的腳本。

**語法:**
```batch
setup_test_env.bat [ENV_NAME]
```

**參數:**
- `ENV_NAME` - 虛擬環境名稱（可選，默認為'test-venv'）

**使用示例:**
```batch
REM 設置默認測試環境
setup_test_env.bat

REM 設置自定義測試環境
setup_test_env.bat custom-test
```

---

### cleanup_build.bat

清理項目中的建構檔案和快取。

**語法:**
```batch
cleanup_build.bat
```

**清理內容:**
- Python快取檔案 (`__pycache__`, `*.pyc`)
- 建構檔案 (`build/`, `dist/`)
- Egg信息 (`*.egg-info`)
- pytest快取 (`.pytest_cache`)
- Coverage檔案 (`.coverage`)

---

### run_tests.bat

執行項目測試套件，支援多種環境和配置。

**語法:**
```batch
run_tests.bat [MODE] [ENV_OPTION]
```

**模式:**
- `basic` - 基本測試（默認）
- `full` - 完整測試（包含覆蓋率報告）

**環境選項:**
- `-global` - 使用全域Python環境
- `-venv ENV_NAME` - 使用指定虛擬環境
- `-testvenv ENV_NAME` - 使用指定測試環境

**使用示例:**
```batch
REM 基本測試
run_tests.bat

REM 完整測試（包含覆蓋率）
run_tests.bat full

REM 使用全域環境
run_tests.bat -global

REM 使用指定虛擬環境
run_tests.bat -venv myenv
run_tests.bat full -venv production
```

---

### build_wheel.bat

建構Python wheel包的腳本。

**語法:**
```batch
build_wheel.bat
```

**功能:**
- 自動創建和管理建構環境
- 清理舊的建構檔案
- 建構wheel和源代碼發布包
- 驗證建構結果

---

### install_wheel.bat

安裝wheel包到指定環境。

**語法:**
```batch
install_wheel.bat [OPTION]
```

**選項:**
- `--global` - 安裝到全域Python環境
- `--venv PATH` - 安裝到指定虛擬環境

**使用示例:**
```batch
REM 安裝到全域環境
install_wheel.bat --global

REM 安裝到指定虛擬環境
install_wheel.bat --venv .venv
install_wheel.bat --venv C:\path\to\venv

REM 自動尋找並安裝到最近的虛擬環境
install_wheel.bat
```

---

### get_version.bat

從各種來源獲取版本信息的多功能工具。

**語法:**
```batch
get_version.bat [OPTIONS]
```

**選項:**
- `-pyproject` - 從pyproject.toml獲取版本
- `-changelog` - 從CHANGELOG.md獲取最新版本
- `-changelog -hasunreleased` - 檢查CHANGELOG.md是否有Unreleased部分
- `-github_latest_tag` - 從Git標籤獲取最新版本

**使用示例:**
```batch
REM 從pyproject.toml獲取版本
get_version.bat -pyproject
REM 輸出: 1.2.3

REM 從CHANGELOG.md獲取版本
get_version.bat -changelog
REM 輸出: 1.2.0

REM 檢查是否有未發布內容
get_version.bat -changelog -hasunreleased
REM 輸出: true 或 false

REM 獲取最新Git標籤
get_version.bat -github_latest_tag
REM 輸出: v1.2.3
```

**功能特點:**
- 自動尋找項目根目錄
- 支援多種版本來源
- 智能解析CHANGELOG.md格式
- Git標籤版本提取

---

### update_version.bat

更新項目中的版本號。

**語法:**
```batch
update_version.bat <VERSION>
```

**參數:**
- `VERSION` - 新的版本號（如: 1.2.3）

**使用示例:**
```batch
REM 更新版本到1.2.3
update_version.bat 1.2.3
```

**更新檔案:**
- `pyproject.toml` - 更新version字段
- `README.md` - 更新版本引用
- `CHANGELOG.md` - 將[Unreleased]替換為版本和日期

---

### create_tag.bat

創建Git版本標籤。

**語法:**
```batch
create_tag.bat [VERSION]
```

**參數:**
- `VERSION` - 版本號（可選，自動從pyproject.toml讀取）

**使用示例:**
```batch
REM 手動指定版本
create_tag.bat 1.2.3

REM 自動從pyproject.toml讀取版本
create_tag.bat
```

**功能:**
- 創建帶註釋的Git標籤
- 自動推送標籤到遠端
- 從CHANGELOG.md提取發布說明

---

### change_branch.bat

切換到現有分支或創建新分支。

**語法:**
```batch
change_branch.bat <BRANCH_NAME>
```

**參數:**
- `BRANCH_NAME` - 分支名稱

**使用示例:**
```batch
REM 切換到現有分支
change_branch.bat main
change_branch.bat develop

REM 創建並切換到新分支
change_branch.bat feature/new-feature
```

**功能:**
- 自動檢測分支是否存在
- 支援本地和遠端分支
- 創建新分支（如果不存在）

---

### delete_branch.bat

安全刪除Git分支。

**語法:**
```batch
delete_branch.bat <BRANCH_NAME> [--remote]
```

**參數:**
- `BRANCH_NAME` - 要刪除的分支名稱
- `--remote` - 同時刪除遠端分支

**使用示例:**
```batch
REM 刪除本地分支
delete_branch.bat feature/old-feature

REM 刪除本地和遠端分支
delete_branch.bat feature/old-feature --remote
```

**安全特性:**
- 保護主分支（main/master）不被刪除
- 防止刪除當前活躍分支
- 清晰的錯誤提示

---

### merge_to_main.bat

將當前分支合併到主分支。

**語法:**
```batch
merge_to_main.bat
```

**功能:**
- 自動檢測主分支（main或master）
- 切換到主分支並合併
- 推送合併結果到遠端

---

### release_project.bat

**🌟 完整的自動化發布流程腳本**

**語法:**
```batch
release_project.bat [INCREMENT_TYPE]
```

**參數:**
- `INCREMENT_TYPE` - 版本遞增類型
  - `-major` - 遞增主版本號 (X.0.0)
  - `-minor` - 遞增次版本號 (x.X.0)
  - `-patch` - 遞增修訂版本號 (x.x.X) [默認]

**使用示例:**
```batch
REM 默認patch版本遞增
release_project.bat

REM 指定版本遞增類型
release_project.bat -patch
release_project.bat -minor
release_project.bat -major
```

**完整發布流程包含12個步驟:**

1. **檢查分支狀態** - 確保在main分支且無未提交變更
2. **版本計算** - 根據遞增類型計算新版本號
3. **遠端版本檢查** - 獲取GitHub最新標籤版本
4. **版本比較** - 驗證新版本的合理性
5. **創建發布分支** - 創建並切換到release分支
6. **環境檢查** - 驗證Python和Git環境
7. **依賴檢查** - 檢查必要的工具（gh CLI等）
8. **測試執行** - 運行完整測試套件
9. **建構wheel包** - 建構發布包
10. **版本更新** - 更新pyproject.toml和CHANGELOG.md
11. **創建GitHub發布** - 創建標籤和GitHub Release
12. **合併和清理** - 合併到main分支並清理發布分支

**功能特點:**
- 全自動化流程，一鍵完成發布
- 智能版本計算和驗證
- 完整的錯誤處理和回滾機制
- 自動環境管理和清理
- GitHub集成（標籤、Release）
- UTF-8編碼支持和工作目錄保護

---

### push_to_release.bat

推送當前分支到release分支。

**語法:**
```batch
push_to_release.bat
```

**功能:**
- 自動複製wheel檔案和文檔
- 推送到release分支
- 更新遠端倉庫

---

### release_to_remote.bat

創建GitHub發布的腳本。

**語法:**
```batch
release_to_remote.bat <VERSION>
```

**參數:**
- `VERSION` - 發布版本號

**使用示例:**
```batch
REM 創建GitHub發布
release_to_remote.bat 1.2.3
```

**功能:**
- 使用GitHub CLI創建發布
- 從CHANGELOG.md提取發布說明
- 上傳wheel檔案作為發布資產
- UTF-8編碼支持

---

### release_to_testmatrix.bat

發布到TestMatrix倉庫的腳本。

**語法:**
```batch
release_to_testmatrix.bat
```

**功能:**
- 推送到TestMatrix遠端倉庫
- 同步發布檔案和文檔

---

### subtree_init.bat

初始化Git subtree的腳本。

**語法:**
```batch
subtree_init.bat [-rootpath PATH]
```

**參數:**
- `-rootpath PATH` - 指定項目根目錄路徑

**使用示例:**
```batch
REM 從項目根目錄初始化
subtree_init.bat

REM 指定項目根目錄
subtree_init.bat -rootpath "E:\TestMatrix\my_project"
```

---

### subtree_pull.bat

更新Git subtree的腳本。

**語法:**
```batch
subtree_pull.bat [-rootpath PATH]
```

**參數:**
- `-rootpath PATH` - 指定項目根目錄路徑

**使用示例:**
```batch
REM 自動尋找項目根目錄並更新
subtree_pull.bat

REM 指定項目根目錄
subtree_pull.bat -rootpath "E:\TestMatrix\my_project"
```

---

## 🛠️ 系統需求

### 基本需求
- Windows 10/11
- PowerShell 5.1+（用於UTF-8支持）
- Python 3.7+
- Git for Windows

### 發布功能需求
- GitHub CLI (`gh`) - 用於GitHub發布功能
- 有效的GitHub身份驗證

### 項目需求
- `pyproject.toml` - Python項目配置
- `CHANGELOG.md` - 版本變更記錄（可選）

---

## 🔧 特色功能

### UTF-8編碼支持
所有腳本都正確處理UTF-8編碼，支援中文和特殊字符。

### 工作目錄保護
所有腳本執行完畢後都會恢復到原始工作目錄。

### 虛擬環境管理
自動創建、檢測和管理Python虛擬環境。

### 錯誤處理
完整的錯誤檢查和友好的錯誤訊息。

### 參數化設計
靈活的命令行參數支持，適應不同使用場景。

---

## 🚀 推薦工作流程

### 日常開發
```batch
REM 1. 創建開發環境
create_venv.bat -local -dev

REM 2. 運行測試
run_tests.bat

REM 3. 切換分支
change_branch.bat feature/new-feature
```

### 發布流程
```batch
REM 一鍵自動化發布（推薦）
release_project.bat -minor

REM 或手動步驟（進階用戶）
update_version.bat 1.2.0
run_tests.bat full
build_wheel.bat
create_tag.bat
release_to_remote.bat 1.2.0
```

---

## ❗ 注意事項

1. **執行權限**: 確保有足夠的檔案系統權限
2. **網絡連接**: GitHub相關功能需要網絡連接
3. **編碼設置**: 建議使用UTF-8編碼保存文件
4. **虛擬環境**: 建議在虛擬環境中運行Python相關操作
5. **分支策略**: 腳本假設使用標準Git Flow（single release branch）

---

## 🐛 故障排除

### 常見問題

**腳本無法執行**
- 檢查執行權限
- 確保PowerShell版本支援UTF-8

**GitHub操作失敗**
- 檢查GitHub CLI安裝和身份驗證
- 確保網絡連接正常

**虛擬環境問題**
- 檢查Python安裝和PATH設置
- 確保有足夠的磁碟空間

**編碼問題**
- 使用UTF-8編碼保存檔案
- 檢查PowerShell編碼設置

---

*這些腳本是Template Project的核心組件，為Windows開發環境提供完整的Python項目自動化解決方案。*