# VISA Bundle - Python Package

[![PyPI version](https://badge.fury.io/py/visa-bundle.svg)](https://badge.fury.io/py/visa-bundle)
[![Python Versions](https://img.shields.io/pypi/pyversions/visa-bundle.svg)](https://pypi.org/project/visa-bundle/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一個高效的 Python VISA 儀器控制包，為測試設備通訊提供增強的管理功能。

## 特色功能

- 🚀 **統一管理**: 封裝 pyvisa 為易用的類別介面
- 🔌 **連線管理**: 自動管理 VISA 連線，避免重複開啟
- 🎛️ **全域設定**: 統一控制通訊啟用/除錯列印等功能
- 📊 **錯誤處理**: 完善的錯誤回報和自動重連機制
- 🔧 **測試友善**: 支援測試模式，可模擬儀器回應

## 快速開始

### 安裝

```bash
pip install visa-bundle
```

### 基本使用

```python
from visa_bundle import VISA, VISAManager, Setting

# 方法 1: 直接使用 VISA 類別
# 建立 VISA 物件
visa = VISA("my_instrument", "USB0::0x1234::0x5678::INSTR")

# 啟用除錯輸出
Setting.VISA_Print_Enable = True

# 傳送指令並讀取回應
response = visa.query('*IDN?')
print(f"儀器識別: {response}")

# 寫入指令
visa.write("*RST")

# 讀取資料
data = visa.read()

# 關閉儀器
visa.close()

# 方法 2: 使用 VISAManager 管理多個儀器
manager = VISAManager()

# 探索可用儀器
available = manager.discover_instruments()
print(f"可用儀器: {available}")

# 添加儀器
dmm = manager.add_instrument("dmm", "USB0::0x1234::0x5678::INSTR")
scope = manager.add_instrument("scope", "TCPIP::192.168.1.100::INSTR")

# 使用儀器
dmm_id = dmm.query("*IDN?")
scope_id = scope.query("*IDN?")

# 關閉所有連線
manager.close_all()
```

## 詳細文件

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

### 模組說明

VISA Bundle 提供儀器驅動程式的 VISA 介面包裝，整合 pyvisa 與自訂設定，方便進行儀器通訊與管理。

### 主要匯出

- `VISA`: 主要 VISA 控制類別，使用 snake_case 方法名稱
- `VISAManager`: 多儀器管理器，提供高階介面
- `opened_connections`: 已開啟的 VISA 連線列表（新格式）
- `Opened_List`: 已開啟的 VISA 連線列表（向後相容別名）
- `Setting`: 全域設定模組

### 新版 API 方法名稱

VISA 類別現在使用符合 PEP 8 的方法名稱：

- `open()` - 開啟 VISA 連線
- `close()` - 關閉 VISA 連線  
- `query(command, delay_time=None)` - 查詢指令
- `write(command)` - 寫入指令
- `read(count=None)` - 讀取資料
- `read_binary()` - 讀取二進位資料
- `write_binary(command)` - 寫入二進位資料
- `query_binary(command, delay_time=0.1)` - 查詢二進位資料

靜態方法：
- `VISA.list_resources()` - 列出可用資源
- `VISA.get_opened_connections()` - 取得已開啟連線
- `VISA.close_all_connections()` - 關閉所有連線

### 全域設定選項

```python
# 是否實際發送 VISA 指令（測試模式時可設為 False）
Setting.VISA_Send_Enable = True

# 是否列印 VISA 指令和回應（除錯用）
Setting.VISA_Print_Enable = True

# 除錯模式
Setting.ITEM_DEBUG = False

# 伺服器模式
Setting.IS_SERVER = False

# 中斷模式
Setting.IS_INTERRUPT = False
```

### 進階功能

#### 連線管理
系統會自動追蹤已開啟的 VISA 連線，避免重複開啟相同位址的儀器：

```python
# 第一次開啟
inst1 = visa.open_resource('USB0::0x1234::0x5678::INSTR')

# 第二次開啟相同位址會回傳已存在的連線
inst2 = visa.open_resource('USB0::0x1234::0x5678::INSTR')

# inst1 和 inst2 實際上是同一個連線物件
```

#### 錯誤處理
當通訊失敗時，系統會自動嘗試重新連線：

```python
try:
    response = inst.query('*IDN?')
except Exception as e:
    print(f"通訊錯誤，將嘗試重新連線: {e}")
    # 系統會自動處理重連
```

## 開發

### 安裝開發環境

```bash
git clone https://github.com/dsplatform/visa-bundle.git
cd visa-bundle
pip install -r requirements-dev.txt
```

### 執行測試

```bash
pytest
```

### 程式碼格式化

```bash
black .
flake8 .
```

### 建置套件

```bash
python -m build
```

## 相依性

- Python >= 3.8
- pyvisa >= 1.11.0

## 授權

本專案採用 MIT 授權 - 詳見 [LICENSE](LICENSE) 檔案。

## 貢獻

歡迎提交 Issue 和 Pull Request！

## 變更記錄

### v0.1.0
- 初始版本
- 基本 VISA 封裝功能
- 連線管理系統
- 全域設定支援

---

## 其他
- `__all__` 只匯出 VISA、Opened_List、Setting。
- 適用於自動化儀器控制、測試平台等場景。
