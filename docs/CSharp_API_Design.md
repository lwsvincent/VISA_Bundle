# C# DLL API 設計規格

## 概述

本文檔定義從 Python VISA Bundle 遷移到 C# DLL 的完整 API 規格。
C# DLL 將提供核心功能，Python 層作為 wrapper 保持向後兼容。

---

## 命名空間結構

```
VisaBundle.Core
├── VisaCore                    # 核心 VISA 類別
├── VisaManagerCore             # 多儀器管理類別
├── VisaSettingsCore            # 全域設定（靜態類別）
└── ConnectionRegistry          # 連線池管理（靜態類別）
```

---

## 1. VisaCore 類別

### 用途
儀器通信的核心類別，對應 Python 的 `VISA` 類別。

### 類別簽章
```csharp
namespace VisaBundle.Core
{
    public class VisaCore : IDisposable
    {
        // 建構函式
        public VisaCore(string name, string address);

        // 實例屬性
        public string Name { get; }
        public string Address { get; }
        public bool IsOpen { get; }

        // 連線管理
        public void Open();
        public void Close();

        // 文字 I/O
        public string Query(string command, double? delayTime = null);
        public void Write(string command);
        public string Read(int? count = null);

        // 二進位 I/O
        public byte[] ReadBinary();
        public void WriteBinary(byte[] data);
        public byte[] QueryBinary(string command, double delayTime = 0.1);

        // 靜態工具方法
        public static string[] ListResources();
        public static string GetOpenedConnectionsJson();
        public static void CloseAllConnections();

        // IDisposable
        public void Dispose();
    }
}
```

### 方法詳細規格

#### 建構函式
```csharp
/// <summary>
/// 初始化 VISA 儀器實例並自動開啟連線
/// </summary>
/// <param name="name">儀器識別名稱，用於日誌和除錯</param>
/// <param name="address">VISA 資源地址，例如 'GPIB0::1::INSTR'</param>
/// <exception cref="ArgumentNullException">當 name 或 address 為 null</exception>
/// <exception cref="VisaException">當無法開啟連線</exception>
public VisaCore(string name, string address)
{
    if (string.IsNullOrWhiteSpace(name))
        throw new ArgumentNullException(nameof(name));
    if (string.IsNullOrWhiteSpace(address))
        throw new ArgumentNullException(nameof(address));

    Name = name;
    Address = address;
    IsOpen = false;

    // 自動開啟連線（對應 Python 行為）
    Open();
}
```

#### Open() - 開啟連線
```csharp
/// <summary>
/// 開啟 VISA 連線，支援連線池和重試邏輯
/// </summary>
/// <remarks>
/// - 檢查連線池，避免重複連線
/// - 失敗時自動重試 2 次
/// - 成功後註冊到全域連線池
/// </remarks>
/// <exception cref="VisaException">連線失敗</exception>
public void Open()
{
    // 除錯輸出
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"Open VISA: {Name}");

    // 測試模式跳過
    if (!VisaSettingsCore.SendEnabled)
        return;

    // 檢查連線池
    var existingHandle = ConnectionRegistry.GetConnection(Address);
    if (existingHandle != null)
    {
        _session = existingHandle;
        IsOpen = true;
        return;
    }

    // 重試邏輯：最多 2 次
    const int maxRetries = 2;
    Exception lastException = null;

    for (int attempt = 0; attempt < maxRetries; attempt++)
    {
        try
        {
            var resourceManager = new ResourceManager();
            _session = (IMessageBasedSession)resourceManager.Open(Address);

            // 清除儀器狀態
            if (_session != null)
            {
                _session.Clear();
                Thread.Sleep(500);  // 等待 0.5 秒
                IsOpen = true;

                // 註冊到連線池
                ConnectionRegistry.RegisterConnection(Address, _session);
                return;
            }
        }
        catch (Exception ex)
        {
            lastException = ex;
            Thread.Sleep(1000);  // 等待 1 秒後重試
        }
    }

    // 所有重試都失敗
    throw new VisaException(
        $"VISA Open Error: {Name}, address: {Address}",
        lastException);
}
```

