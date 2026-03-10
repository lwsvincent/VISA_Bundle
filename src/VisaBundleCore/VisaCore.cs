using System;
using System.Text;
using System.Threading;

namespace VisaBundle.Core
{
    /// <summary>
    /// VISA 儀器通信核心類別
    /// 對應 Python VISA 類別，提供 Open/Close/Query/Write/Read 功能
    /// </summary>
    /// <remarks>
    /// 重要：本類別需要配合 VISA 驅動程式使用
    /// 支援的 VISA 庫：
    /// 1. NI-VISA (推薦) - 需要安裝 NI-VISA 驅動程式
    /// 2. IVI.NET VISA - 開源實現
    ///
    /// 使用前請確保：
    /// - 已安裝 VISA 驅動程式（如 NI-VISA 或 Keysight IO Libraries）
    /// - .csproj 中已引用對應的 VISA .NET 組件
    /// </remarks>
    public class VisaCore : IDisposable
    {
        #region 私有欄位

        // VISA session 物件（使用 dynamic 以支援不同的 VISA 實現）
        private object? _session;

        // Dispose 旗標
        private bool _disposed = false;

        #endregion

        #region 公開屬性

        /// <summary>
        /// 儀器識別名稱，用於日誌和除錯
        /// </summary>
        public string Name { get; }

        /// <summary>
        /// VISA 資源地址（例如：'GPIB0::1::INSTR', 'USB0::0x1234::0x5678::INSTR'）
        /// </summary>
        public string Address { get; }

        /// <summary>
        /// 連線是否已開啟
        /// </summary>
        public bool IsOpen { get; private set; }

        #endregion

        #region 建構函式

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

        #endregion

        #region 連線管理

        /// <summary>
        /// 開啟 VISA 連線，支援連線池和重試邏輯
        /// </summary>
        /// <remarks>
        /// 行為：
        /// - 檢查連線池，避免重複連線到同一地址
        /// - 失敗時自動重試 2 次，每次間隔 1 秒
        /// - 成功後註冊到全域連線池
        /// - 執行 Clear 操作清除儀器狀態
        /// </remarks>
        /// <exception cref="VisaException">連線失敗</exception>
        public void Open()
        {
            // 除錯輸出
            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"Open VISA: {Name}");

            // 測試模式跳過實際連線
            if (!VisaSettingsCore.SendEnabled)
            {
                IsOpen = true;  // 標記為已開啟（測試模式）
                return;
            }

            // 檢查連線池，避免重複連線
            var existingSession = ConnectionRegistry.GetConnection(Address);
            if (existingSession != null)
            {
                _session = existingSession;
                IsOpen = true;
                return;
            }

            // 重試邏輯：最多 2 次
            const int maxRetries = 2;
            Exception? lastException = null;

            for (int attempt = 0; attempt < maxRetries; attempt++)
            {
                try
                {
                    // === VISA 驅動程式調用 ===
                    //
                    // 方案 1：使用 NI-VISA (推薦)
                    // 需要引用：NationalInstruments.Visa 或 Ivi.Visa
                    //
                    // using Ivi.Visa;
                    // var resourceManager = new ResourceManager();
                    // var session = resourceManager.Open(Address);
                    // _session = session;
                    //
                    // if (session is IMessageBasedSession mbSession)
                    // {
                    //     mbSession.Clear();
                    // }
                    //
                    // 方案 2：使用反射動態載入（最大兼容性）
                    // 可以在運行時決定使用哪個 VISA 實現
                    //
                    // _session = OpenVisaResourceDynamic(Address);
                    //
                    // === 目前為示範版本 ===
                    // 實際部署時需要取消註釋上述代碼並配置 VISA 庫

                    // 模擬成功開啟（供測試用）
                    // TODO: 取消註釋上方的實際 VISA 代碼
                    _session = new object();  // 占位符

                    // 等待儀器穩定
                    Thread.Sleep(500);
                    IsOpen = true;

                    // 註冊到連線池
                    ConnectionRegistry.RegisterConnection(Address, _session);

                    if (VisaSettingsCore.DebugMode)
                        Console.WriteLine($"[{Name}] 連線成功: {Address}");

                    return;  // 成功，結束方法
                }
                catch (Exception ex)
                {
                    lastException = ex;

                    if (VisaSettingsCore.DebugMode)
                        Console.WriteLine($"[{Name}] 連線嘗試 {attempt + 1}/{maxRetries} 失敗: {ex.Message}");

                    // 最後一次嘗試前不等待
                    if (attempt < maxRetries - 1)
                        Thread.Sleep(1000);
                }
            }

            // 所有重試都失敗
            throw new VisaException(
                $"VISA Open Error: {Name}, address: {Address}",
                lastException);
        }

        /// <summary>
        /// 關閉 VISA 連線並從連線池移除
        /// </summary>
        public void Close()
        {
            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"Close VISA: {Name}");

            if (!VisaSettingsCore.SendEnabled || _session == null)
            {
                IsOpen = false;
                return;
            }

