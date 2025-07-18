# Template Project 實施計劃

## 專案概述
此template project旨在為多人協作和多個小專案提供統一的Git pre-push規則管理和AI prompts，使用Git subtree功能進行集成。

## 目標
- 統一化多個專案的代碼品質標準
- 提供標準化的AI協作模板
- 簡化Git subtree的使用和管理
- 提高團隊協作效率

## 已完成的工作

### ✅ 1. 分析當前目錄結構
- 分析了 `E:\TestMatrix` 下的所有子專案
- 發現的專案類型：
  - `am_report_generator`: Python報告生成器（完整的CI/CD結構）
  - `am_shared`: 共享函式庫
  - `gui_export_single_report`: Web GUI應用
  - `testmatrix_repo`: 打包倉庫

### ✅ 2. 設計template project的目錄結構
```
template_project/
├── .git-hooks/                 # Git hooks模板
│   ├── pre-push               # 主要的pre-push檢查腳本
│   └── install-hooks.sh       # 安裝hooks的腳本
├── .ai-prompts/               # AI prompts管理
│   ├── code-review.md         # 代碼審查模板
│   ├── testing.md             # 測試相關模板
│   └── documentation.md       # 文檔生成模板
├── scripts/                   # 管理腳本（待完成）
│   ├── subtree-add.sh
│   ├── subtree-sync.sh
│   └── setup-project.sh
├── config/                    # 配置文件
│   └── pre-push-rules.yml     # Pre-push規則配置
├── templates/                 # 專案模板（待完成）
│   ├── python-lib/
│   └── web-app/
└── docs/                     # 使用文檔（待完成）
    ├── quick-start.md
    └── subtree-guide.md
```

### ✅ 3. 創建Git hooks管理系統
- **pre-push hook**: 智能檢測專案類型並執行相應的品質檢查
  - Python: flake8, black, pytest, mypy
  - JavaScript/TypeScript: ESLint, TypeScript編譯, Jest
  - 安全性檢查：敏感信息掃描，大文件檢測
- **install-hooks.sh**: 自動安裝hooks到專案中
- **pre-push-rules.yml**: 可配置的規則設定文件

### ✅ 4. 設計AI prompts管理系統
- **code-review.md**: 包含各種代碼審查模板
  - 安全性審查、性能優化、代碼品質
  - Python和JavaScript/TypeScript特定審查
  - 專案特定審查（報告生成器、GUI應用）
- **testing.md**: 測試相關AI prompts
  - 單元測試、集成測試、E2E測試
  - 測試數據生成、性能測試
  - 測試維護和調試
- **documentation.md**: 文檔生成模板
  - 代碼文檔、API文檔、用戶文檔
  - 技術文檔、專案文檔、維護文檔

## 待完成的工作

### ✅ 5. 創建Git subtree集成腳本
**已完成內容：**
- `subtree-add.sh`: 將template project加入到其他專案
- `subtree-sync.sh`: 同步template project更新
- `setup-project.sh`: 一鍵設置專案環境

**使用方式：**
```bash
# 添加到專案
./scripts/subtree-add.sh <target-project-path>

# 同步更新
./scripts/subtree-sync.sh pull <target-project-path>
./scripts/subtree-sync.sh push <target-project-path>

# 設置環境
./scripts/setup-project.sh
```

### ✅ 6. 編寫使用文檔和快速開始指南
**已完成內容：**
- `quick-start.md`: 詳細的快速開始指南
- `subtree-guide.md`: 完整的Git subtree使用指南
- `README.md`: 專案說明文檔

**文檔特色：**
- 完整的安裝和設置流程
- 詳細的使用範例
- AI prompts使用指南
- 故障排除和最佳實踐
- 多種使用場景說明

### ✅ 7. 創建自動化部署腳本
**已完成內容：**
- `version-manager.sh`: 版本管理腳本
- `update-all-projects.sh`: 批量更新腳本
- `batch-setup.sh`: 批量設置腳本

**功能特色：**
- 版本標籤管理
- 批量專案更新
- 並行處理支援
- 配置文件驅動

## 使用流程設計

### 初次設置
1. 將template_project作為subtree加入到目標專案
2. 執行`setup-project.sh`安裝hooks和配置
3. 根據專案類型調整`pre-push-rules.yml`

### Git Flow 日常使用
1. **功能開發**: 在 `feature/功能名` 分支開發
2. **整合開發**: 合併到 `develop` 分支
3. **準備發布**: 從 `develop` 創建單一 `release` 分支
4. **自動化檢查**: 推送 `release` 分支觸發自動化流程
5. **完成發布**: 合併回 `main` 和 `develop`，刪除 `release` 分支
6. **使用AI prompts**: 進行代碼審查和文檔生成
7. **定期同步**: template project更新

### 維護更新
1. 在template project中更新規則和模板
2. 使用`subtree-sync.sh`將更新推送到各個專案
3. 團隊成員獲得一致的最新標準

## 技術特點
- **非侵入性**: 不影響現有專案結構
- **可配置**: 支持不同專案的個性化需求
- **智能檢測**: 自動識別專案類型和技術棧
- **標準化**: 統一的代碼品質和協作標準

## 專案完成狀態
✅ **所有主要功能已完成**

### 核心組件
- ✅ Git hooks管理系統
- ✅ AI prompts管理系統 
- ✅ Git subtree集成腳本
- ✅ 使用文檔和指南
- ✅ 自動化部署腳本

### 可用功能
- ✅ 智能代碼品質檢查
- ✅ 結構化AI協作模板
- ✅ 跨專案工具同步
- ✅ 批量專案管理
- ✅ 版本控制和部署

## 新增功能：Python Release分支自動化

### ✅ Git Flow Release分支自動化
**已完成功能：**
- **標準Git Flow支援**: 僅使用單一 `release` 分支
- **智能分支檢測**: 自動識別標準Git Flow分支
- **版本一致性檢查**: Changelog與專案版本同步驗證
- **自動wheel構建**: 包含完整驗證流程
- 隔離環境測試
- GitHub自動發布和資產上傳

**技術實現：**
- `scripts/release/check-changelog.py`: 版本檢查
- `scripts/release/build-wheel.sh`: Wheel構建
- `scripts/release/test-release.sh`: 測試流程
- `scripts/release/github-release.sh`: GitHub發布
- `scripts/utils/version-utils.py`: 版本工具
- `scripts/utils/github-api.py`: GitHub API
- `config/release-config.yml`: 配置文件

**Git Flow使用流程：**
1. 從 `develop` 創建 `release` 分支
2. 更新版本號和CHANGELOG.md
3. 推送到 `release` 分支觸發自動化
4. 完成後合併回 `main` 和 `develop`
5. 刪除 `release` 分支，保留Git標籤追蹤版本

## 下一步行動
1. ✅ ~~完成Git subtree集成腳本~~
2. ✅ ~~編寫詳細的使用文檔~~
3. ✅ ~~實現Python Release分支自動化~~
4. **在測試專案中驗證完整流程**
5. 根據實際使用反饋進行調整
6. 推廣到所有專案中使用

## 注意事項
- 確保所有腳本兼容Windows環境
- 考慮不同開發者的環境差異
- 提供降級和回滾機制
- 定期更新和維護模板內容

---
*此計劃文檔將持續更新，記錄專案進展和變更*