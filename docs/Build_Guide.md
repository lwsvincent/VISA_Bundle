# C# DLL 建置指南

## 環境要求

### Windows 環境（推薦）
- Windows 10/11
- .NET Framework 4.8 或更高版本
- .NET SDK 6.0 或更高版本
- Visual Studio 2019/2022（可選，但建議安裝）

### Linux/macOS 環境
- .NET SDK 6.0 或更高版本
- Mono（可選）
- 注意：pythonnet 在非 Windows 平台支援有限

## 建置步驟

### 方法 1：使用 Visual Studio（Windows，最簡單）

1. 開啟 Visual Studio
2. 檔案 → 開啟 → 專案/方案
3. 選擇 `src/VisaBundleCore/VisaBundleCore.csproj`
4. 選擇「Release」組態（或「Debug」用於除錯）
5. 建置 → 建置方案（或按 Ctrl+Shift+B）
6. 成功後，DLL 位於 `bin/Release/net48/VisaBundleCore.dll`

### 方法 2：使用 .NET CLI（跨平台）

```bash
# 1. 確認 .NET SDK 已安裝
dotnet --version

# 2. 進入專案目錄
cd src/VisaBundleCore

# 3. 還原依賴（如果有 NuGet 套件）
dotnet restore

# 4. 建置專案
dotnet build -c Release

# 5. 檢查輸出
ls ../../bin/Release/
```

### 方法 3：使用 MSBuild（Windows）

```cmd
# 1. 開啟「開發人員命令提示字元」（Developer Command Prompt）

# 2. 進入專案目錄
cd src\VisaBundleCore

# 3. 建置
msbuild VisaBundleCore.csproj /p:Configuration=Release

# 4. 檢查輸出
dir ..\..\bin\Release\
```

### 方法 4：使用 Python 建置腳本

```bash
# 從專案根目錄執行
python scripts/build_csharp.py
```

## 建置輸出

成功建置後，會在 `bin/Release/` 目錄產生：

```
bin/Release/net48/
├── VisaBundleCore.dll          # 主要 DLL（必須）
├── VisaBundleCore.xml          # XML 文檔（可選）
├── VisaBundleCore.pdb          # 除錯符號（Debug 組態）
└── VisaBundleCore.deps.json    # 依賴資訊（.NET Core/5+）
```

## 配置 VISA 依賴

### 選項 A：使用 NI-VISA（生產環境推薦）

1. 安裝 NI-VISA 驅動程式
   - 下載：https://www.ni.com/zh-tw/support/downloads/drivers/download.ni-visa.html
   - 安裝完整版本（包含 .NET 支援）

2. 找到 VISA .NET DLL 位置
   ```
   C:\Program Files (x86)\National Instruments\MeasurementStudioVS2010\DotNET\Assemblies\Current\
   或
   C:\Program Files\IVI Foundation\VISA\VisaDotNET\
   ```

3. 編輯 `VisaBundleCore.csproj`，新增參考：
   ```xml
   <ItemGroup>
     <Reference Include="NationalInstruments.Common">
       <HintPath>C:\Program Files (x86)\...\NationalInstruments.Common.dll</HintPath>
     </Reference>
     <Reference Include="NationalInstruments.NI4882">
       <HintPath>C:\Program Files (x86)\...\NationalInstruments.NI4882.dll</HintPath>
     </Reference>
   </ItemGroup>
   ```

4. 在 `VisaCore.cs` 中取消註釋實際 VISA 代碼
   - 搜尋 `=== VISA 驅動程式調用 ===`
   - 取消註釋對應區塊
   - 註釋掉模擬代碼

### 選項 B：使用 IVI.NET VISA（開源）

1. 新增 NuGet 套件
   ```bash
   cd src/VisaBundleCore
   dotnet add package Ivi.Visa
   ```

2. 修改 `VisaCore.cs`
   ```csharp
   using Ivi.Visa;

   // 在 Open() 方法中：
   var resourceManager = new ResourceManager();
   var session = resourceManager.Open(Address);
   _session = session;
   ```

### 選項 C：測試模式（無 VISA 驅動）

當前配置即為測試模式：
- 可以編譯成功
- 返回模擬資料
- 適合開發和 CI/CD

## 部署

### 部署到 Python 專案

1. 複製 DLL 到專案目錄
   ```bash
   cp bin/Release/net48/VisaBundleCore.dll ./bin/
   ```

