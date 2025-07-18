# Template Project 快速開始指南

## 概述
Template Project 是一個統一的開發工具集，提供：
- 標準化的Git pre-push檢查
- AI協作提示模板
- 跨專案的一致性工具

## 開發環境準備

### 推薦：使用虛擬環境 (venv)

**強烈建議**使用 Python 虛擬環境來隔離專案依賴，確保測試環境一致：

```bash
# 創建虛擬環境
python -m venv .venv

# 啟用虛擬環境
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# 安裝專案依賴（根據專案類型）
# Python 專案：
pip install -e .[test]  # 開發模式 + 測試依賴
# 或基本安裝：
pip install -r requirements.txt

# 驗證環境
python --version
pip list
```

### venv 使用的好處
- 🔒 **依賴隔離**：避免與系統 Python 套件衝突
- 🔬 **一致測試環境**：確保 pre-push 檢查結果可重現
- 🚀 **符合自動化流程**：與 release 分支的自動化環境保持一致
- 👥 **團隊協作**：統一開發環境，減少環境差異問題

### 重要提醒
Template Project 的 pre-push hooks 和 release 自動化會自動：
- 檢測並啟用 `.venv` 虛擬環境（如果存在）
- 安裝必要的測試和建置依賴
- 在隔離環境中執行所有檢查

## 快速安裝

### 1. 添加到現有專案
```bash
# 在template_project目錄中執行
./scripts/subtree-add.sh <your-project-path>

# 例如：
./scripts/subtree-add.sh ../am_report_generator
```

### 2. 設置專案環境
```bash
# 進入目標專案的template_project目錄
cd <your-project>/template_project

# 執行設置腳本
./scripts/setup-project.sh
```

### 3. 驗證安裝
```bash
# 在你的專案目錄中測試
git add .
git commit -m "Test commit"
git push  # 這會觸發pre-push檢查
```

## Git Flow 工作流程

### Release 分支管理
Template Project 遵循標準 Git Flow，使用單一 `release` 分支：

```bash
# 1. 準備發布
git checkout develop
git checkout -b release

# 2. 在 release 分支更新版本
# - 編輯 setup.py, __init__.py, CHANGELOG.md

# 3. 推送觸發自動化檢查
git add .
git commit -m "Prepare release 1.0.3"
git push origin release

# 4. 自動化流程完成後，手動完成合併
git checkout main
git merge release
git tag -a v1.0.3 -m "Release 1.0.3"

git checkout develop
git merge release

# 5. 清理：刪除 release 分支
git branch -d release
git push origin main develop v1.0.3
```

### 版本追蹤
- **分支生命週期**：Release 分支在發布完成後會被刪除
- **版本記錄**：透過 Git Tags (如 `v1.0.3`) 永久標記每個版本  
- **歷史查詢**：使用 `git tag --list` 和 `git log --oneline --decorate` 查看版本歷史

## 基本使用

### Pre-push檢查
設置完成後，每次`git push`都會自動執行：
- 代碼格式檢查（Python: black, flake8；JavaScript: ESLint）
- 測試執行（pytest, Jest）
- 安全性掃描（敏感信息檢測）
- 文件大小檢查

### AI提示模板
在`template_project/.ai-prompts/`目錄中找到：

#### 代碼審查（code-review.md）
```markdown
請審查以下代碼的安全性問題：

代碼片段：
[YOUR_CODE_HERE]

重點檢查：
1. 是否存在潛在的安全漏洞
2. 敏感信息是否有洩露風險
...
```

#### 測試生成（testing.md）
```markdown
請為以下代碼生成完整的單元測試：

代碼片段：
[YOUR_CODE_HERE]

測試要求：
1. 覆蓋所有主要功能路徑
2. 包含邊界條件測試
...
```

#### 文檔生成（documentation.md）
```markdown
請為以下函數/方法生成詳細的文檔：

代碼片段：
[YOUR_CODE_HERE]

文檔要求：
1. 清晰的功能描述
2. 參數說明
...
```

### 配置自定義
編輯`template_project/config/pre-push-rules.yml`來自定義檢查規則：

