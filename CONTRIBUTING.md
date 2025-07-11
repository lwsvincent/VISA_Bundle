# VISA Bundle Package Configuration

## 開發指南

### 本地開發安裝
```bash
# 克隆專案
git clone <repository-url>
cd VISA_Bundle

# 安裝開發依賴
pip install -r requirements-dev.txt

# 以開發模式安裝套件
pip install -e .
```

### 建置和測試
```bash
# 運行測試
pytest

# 程式碼格式化
black .

# 程式碼檢查
flake8 .

# 型別檢查
mypy .

# 建置套件
python build.py
# 或
build.bat   # Windows
```

### 發布流程
1. 更新版本號在 `pyproject.toml` 和 `__init__.py`
2. 更新 CHANGELOG
3. 運行測試確保一切正常
4. 建置套件: `python build.py`
5. 上傳到 PyPI: `python -m twine upload dist/*`

### 專案結構
```
VISA_Bundle/
├── src/                    # 原始碼目錄
│   └── visa_bundle/       # 主要套件
│       ├── __init__.py    # 套件初始化
│       ├── VISA.py        # 主要 VISA 類別
│       └── Setting.py     # 全域設定
├── tests/                 # 測試目錄
│   ├── __init__.py
│   └── test_visa_bundle.py
├── pyproject.toml         # 套件配置
├── README.md              # 專案說明
├── requirements.txt       # 相依套件
├── requirements-dev.txt   # 開發相依套件
├── LICENSE                # 授權文件
├── MANIFEST.in            # 套件包含檔案
├── setup.py              # 兼容性設定
├── build.py              # 建置腳本
├── build.bat             # Windows 建置腳本
├── install.py            # 安裝腳本
├── CHANGELOG.md          # 變更記錄
├── CONTRIBUTING.md       # 開發指南
└── .gitignore           # Git 忽略清單
```

### 版本控制
使用語意化版本 (Semantic Versioning):
- MAJOR.MINOR.PATCH
- MAJOR: 不相容的 API 變更
- MINOR: 向後相容的功能新增
- PATCH: 向後相容的問題修正
