# VisaBundleCore - C# DLL 核心庫

## 概述

VisaBundleCore 是 VISA Bundle 專案的 C# 核心實現，提供高性能的 VISA 儀器通信功能。
Python 層作為 wrapper 調用此 DLL，保持原有 API 的向後兼容性。

## 架構

```
Python API (visa_bundle)
    ↓ (pythonnet)
C# DLL (VisaBundleCore.dll)
    ↓ (VISA .NET API)
VISA 驅動程式 (NI-VISA / IVI-VISA)
```

## 核心類別

### 1. VisaCore
- 對應 Python 的 `VISA` 類別
- 提供 Open/Close/Query/Write/Read 功能
- 支援文字和二進位 I/O
- 內建連線池和重試邏輯

### 2. VISAManagerCore
- 對應 Python 的 `VISAManager` 類別
- 管理多個 VISA 儀器實例

### 3. VisaSettingsCore
- 對應 Python 的 `Setting` 模組
- 全域配置管理

### 4. ConnectionRegistry
- 內部連線池管理
- 防止重複連線
- 執行緒安全

## 建置環境要求

### 必要條件
- .NET Framework 4.8 或更高版本
- Windows 作業系統（Linux/macOS 需使用 .NET 6+ 並調整 VISA 庫）

### 可選條件
- Visual Studio 2019/2022（或 VS Code + C# 擴充）
- .NET SDK（如果使用命令列建置）

## VISA 驅動程式配置

### 方案 1：使用 NI-VISA（推薦）

1. **安裝 NI-VISA 驅動程式**
   - 下載：https://www.ni.com/zh-tw/support/downloads/drivers/download.ni-visa.html
   - 安裝完成後，VISA .NET 組件位於：
     `C:\Program Files\IVI Foundation\VISA\VisaDotNET\`

2. **引用 VISA 組件**

   編輯 `VisaBundleCore.csproj`，新增：
   ```xml
   <ItemGroup>
     <Reference Include="NationalInstruments.Common">
       <HintPath>C:\Program Files (x86)\National Instruments\MeasurementStudioVS2010\DotNET\Assemblies\Current\NationalInstruments.Common.dll</HintPath>
     </Reference>
     <Reference Include="NationalInstruments.NI4882">
       <HintPath>C:\Program Files (x86)\National Instruments\MeasurementStudioVS2010\DotNET\Assemblies\Current\NationalInstruments.NI4882.dll</HintPath>
     </Reference>
   </ItemGroup>
   ```

   或使用 NuGet（如果可用）：
   ```bash
   dotnet add package NationalInstruments.Visa
   ```

3. **取消註釋 VisaCore.cs 中的實際代碼**

   搜尋 `=== VISA 驅動程式調用 ===` 並取消相關代碼的註釋。

### 方案 2：使用 IVI.NET VISA（開源）

1. **安裝 IVI.NET 組件**
   ```bash
   dotnet add package Ivi.Visa
   ```

2. **修改 VisaCore.cs**

   將 VISA API 調用改為使用 `Ivi.Visa` 命名空間：
   ```csharp
   using Ivi.Visa;
   var resourceManager = new ResourceManager();
   var session = resourceManager.Open(Address);
   ```

### 方案 3：測試模式（無需 VISA 驅動）

當前代碼已配置為測試模式，可以：
- 編譯成功（不需要 VISA 驅動程式）
- 返回模擬資料
- 適用於開發和測試

要啟用測試模式：
```csharp
VisaSettingsCore.SendEnabled = false;  // 不執行實際 VISA 操作
VisaSettingsCore.PrintEnabled = true;  // 列印除錯訊息
```

## 建置步驟

### 使用 Visual Studio
1. 開啟 `VisaBundleCore.csproj`
2. 選擇 Release 組態
3. 建置 → 建置方案
4. 輸出位於 `bin/Release/`

### 使用命令列（.NET CLI）

```bash
# 進入專案目錄
cd src/VisaBundleCore

# 建置 Release 版本
dotnet build -c Release

# 輸出位於 ../../bin/Release/
```

### 使用建置腳本

```bash
# 從專案根目錄執行
python scripts/build_csharp.py
```

## 輸出檔案

建置成功後會產生：
- `VisaBundleCore.dll` - 主要 DLL
- `VisaBundleCore.xml` - XML 文檔檔案
- `VisaBundleCore.pdb` - 除錯符號檔案（Debug 組態）

## Python 整合

### 安裝 pythonnet

```bash
pip install pythonnet
```

### 使用範例

```python
import clr
from pathlib import Path

# 載入 DLL
dll_path = Path("bin/Release/VisaBundleCore.dll")
clr.AddReference(str(dll_path))

# 匯入 C# 類別
from VisaBundle.Core import VisaCore, VisaSettingsCore

# 啟用測試模式
VisaSettingsCore.SendEnabled = True
VisaSettingsCore.PrintEnabled = True

# 使用 VISA
visa = VisaCore("DMM", "GPIB0::1::INSTR")
result = visa.Query("*IDN?")
print(result)
visa.Close()
```

## 除錯

### 啟用除錯模式

```csharp
VisaSettingsCore.DebugMode = true;
VisaSettingsCore.PrintEnabled = true;
```

### 從 Python 除錯 C# 代碼

1. 在 Visual Studio 中開啟專案
2. 設定斷點
3. 偵錯 → 附加至處理序
4. 選擇 `python.exe` 處理序
5. 執行 Python 腳本，觸發斷點

## 常見問題

### Q1: 編譯錯誤「找不到 IMessageBasedSession」
A: 需要安裝並引用 VISA .NET 組件。請參考上方「VISA 驅動程式配置」。

### Q2: Python 無法載入 DLL
A: 檢查：
- DLL 路徑是否正確
- 是否安裝 pythonnet
- .NET Framework 版本是否符合
- DLL 是否為 AnyCPU 或符合 Python 架構（x86/x64）

### Q3: 執行時錯誤「Session not opened」
A: 確保 `VisaSettingsCore.SendEnabled = true`

### Q4: 找不到 VISA 資源
A: 確保：
- VISA 驅動程式已安裝
- 儀器已連接並開機
- 使用 NI MAX 或 Keysight Connection Expert 驗證連線

## 授權

MIT License - 與主專案相同

## 版本歷史

- **v1.0.0** (2025-01) - 初始版本
  - 完整的 VISA 功能
  - Python API 兼容層
  - 連線池和重試邏輯