```yaml
# 基本設置
settings:
  fail_fast: true
  verbose: true
  timeout: 300

# Python專案配置
python:
  enabled: true
  checks:
    - name: "flake8"
      command: "flake8"
      args: ". --exclude=build,dist,.git --max-line-length=100"
      required: true
```

## 常見使用場景

### 1. 代碼審查
使用AI提示模板進行代碼審查：
1. 複製`template_project/.ai-prompts/code-review.md`中的相關模板
2. 將`[YOUR_CODE_HERE]`替換為實際代碼
3. 發送給AI助手進行審查

### 2. 測試生成
1. 選擇適當的測試模板
2. 提供代碼片段和測試要求
3. 獲得完整的測試代碼

### 3. 文檔生成
1. 使用文檔模板生成API文檔
2. 創建用戶指南
3. 生成技術文檔

## 同步更新

### 獲取最新模板
```bash
# 在專案根目錄執行
./template_project/scripts/subtree-sync.sh pull .
```

### 推送改進到模板
```bash
# 將本地修改推送回模板專案
./template_project/scripts/subtree-sync.sh push .
```

## 故障排除

### 常見問題

#### 1. Pre-push檢查失敗
```bash
# 檢查具體錯誤
git push  # 查看詳細錯誤信息

# 跳過檢查（不推薦）
git push --no-verify
```

#### 2. 工具未找到
```bash
# Python環境
pip install flake8 black pytest

# JavaScript環境
npm install eslint prettier jest
```

#### 3. 權限問題
```bash
# 確保腳本可執行
chmod +x template_project/scripts/*.sh
chmod +x template_project/.git-hooks/*
```

#### 4. Git hooks未安裝
```bash
# 重新安裝hooks
cd template_project
./scripts/setup-project.sh
```

### 調試模式
編輯`template_project/config/pre-push-rules.yml`：
```yaml
settings:
  fail_fast: false  # 不要在第一個錯誤時停止
  verbose: true     # 顯示詳細輸出
```

## 項目特定配置

### Python專案
```yaml
python:
  enabled: true
  checks:
    - name: "mypy"
      command: "mypy"
      args: "."
      required: false
      condition: "file_exists:mypy.ini"
```

### JavaScript/TypeScript專案
```yaml
javascript:
  enabled: true
  checks:
    - name: "prettier"
      command: "npx prettier"
      args: "--check ."
      required: false
```

### 混合專案
兩個配置區塊都可以啟用：
```yaml
python:
  enabled: true
javascript:
  enabled: true
```

## 最佳實踐

### 1. 團隊協作
- 所有團隊成員使用相同的template project版本
- 定期同步模板更新
- 統一的代碼風格和質量標準

### 2. 持續集成
- 在CI/CD流程中使用相同的檢查標準
- 本地檢查與遠程檢查保持一致

### 3. 自定義開發
- 根據專案需求調整檢查規則
- 添加專案特定的AI提示模板
- 貢獻改進回模板專案

### 4. 性能優化
- 合理設置timeout值
- 使用適當的exclude規則
- 定期清理不必要的檢查

## 進階功能

### 自定義檢查
在`pre-push-rules.yml`中添加：
```yaml
custom_checks:
  - name: "custom_lint"
    command: "your-custom-tool"
    args: "."
    required: true
```

### 環境特定配置
```yaml
environments:
  development:
    python:
      checks:
        - name: "pytest"
          args: "--tb=short -v"
  production:
    python:
      checks:
        - name: "pytest"
          args: "--tb=line"
```

## 獲得幫助

### 文檔資源
- `PROJECT_PLAN.md`: 完整的專案計劃
- `subtree-guide.md`: Git subtree詳細指南
- `.ai-prompts/`: AI協作模板

### 常見命令參考
```bash
# 設置新專案
./scripts/subtree-add.sh <project-path>
./scripts/setup-project.sh

# 同步更新
./scripts/subtree-sync.sh pull <project-path>
./scripts/subtree-sync.sh push <project-path>

# 重新安裝hooks
./.git-hooks/install-hooks.sh
```

### 支援
如果遇到問題，請檢查：
1. 腳本執行權限
2. Git倉庫狀態
3. 依賴工具安裝
4. 配置文件語法

---

*此文檔會持續更新，請定期同步最新版本*