#### Close() - 關閉連線
```csharp
/// <summary>
/// 關閉 VISA 連線並從連線池移除
/// </summary>
public void Close()
{
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"Close VISA: {Name}");

    if (!VisaSettingsCore.SendEnabled || _session == null)
        return;

    try
    {
        _session.Dispose();
        ConnectionRegistry.UnregisterConnection(Address);
        IsOpen = false;
        _session = null;
    }
    catch (Exception)
    {
        // 忽略關閉錯誤
    }
}
```

#### Query() - 查詢
```csharp
/// <summary>
/// 發送命令並讀取回應
/// </summary>
/// <param name="command">SCPI 命令字串</param>
/// <param name="delayTime">讀取前延遲時間（秒），null 表示無延遲</param>
/// <returns>儀器回應字串</returns>
/// <exception cref="VisaException">通信錯誤</exception>
public string Query(string command, double? delayTime = null)
{
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"[{Name}] Query: {command}");

    if (!VisaSettingsCore.SendEnabled)
        return "0";

    if (_session == null)
        throw new VisaException("not MessageBasedResource");

    try
    {
        string response;
        if (delayTime.HasValue)
        {
            _session.FormattedIO.WriteLine(command);
            Thread.Sleep((int)(delayTime.Value * 1000));
            response = _session.FormattedIO.ReadLine();
        }
        else
        {
            response = _session.FormattedIO.Query(command);
        }

        if (VisaSettingsCore.PrintEnabled)
            Console.WriteLine($"[{Name}] Recv: {response}");

        return response;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"VISA Query Error: {Name}");
        Console.WriteLine($"Address: {Address}");
        Console.WriteLine($"Command: {command}");
        throw new VisaException("VISA Query Error", ex);
    }
}
```

#### Write() - 寫入
```csharp
/// <summary>
/// 發送命令到儀器
/// </summary>
/// <param name="command">SCPI 命令字串</param>
/// <exception cref="VisaException">通信錯誤</exception>
public void Write(string command)
{
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"[{Name}] Write: {command}");

    if (!VisaSettingsCore.SendEnabled)
        return;

    if (_session == null)
        throw new VisaException("not MessageBasedResource");

    try
    {
        _session.FormattedIO.WriteLine(command);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"VISA Write Error: {Name}");
        Console.WriteLine($"Address: {Address}");
        Console.WriteLine($"Command: {command}");
        throw new VisaException("VISA Write Error", ex);
    }
}
```

#### Read() - 讀取
```csharp
/// <summary>
/// 從儀器讀取資料
/// </summary>
/// <param name="count">讀取位元組數，null 表示讀取到終止符</param>
/// <returns>回應字串</returns>
/// <exception cref="VisaException">通信錯誤</exception>
public string Read(int? count = null)
{
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"[{Name}] Read");

    if (!VisaSettingsCore.SendEnabled)
        return "0";

    if (_session == null)
        throw new VisaException("not MessageBasedResource");

    try
    {
        string response;
        if (count.HasValue)
        {
            // 讀取指定位元組數並解碼為 UTF-8
            byte[] buffer = new byte[count.Value];
            _session.RawIO.Read(buffer);
            response = Encoding.UTF8.GetString(buffer);
        }
        else
        {
            response = _session.FormattedIO.ReadLine();
        }

        if (VisaSettingsCore.PrintEnabled)
            Console.WriteLine(response);

        return response;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"VISA Read Error: {Name}");
        throw new VisaException("VISA Read Error", ex);
    }
}
```

#### ReadBinary() - 讀取二進位
```csharp
/// <summary>
/// 從儀器讀取二進位資料
/// </summary>
/// <returns>二進位回應資料</returns>
/// <exception cref="VisaException">通信錯誤</exception>
public byte[] ReadBinary()
{
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"[{Name}] Read Binary");

    if (!VisaSettingsCore.SendEnabled)
        return new byte[0];

    if (_session == null)
        throw new VisaException("not MessageBasedResource");

    try
    {
        return _session.RawIO.Read();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"VISA Read Binary Error: {Name}");
        throw new VisaException("VISA Read Binary Error", ex);
    }
}
```

