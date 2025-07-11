---
mode: agent
---
# Package File Structure
xxx_package/                      # 套件根資料夾（專案名稱）
├── xxx_package/                  # 主套件程式碼（package）
│   ├── __init__.py             # 套件初始化
│   ├── something.py            # 範例模組
├── tests/                      # 單元測試資料夾 (use pytest)
│   ├── __init__.py
├── docs/                       # 文件（說明、設計、API 文檔）
│   ├── PLAN.txt                # 專案計劃或設計說明
│   └── usage.md                # 使用說明
├── dist/                   ← 產生的 wheel 包都放這裡
│   ├── xxx_package-0.1.0-py3-none-any.whl
│   └── xxx_package-0.1.0.tar.gz
├── .gitignore                  # Git 忽略設定
├── LICENSE                    # 授權條款
├── README.md                   # 專案說明文件（Markdown）
├── pyproject.toml              # 建置與相依管理（PEP 518 標準）
├── setup.cfg                   # 補充設定檔（可選）