            try
            {
                // 嘗試關閉 session
                if (_session is IDisposable disposable)
                {
                    disposable.Dispose();
                }

                // 從連線池移除
                ConnectionRegistry.UnregisterConnection(Address);

                IsOpen = false;
                _session = null;

                if (VisaSettingsCore.DebugMode)
                    Console.WriteLine($"[{Name}] 連線已關閉");
            }
            catch (Exception ex)
            {
                if (VisaSettingsCore.DebugMode)
                    Console.WriteLine($"[{Name}] 關閉時發生錯誤: {ex.Message}");

                // 忽略關閉錯誤，確保狀態被重置
                IsOpen = false;
                _session = null;
            }
        }

        #endregion

        #region 文字 I/O 操作

        /// <summary>
        /// 發送命令並讀取回應
        /// </summary>
        /// <param name="command">SCPI 命令字串</param>
        /// <param name="delayTime">讀取前延遲時間（秒），null 表示無延遲</param>
        /// <returns>儀器回應字串</returns>
        /// <exception cref="VisaException">通信錯誤或 session 無效</exception>
        public string Query(string command, double? delayTime = null)
        {
            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"[{Name}] Query: {command}");

            // 測試模式返回模擬值
            if (!VisaSettingsCore.SendEnabled)
                return "0";

            if (_session == null)
                throw new VisaException("Session not opened - not MessageBasedResource");

            try
            {
                // === VISA 驅動程式調用 ===
                //
                // 實際代碼示例（需要 VISA 庫）：
                //
                // if (_session is IMessageBasedSession mbSession)
                // {
                //     string response;
                //     if (delayTime.HasValue)
                //     {
                //         mbSession.RawIO.Write(Encoding.ASCII.GetBytes(command + "\n"));
                //         Thread.Sleep((int)(delayTime.Value * 1000));
                //         response = mbSession.RawIO.ReadString();
                //     }
                //     else
                //     {
                //         response = mbSession.FormattedIO.Query(command);
                //     }
                //
                //     if (VisaSettingsCore.PrintEnabled)
                //         Console.WriteLine($"[{Name}] Recv: {response}");
                //
                //     return response;
                // }

                // 模擬回應（供測試用）
                string simulatedResponse = $"Response to: {command}";

                if (VisaSettingsCore.PrintEnabled)
                    Console.WriteLine($"[{Name}] Recv: {simulatedResponse}");

                return simulatedResponse;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"VISA Query Error: {Name}");
                Console.WriteLine($"Address: {Address}");
                Console.WriteLine($"Command: {command}");
                throw new VisaException("VISA Query Error", ex);
            }
        }

        /// <summary>
        /// 發送命令到儀器
        /// </summary>
        /// <param name="command">SCPI 命令字串</param>
        /// <exception cref="VisaException">通信錯誤或 session 無效</exception>
        public void Write(string command)
        {
            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"[{Name}] Write: {command}");

            if (!VisaSettingsCore.SendEnabled)
                return;

            if (_session == null)
                throw new VisaException("Session not opened - not MessageBasedResource");

            try
            {
                // === VISA 驅動程式調用 ===
                //
                // 實際代碼示例：
                //
                // if (_session is IMessageBasedSession mbSession)
                // {
                //     mbSession.FormattedIO.WriteLine(command);
                // }

                // 模擬寫入（供測試用）
                if (VisaSettingsCore.DebugMode)
                    Console.WriteLine($"[{Name}] Write completed");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"VISA Write Error: {Name}");
                Console.WriteLine($"Address: {Address}");
                Console.WriteLine($"Command: {command}");
                throw new VisaException("VISA Write Error", ex);
            }
        }

        /// <summary>
        /// 從儀器讀取資料
        /// </summary>
        /// <param name="count">讀取位元組數，null 表示讀取到終止符</param>
        /// <returns>回應字串</returns>
        /// <exception cref="VisaException">通信錯誤或 session 無效</exception>
        public string Read(int? count = null)
        {
            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"[{Name}] Read" + (count.HasValue ? $" ({count} bytes)" : ""));

            if (!VisaSettingsCore.SendEnabled)
                return "0";

            if (_session == null)
                throw new VisaException("Session not opened - not MessageBasedResource");

            try
            {
                // === VISA 驅動程式調用 ===
                //
                // 實際代碼示例：
                //
                // if (_session is IMessageBasedSession mbSession)
                // {
                //     string response;
                //     if (count.HasValue)
                //     {
                //         byte[] buffer = new byte[count.Value];
                //         mbSession.RawIO.Read(buffer);
                //         response = Encoding.UTF8.GetString(buffer);
                //     }
                //     else
                //     {
                //         response = mbSession.FormattedIO.ReadLine();
                //     }
                //
                //     if (VisaSettingsCore.PrintEnabled)
                //         Console.WriteLine(response);
                //
                //     return response;
                // }

                // 模擬讀取（供測試用）
                string simulatedResponse = count.HasValue
                    ? new string('X', count.Value)
                    : "Simulated read response";

                if (VisaSettingsCore.PrintEnabled)
                    Console.WriteLine(simulatedResponse);

                return simulatedResponse;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"VISA Read Error: {Name}");
                throw new VisaException("VISA Read Error", ex);
            }
        }

        #endregion

        #region 二進位 I/O 操作

        /// <summary>
        /// 從儀器讀取二進位資料
        /// </summary>
        /// <returns>二進位回應資料</returns>
        /// <exception cref="VisaException">通信錯誤或 session 無效</exception>
        public byte[] ReadBinary()
        {
            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"[{Name}] Read Binary");

            if (!VisaSettingsCore.SendEnabled)
                return new byte[0];

            if (_session == null)
                throw new VisaException("Session not opened - not MessageBasedResource");

            try
            {
                // === VISA 驅動程式調用 ===
                //
                // 實際代碼示例：
                //
                // if (_session is IMessageBasedSession mbSession)
                // {
                //     return mbSession.RawIO.Read();
                // }

                // 模擬讀取（供測試用）
                return new byte[] { 0x01, 0x02, 0x03, 0x04 };
            }
            catch (Exception ex)
            {
                Console.WriteLine($"VISA Read Binary Error: {Name}");
                throw new VisaException("VISA Read Binary Error", ex);
            }
        }

        /// <summary>
        /// 發送二進位資料到儀器
        /// </summary>
        /// <param name="data">二進位命令資料</param>
        /// <exception cref="VisaException">通信錯誤或 session 無效</exception>
        public void WriteBinary(byte[] data)
        {
            if (data == null)
                throw new ArgumentNullException(nameof(data));

            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"[{Name}] Write Binary (length: {data.Length} bytes)");

            if (!VisaSettingsCore.SendEnabled)
                return;

            if (_session == null)
                throw new VisaException("Session not opened - not MessageBasedResource");

            try
            {
                // === VISA 驅動程式調用 ===
                //
                // 實際代碼示例：
                //
                // if (_session is IMessageBasedSession mbSession)
                // {
                //     mbSession.RawIO.Write(data);
                // }

                // 模擬寫入（供測試用）
                if (VisaSettingsCore.DebugMode)
                    Console.WriteLine($"[{Name}] Binary write completed: {data.Length} bytes");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"VISA Write Binary Error: {Name}");
                throw new VisaException("VISA Write Binary Error", ex);
            }
        }

        /// <summary>
        /// 發送文字命令並讀取二進位回應
        /// </summary>
        /// <param name="command">文字命令</param>
        /// <param name="delayTime">延遲時間（秒）</param>
        /// <returns>二進位回應資料</returns>
        /// <exception cref="VisaException">通信錯誤或 session 無效</exception>
        public byte[] QueryBinary(string command, double delayTime = 0.1)
        {
            if (VisaSettingsCore.PrintEnabled)
                Console.WriteLine($"[{Name}] Query Binary: {command}");

            if (!VisaSettingsCore.SendEnabled)
                return Encoding.UTF8.GetBytes("0");

            if (_session == null)
                throw new VisaException("Session not opened - not MessageBasedResource");

            try
            {
                // 組合操作：Write + Delay + ReadBinary
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

        #endregion

        #region 靜態工具方法

        /// <summary>
        /// 列出所有可用的 VISA 資源
        /// </summary>
        /// <returns>VISA 資源地址陣列</returns>
        public static string[] ListResources()
        {
            try
            {
                // === VISA 驅動程式調用 ===
                //
                // 實際代碼示例：
                //
                // using Ivi.Visa;
                // var resourceManager = new ResourceManager();
                // return resourceManager.Find("?*").ToArray();

                // 模擬資源列表（供測試用）
                return new string[]
                {
                    "GPIB0::1::INSTR",
                    "USB0::0x1234::0x5678::INSTR",
                    "TCPIP0::192.168.1.100::inst0::INSTR"
                };
            }
            catch (Exception ex)
            {
                if (VisaSettingsCore.DebugMode)
                    Console.WriteLine($"ListResources error: {ex.Message}");

                return new string[0];
            }
        }

        /// <summary>
        /// 取得所有已開啟連線的資訊（JSON 格式）
        /// </summary>
        /// <returns>JSON 格式的連線資訊</returns>
        /// <remarks>
        /// 返回格式：[{"address": "GPIB0::1::INSTR", "handle": "12345"}, ...]
        /// Python 友好的格式
        /// </remarks>
        public static string GetOpenedConnectionsJson()
        {
            return ConnectionRegistry.GetConnectionsAsJson();
        }

        /// <summary>
        /// 關閉所有已開啟的 VISA 連線
        /// </summary>
        public static void CloseAllConnections()
        {
            ConnectionRegistry.CloseAll();
        }

        #endregion

        #region IDisposable 實作

        /// <summary>
        /// 釋放資源
        /// </summary>
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        /// <summary>
        /// 釋放資源（內部方法）
        /// </summary>
        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    // 釋放受管理資源
                    Close();
                }

                _disposed = true;
            }
        }

        /// <summary>
        /// 解構函式
        /// </summary>
        ~VisaCore()
        {
            Dispose(false);
        }

        #endregion
    }
}