#### WriteBinary() - 寫入二進位
```csharp
/// <summary>
/// 發送二進位資料到儀器
/// </summary>
/// <param name="data">二進位命令資料</param>
/// <exception cref="VisaException">通信錯誤</exception>
public void WriteBinary(byte[] data)
{
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"[{Name}] Write Binary (length: {data?.Length ?? 0})");

    if (!VisaSettingsCore.SendEnabled)
        return;

    if (_session == null)
        throw new VisaException("not MessageBasedResource");

    try
    {
        _session.RawIO.Write(data);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"VISA Write Binary Error: {Name}");
        throw new VisaException("VISA Write Binary Error", ex);
    }
}
```

#### QueryBinary() - 查詢二進位
```csharp
/// <summary>
/// 發送文字命令並讀取二進位回應
/// </summary>
/// <param name="command">文字命令</param>
/// <param name="delayTime">延遲時間（秒）</param>
/// <returns>二進位回應資料</returns>
/// <exception cref="VisaException">通信錯誤</exception>
public byte[] QueryBinary(string command, double delayTime = 0.1)
{
    if (VisaSettingsCore.PrintEnabled)
        Console.WriteLine($"[{Name}] Query Binary: {command}");

    if (!VisaSettingsCore.SendEnabled)
        return Encoding.UTF8.GetBytes("0");

    if (_session == null)
        throw new VisaException("not MessageBasedResource");

    try
    {
        Write(command);
        Thread.Sleep((int)(delayTime * 1000));
        byte[] response = ReadBinary();

        if (VisaSettingsCore.PrintEnabled)
            Console.WriteLine($"[{Name}] Recv: {response.Length} bytes");

        return response;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"VISA Query Binary Error: {Name}");
        throw new VisaException("VISA Query Binary Error", ex);
    }
}
```

#### ListResources() - 列出資源
```csharp
/// <summary>
/// 列出所有可用的 VISA 資源
/// </summary>
/// <returns>VISA 資源地址陣列</returns>
public static string[] ListResources()
{
    try
    {
        var resourceManager = new ResourceManager();
        return resourceManager.Find("?*").ToArray();
    }
    catch (Exception)
    {
        return new string[0];
    }
}
```

#### GetOpenedConnectionsJson() - 取得已開啟連線（JSON 格式）
```csharp
/// <summary>
/// 取得所有已開啟連線的資訊（JSON 格式）
/// </summary>
/// <returns>JSON 格式的連線資訊</returns>
/// <remarks>
/// 返回格式：[{"address": "GPIB0::1::INSTR", "handle": "12345"}, ...]
/// </remarks>
public static string GetOpenedConnectionsJson()
{
    return ConnectionRegistry.GetConnectionsAsJson();
}
```

#### CloseAllConnections() - 關閉所有連線
```csharp
/// <summary>
/// 關閉所有已開啟的 VISA 連線
/// </summary>
public static void CloseAllConnections()
{
    ConnectionRegistry.CloseAll();
}
```

---

## 2. VISAManagerCore 類別

### 用途
管理多個 VISA 儀器實例。

### 類別簽章
```csharp
namespace VisaBundle.Core
{
    public class VISAManagerCore : IDisposable
    {
        // 建構函式
        public VISAManagerCore();

        // 儀器管理
        public VisaCore AddInstrument(string name, string address);
        public VisaCore GetInstrument(string name);
        public bool RemoveInstrument(string name);
        public void CloseAll();
        public string[] ListInstruments();

        // 靜態工具
        public static string[] DiscoverInstruments();

        // IDisposable
        public void Dispose();
    }
}
```

### 方法詳細規格

