# 開發最佳實踐指南

## 虛擬環境管理

### 為什麼使用 venv？

Template Project **強烈建議**所有專案使用 Python 虛擬環境，這是現代 Python 開發的標準做法：

#### 核心優勢
- 🔒 **依賴隔離**: 每個專案獨立的 Python 環境
- 🔬 **一致性**: 開發、測試、生產環境保持一致
- 🚀 **自動化友好**: 與 CI/CD 流程完美整合
- 👥 **團隊協作**: 確保所有開發者環境統一
- 🐛 **問題排查**: 更容易診斷依賴相關問題

### 標準 venv 工作流程

#### 1. 專案初始化
```bash
# 克隆或創建專案
git clone <project-url>
cd <project-name>

# 創建虛擬環境
python -m venv .venv

# 啟用虛擬環境
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# 驗證環境
which python  # 應該指向 .venv 目錄
python --version
```

#### 2. 依賴安裝
```bash
# 基本安裝
pip install -r requirements.txt

# 開發模式安裝（推薦）
pip install -e .

# 包含測試依賴
pip install -e .[test]

# 驗證安裝
pip list
pip check  # 檢查依賴衝突
```

#### 3. 日常開發
```bash
# 每次開發前啟用環境
source .venv/bin/activate  # Linux/Mac
# 或
.venv\Scripts\activate  # Windows

# 開發工作...
python your_script.py
pytest tests/
git commit -m "Your changes"

# 推送前檢查（自動使用 venv）
git push  # Template Project 會自動檢測 .venv
```

### Template Project 中的 venv 整合

#### 自動檢測機制
Template Project 的工具會自動：

1. **檢測 `.venv` 目錄**
   ```bash
   if [ -d ".venv" ]; then
       echo "發現虛擬環境，啟用中..."
       source .venv/bin/activate
   fi
   ```

2. **pre-push hooks 整合**
   - 自動啟用虛擬環境
   - 安裝必要的檢查工具
   - 在隔離環境中執行測試

3. **release 自動化**
   - 創建乾淨的建置環境
   - 安裝精確的依賴版本
   - 確保建置可重現性

#### 配置範例
在 `template_project/config/pre-push-rules.yml` 中：

```yaml
settings:
  # 自動啟用虛擬環境
  use_venv: true
  venv_path: ".venv"
  
  # 如果沒有 venv，是否繼續
  require_venv: false
  
python:
  enabled: true
  venv_setup:
    # 自動安裝測試依賴
    install_test_deps: true
    # 升級 pip
    upgrade_pip: true
```

### 多專案環境管理

#### 1. 專案隔離策略
```bash
# 專案結構
workspace/
├── project_a/
│   ├── .venv/          # project_a 專用環境
│   ├── requirements.txt
│   └── src/
├── project_b/
│   ├── .venv/          # project_b 專用環境
│   ├── requirements.txt
│   └── src/
└── template_project/   # 共享工具，無需 venv
```

#### 2. 環境切換
```bash
# 切換到專案 A
cd project_a
source .venv/bin/activate
python --version  # 專案 A 的 Python 版本

# 切換到專案 B  
deactivate  # 先退出當前環境
cd ../project_b
source .venv/bin/activate
python --version  # 專案 B 的 Python 版本
```

### 常見問題與解決方案

#### 1. venv 創建失敗
```bash
# 檢查 Python 版本
python --version
python -m venv --help

# 如果系統 Python 有問題，使用特定版本
python3.8 -m venv .venv
python3.9 -m venv .venv
```

#### 2. 依賴安裝失敗
```bash
# 升級 pip
python -m pip install --upgrade pip

# 使用國內鏡像（如果網路問題）
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple package_name

# 清除快取重試
pip cache purge
pip install -r requirements.txt
```

#### 3. 虛擬環境損壞
```bash
# 刪除重建
rm -rf .venv
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

#### 4. IDE 整合問題
```bash
# VSCode: 確保選擇正確的 Python 解釋器
# Ctrl+Shift+P -> "Python: Select Interpreter"
# 選擇 .venv/bin/python

# PyCharm: Project Settings -> Project Interpreter
# 設置為 .venv/bin/python
```

### 進階技巧

#### 1. 環境變數管理
```bash
# 創建 .env 檔案
echo "DEBUG=True" > .env
echo "DATABASE_URL=sqlite:///dev.db" >> .env

# 使用 python-dotenv
pip install python-dotenv
```

#### 2. 依賴管理
```bash
# 凍結當前環境依賴
pip freeze > requirements.txt

# 生產環境依賴（排除開發工具）
pip freeze | grep -v pytest > requirements-prod.txt

# 開發依賴
pip freeze | grep -E "(pytest|black|flake8)" > requirements-dev.txt
```

#### 3. 多 Python 版本測試
```bash
# 使用 tox
pip install tox
tox  # 測試多個 Python 版本

# 或使用 pyenv + venv
pyenv install 3.8.10
pyenv install 3.9.7
pyenv local 3.8.10
python -m venv .venv38
```

### CI/CD 整合

#### GitHub Actions 範例
```yaml
name: Test with venv
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: 3.9
    
    - name: Create virtual environment
      run: python -m venv .venv
    
    - name: Activate venv and install deps
      run: |
        source .venv/bin/activate
        pip install -e .[test]
    
    - name: Run tests
      run: |
        source .venv/bin/activate
        pytest
```

### 團隊協作規範

#### 1. .gitignore 設定
```gitignore
# 虛擬環境（不要提交）
.venv/
venv/
env/

# 但要提交依賴清單
requirements.txt
requirements-dev.txt
pyproject.toml
```

#### 2. 團隊約定
- ✅ 所有成員都使用 `.venv` 作為虛擬環境目錄名
- ✅ 提交前更新 `requirements.txt`
- ✅ 新成員必讀此文檔
- ✅ 統一 Python 版本（如 3.9+）

#### 3. 專案 README 模板
```markdown
## 開發環境設置

1. 創建虛擬環境：`python -m venv .venv`
2. 啟用環境：`source .venv/bin/activate` (Linux/Mac) 或 `.venv\Scripts\activate` (Windows)
3. 安裝依賴：`pip install -e .[test]`
4. 運行測試：`pytest`
```

### 性能優化

#### 1. 快速環境重建
```bash
# 使用 pip-tools 管理依賴
pip install pip-tools

# 生成鎖定文件
pip-compile requirements.in
pip-sync requirements.txt  # 快速同步
```

#### 2. 減少安裝時間
```bash
# 使用本地快取
pip install --cache-dir ~/.pip/cache

# 批量安裝
pip install -r requirements.txt --no-deps --disable-pip-version-check
```

### 監控與維護

#### 1. 依賴安全掃描
```bash
# 安全漏洞檢查
pip install safety
safety check

# 或使用 GitHub Dependabot
# 在 .github/dependabot.yml 配置
```

#### 2. 依賴更新
```bash
# 檢查過期套件
pip list --outdated

# 批量更新（謹慎使用）
pip install --upgrade -r requirements.txt
```

---

## 總結

使用虛擬環境是現代 Python 開發的基礎實踐。Template Project 的所有工具都針對 venv 環境進行了優化，遵循本指南能確保：

- 🏗️ **穩定的開發環境**
- 🔄 **一致的 CI/CD 流程**
- 🤝 **順暢的團隊協作**
- 🐛 **快速的問題診斷**

**記住**：好的開發環境是高質量代碼的基礎！