using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace VisaBundle.Core
{
    /// <summary>
    /// 連線池管理（靜態類別）
    /// 管理所有已開啟的 VISA 連線，防止重複連線
    /// 執行緒安全
    /// </summary>
    internal static class ConnectionRegistry
    {
        // 連線字典：address -> session object
        private static readonly Dictionary<string, object> _connections
            = new Dictionary<string, object>();

        // 執行緒鎖
        private static readonly object _lock = new object();

        /// <summary>
        /// 註冊新連線到池中
        /// </summary>
        /// <param name="address">VISA 資源地址</param>
        /// <param name="session">VISA session 物件</param>
        public static void RegisterConnection(string address, object session)
        {
            if (string.IsNullOrWhiteSpace(address))
                throw new ArgumentNullException(nameof(address));

            if (session == null)
                throw new ArgumentNullException(nameof(session));

            lock (_lock)
            {
                _connections[address] = session;
            }
        }

        /// <summary>
        /// 從池中移除連線
        /// </summary>
        /// <param name="address">VISA 資源地址</param>
        /// <returns>是否成功移除</returns>
        public static bool UnregisterConnection(string address)
        {
            if (string.IsNullOrWhiteSpace(address))
                return false;

            lock (_lock)
            {
                return _connections.Remove(address);
            }
        }

        /// <summary>
        /// 取得已存在的連線
        /// </summary>
        /// <param name="address">VISA 資源地址</param>
        /// <returns>Session 物件，不存在則返回 null</returns>
        public static object? GetConnection(string address)
        {
            if (string.IsNullOrWhiteSpace(address))
                return null;

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
                        // 嘗試呼叫 Dispose 方法（如果實作了 IDisposable）
                        if (session is IDisposable disposable)
                        {
                            disposable.Dispose();
                        }
                    }
                    catch
                    {
                        // 忽略錯誤，繼續關閉其他連線
                    }
                }
                _connections.Clear();
            }
        }

        /// <summary>
        /// 以 JSON 格式返回所有連線資訊
        /// Python 友好的格式
        /// </summary>
        /// <returns>JSON 字串，格式：[{"address": "...", "handle": "..."}, ...]</returns>
        public static string GetConnectionsAsJson()
        {
            lock (_lock)
            {
                var sb = new StringBuilder();
                sb.Append("[");

                bool first = true;
                foreach (var kvp in _connections)
                {
                    if (!first)
                        sb.Append(",");

                    sb.Append("{");
                    sb.Append($"\"address\":\"{EscapeJson(kvp.Key)}\",");
                    sb.Append($"\"handle\":\"{kvp.Value.GetHashCode()}\"");
                    sb.Append("}");

                    first = false;
                }

                sb.Append("]");
                return sb.ToString();
            }
        }

        /// <summary>
        /// 取得連線數量
        /// </summary>
        /// <returns>當前連線數</returns>
        public static int GetConnectionCount()
        {
            lock (_lock)
            {
                return _connections.Count;
            }
        }

        /// <summary>
        /// 取得所有已連線的地址
        /// </summary>
        /// <returns>地址陣列</returns>
        public static string[] GetAllAddresses()
        {
            lock (_lock)
            {
                return _connections.Keys.ToArray();
            }
        }

        /// <summary>
        /// JSON 字串跳脫
        /// </summary>
        private static string EscapeJson(string text)
        {
            if (string.IsNullOrEmpty(text))
                return text;

            return text
                .Replace("\\", "\\\\")
                .Replace("\"", "\\\"")
                .Replace("\n", "\\n")
                .Replace("\r", "\\r")
                .Replace("\t", "\\t");
        }
    }
}