```csharp
/// <summary>
/// 初始化 VISA 管理器
/// </summary>
public VISAManagerCore()
{
    _instruments = new Dictionary<string, VisaCore>();
}

/// <summary>
/// 新增並連線到儀器
/// </summary>
/// <param name="name">唯一儀器識別名稱</param>
/// <param name="address">VISA 資源地址</param>
/// <returns>VISA 儀器實例</returns>
/// <exception cref="ArgumentException">儀器名稱已存在</exception>
public VisaCore AddInstrument(string name, string address)
{
    if (_instruments.ContainsKey(name))
        throw new ArgumentException($"Instrument '{name}' already exists");

    var instrument = new VisaCore(name, address);
    _instruments[name] = instrument;
    return instrument;
}

/// <summary>
/// 根據名稱取得儀器
/// </summary>
/// <param name="name">儀器識別名稱</param>
/// <returns>VISA 儀器實例，若不存在則為 null</returns>
public VisaCore GetInstrument(string name)
{
    return _instruments.TryGetValue(name, out var instrument)
        ? instrument
        : null;
}

/// <summary>
/// 移除並關閉儀器連線
/// </summary>
/// <param name="name">儀器識別名稱</param>
/// <returns>成功移除返回 true，否則 false</returns>
public bool RemoveInstrument(string name)
{
    if (_instruments.TryGetValue(name, out var instrument))
    {
        instrument.Close();
        _instruments.Remove(name);
        return true;
    }
    return false;
}

/// <summary>
/// 關閉所有儀器連線
/// </summary>
public void CloseAll()
{
    foreach (var instrument in _instruments.Values)
    {
        instrument.Close();
    }
    _instruments.Clear();
}

/// <summary>
/// 列出所有已管理的儀器名稱
/// </summary>
/// <returns>儀器名稱陣列</returns>
public string[] ListInstruments()
{
    return _instruments.Keys.ToArray();
}

/// <summary>
/// 發現可用的 VISA 資源
/// </summary>
/// <returns>可用 VISA 資源地址陣列</returns>
public static string[] DiscoverInstruments()
{
    return VisaCore.ListResources();
}
```

---

## 3. VisaSettingsCore 類別

### 用途
全域配置管理（對應 Python 的 Setting 模組）。

### 類別簽章
```csharp
namespace VisaBundle.Core
{
    /// <summary>
    /// VISA 全域設定（靜態類別）
    /// </summary>
    public static class VisaSettingsCore
    {
        // 設定屬性
        public static bool SendEnabled { get; set; }
        public static bool PrintEnabled { get; set; }
        public static bool DebugMode { get; set; }
        public static bool IsServer { get; set; }
        public static bool IsInterrupt { get; set; }

        // 重置方法
        public static void Reset();
    }
}
```

### 實作
```csharp
public static class VisaSettingsCore
{
    /// <summary>
    /// 是否實際發送 VISA 指令（false 為測試模式）
    /// </summary>
    public static bool SendEnabled { get; set; } = false;

    /// <summary>
    /// 是否列印除錯訊息
    /// </summary>
    public static bool PrintEnabled { get; set; } = false;

    /// <summary>
    /// 除錯模式
    /// </summary>
    public static bool DebugMode { get; set; } = false;

    /// <summary>
    /// 伺服器模式
    /// </summary>
    public static bool IsServer { get; set; } = false;

    /// <summary>
    /// 中斷處理旗標
    /// </summary>
    public static bool IsInterrupt { get; set; } = false;

    /// <summary>
    /// 重置所有設定到預設值
    /// </summary>
    public static void Reset()
    {
        SendEnabled = false;
        PrintEnabled = false;
        DebugMode = false;
        IsServer = false;
        IsInterrupt = false;
    }
}
```

---

## 4. ConnectionRegistry 類別

### 用途
管理全域連線池（對應 Python 的 `opened_connections`）。

### 類別簽章
```csharp
namespace VisaBundle.Core
{
    /// <summary>
    /// 連線池管理（靜態類別）
    /// </summary>
    internal static class ConnectionRegistry
    {
        // 連線管理
        public static void RegisterConnection(string address, IMessageBasedSession session);
        public static void UnregisterConnection(string address);
        public static IMessageBasedSession GetConnection(string address);
        public static void CloseAll();

        // 查詢方法
        public static string GetConnectionsAsJson();
        public static int GetConnectionCount();
    }
}
```