2. 如果使用 NI-VISA，也需要複製依賴
   ```bash
   cp "C:\Program Files (x86)\...\NationalInstruments.*.dll" ./bin/
   ```

3. 在 Python 中載入
   ```python
   import clr
   clr.AddReference('bin/VisaBundleCore.dll')
   ```

### 部署到其他機器

最小部署包含：
- `VisaBundleCore.dll`
- VISA 驅動程式 DLL（如 `NationalInstruments.Common.dll`）
- .NET Framework 4.8 運行時（Windows 10/11 已內建）

## 驗證建置

### 檢查 DLL

```bash
# Windows
dir bin\Release\net48\VisaBundleCore.dll

# Linux/macOS
ls -lh bin/Release/net48/VisaBundleCore.dll
```

### 使用 .NET Reflector 檢查（可選）

1. 安裝工具（如 ILSpy、dnSpy、dotPeek）
2. 開啟 `VisaBundleCore.dll`
3. 驗證所有類別和方法都存在

### Python 測試

```python
import clr
import sys

# 載入 DLL
dll_path = r'bin\Release\net48\VisaBundleCore.dll'
clr.AddReference(dll_path)

# 匯入命名空間
from VisaBundle.Core import VisaCore, VisaSettingsCore

# 測試
print("VisaCore loaded:", VisaCore)
print("VisaSettingsCore loaded:", VisaSettingsCore)

# 測試靜態方法
resources = VisaCore.ListResources()
print("Available resources:", resources)
```

## 故障排除

### 問題 1：找不到 dotnet 命令

**解決方案：**
- 安裝 .NET SDK：https://dotnet.microsoft.com/download
- 或使用 Visual Studio 建置

### 問題 2：找不到 VISA 參考

**解決方案：**
- 安裝 NI-VISA 驅動程式
- 或使用測試模式（不需要 VISA）

### 問題 3：目標框架不支援

**錯誤：** `error NU1202: Package ... is not compatible with net48`

**解決方案：**
- 檢查 NuGet 套件是否支援 .NET Framework 4.8
- 或改用 .NET 6.0：編輯 .csproj，修改 `<TargetFramework>net6.0</TargetFramework>`

### 問題 4：Python 無法載入 DLL

**錯誤：** `System.IO.FileNotFoundException`

**解決方案：**
```python
import os
import clr

# 使用絕對路徑
dll_path = os.path.abspath('bin/Release/net48/VisaBundleCore.dll')
print(f"Loading DLL from: {dll_path}")
print(f"DLL exists: {os.path.exists(dll_path)}")

clr.AddReference(dll_path)
```

### 問題 5：版本衝突

**錯誤：** `Could not load file or assembly ... or one of its dependencies`

**解決方案：**
- 確保所有依賴 DLL 都在同一目錄
- 或添加到 GAC：`gacutil /i VisaBundleCore.dll`

## CI/CD 整合

### GitHub Actions 範例

```yaml
name: Build C# DLL

on: [push, pull_request]

jobs:
  build:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '6.0.x'

    - name: Restore dependencies
      run: dotnet restore src/VisaBundleCore/VisaBundleCore.csproj

    - name: Build
      run: dotnet build src/VisaBundleCore/VisaBundleCore.csproj -c Release --no-restore

    - name: Upload DLL
      uses: actions/upload-artifact@v3
      with:
        name: VisaBundleCore-dll
        path: bin/Release/net48/VisaBundleCore.dll
```

## 效能優化

### Release 組態設定

```xml
<PropertyGroup Condition="'$(Configuration)'=='Release'">
  <Optimize>true</Optimize>
  <DebugType>none</DebugType>
  <DebugSymbols>false</DebugSymbols>
</PropertyGroup>
```

### AOT 編譯（.NET 7+）

```xml
<PropertyGroup>
  <PublishAot>true</PublishAot>
</PropertyGroup>
```

## 下一步

建置完成後：
1. 測試 DLL 功能
2. 建立 Python wrapper 層
3. 執行整合測試
4. 更新文檔

## 參考資源

- .NET SDK 下載：https://dotnet.microsoft.com/download
- NI-VISA 驅動：https://www.ni.com/visa
- pythonnet 文檔：https://pythonnet.github.io/
- IVI Foundation：https://www.ivifoundation.org/