### 實作
```csharp
internal static class ConnectionRegistry
{
    private static readonly Dictionary<string, IMessageBasedSession> _connections
        = new Dictionary<string, IMessageBasedSession>();

    private static readonly object _lock = new object();

    /// <summary>
    /// 註冊新連線到池中
    /// </summary>
    public static void RegisterConnection(string address, IMessageBasedSession session)
    {
        lock (_lock)
        {
            _connections[address] = session;
        }
    }

    /// <summary>
    /// 從池中移除連線
    /// </summary>
    public static void UnregisterConnection(string address)
    {
        lock (_lock)
        {
            _connections.Remove(address);
        }
    }

    /// <summary>
    /// 取得已存在的連線
    /// </summary>
    public static IMessageBasedSession GetConnection(string address)
    {
        lock (_lock)
        {
            return _connections.TryGetValue(address, out var session)
                ? session
                : null;
        }
    }

    /// <summary>
    /// 關閉所有連線
    /// </summary>
    public static void CloseAll()
    {
        lock (_lock)
        {
            foreach (var session in _connections.Values)
            {
                try
                {
                    session.Dispose();
                }
                catch { }
            }
            _connections.Clear();
        }
    }

    /// <summary>
    /// 以 JSON 格式返回所有連線資訊
    /// </summary>
    public static string GetConnectionsAsJson()
    {
        lock (_lock)
        {
            var list = _connections.Select(kvp => new
            {
                address = kvp.Key,
                handle = kvp.Value.GetHashCode().ToString()
            }).ToList();

            return System.Text.Json.JsonSerializer.Serialize(list);
        }
    }

    /// <summary>
    /// 取得連線數量
    /// </summary>
    public static int GetConnectionCount()
    {
        lock (_lock)
        {
            return _connections.Count;
        }
    }
}
```

---

## 5. VisaException 類別

### 用途
統一的 VISA 異常類別。

### 類別簽章
```csharp
namespace VisaBundle.Core
{
    /// <summary>
    /// VISA 操作異常
    /// </summary>
    public class VisaException : Exception
    {
        public VisaException() : base() { }

        public VisaException(string message) : base(message) { }

        public VisaException(string message, Exception innerException)
            : base(message, innerException) { }
    }
}
```

---

## 6. 數據類型對應表

| Python 類型 | C# 類型 | 說明 |
|------------|---------|------|
| `str` | `string` | 文字字串 |
| `int` | `int` | 整數 |
| `float` | `double` | 浮點數 |
| `bool` | `bool` | 布林值 |
| `bytes` | `byte[]` | 二進位資料 |
| `List[str]` | `string[]` | 字串陣列 |
| `List[Tuple[str, Any]]` | JSON string | 複雜結構用 JSON 序列化 |
| `Optional[T]` | `Nullable<T>` 或 `T?` | 可空類型 |
| `None` | `null` | 空值 |

---

## 7. Python Wrapper 接口設計

### 數據轉換示例

```python
# C# byte[] → Python bytes
net_array = visa_core.ReadBinary()
python_bytes = bytes(net_array)

# Python bytes → C# byte[]
python_bytes = b'\x01\x02\x03'
import System
net_array = System.Array[System.Byte](list(python_bytes))

# C# string[] → Python list
net_array = VisaCore.ListResources()
python_list = list(net_array)

# JSON 字串轉換
import json
json_str = VisaCore.GetOpenedConnectionsJson()
python_list = json.loads(json_str)
```

---

## 8. 建置目標

### 目標框架
- **主要：** .NET Framework 4.8（Windows 內建，pythonnet 最佳兼容）
- **備選：** .NET 6.0（跨平台，需要 pythonnet 3.0+）

### NuGet 依賴
```xml
<PackageReference Include="NationalInstruments.Visa" Version="21.0.0" />
<!-- 或 -->
<PackageReference Include="Ivi.Visa" Version="5.12.0" />
```

### 輸出
- `VisaBundleCore.dll` - 主要 DLL
- `VisaBundleCore.pdb` - 除錯符號（可選）
- `NationalInstruments.Visa.dll` - VISA 依賴（需一起部署）

---

## 9. 測試策略

### C# 單元測試
- 使用 xUnit 框架
- 模擬 VISA 資源管理器
- 測試所有公開方法
- 測試異常處理

### Python 整合測試
- 保持現有測試不變
- 新增 DLL 加載測試
- 新增數據轉換測試
- 新增性能基準測試

---

## 10. 版本兼容性

### API 版本
- **v1.0.0** - 初始 C# DLL 版本
- 保持與 Python v0.1.0 功能相同

### 向後兼容
- Python API 完全向後兼容
- 現有 Python 代碼無需修改
- 新功能通過 C# 添加後，Python 自動獲得

---

## 總結

本設計確保：
1. ✅ C# DLL 提供完整的 VISA 功能
2. ✅ Python wrapper 保持 API 不變
3. ✅ 數據類型正確轉換
4. ✅ 異常處理統一
5. ✅ 執行緒安全（連線池使用 lock）
6. ✅ pythonnet 友好（簡單類型，無複雜泛型）
7. ✅ 易於測試和除錯
