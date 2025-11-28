using System;
using System.Collections.Generic;
using System.Linq;

namespace VisaBundle.Core
{
    /// <summary>
    /// VISA 多儀器管理類別
    /// 提供高階介面來管理多個 VISA 儀器實例
    /// 對應 Python 的 VISAManager 類別
    /// </summary>
    public class VISAManagerCore : IDisposable
    {
        #region 私有欄位

        // 儀器字典：name -> VisaCore instance
        private readonly Dictionary<string, VisaCore> _instruments;

        // Dispose 旗標
        private bool _disposed = false;

        #endregion

        #region 建構函式

        /// <summary>
        /// 初始化 VISA 管理器
        /// </summary>
        public VISAManagerCore()
        {
            _instruments = new Dictionary<string, VisaCore>();
        }

        #endregion

        #region 儀器管理方法

        /// <summary>
        /// 新增並連線到儀器
        /// </summary>
        /// <param name="name">唯一儀器識別名稱</param>
        /// <param name="address">VISA 資源地址</param>
        /// <returns>VISA 儀器實例</returns>
        /// <exception cref="ArgumentNullException">name 或 address 為 null</exception>
        /// <exception cref="ArgumentException">儀器名稱已存在</exception>
        /// <exception cref="VisaException">連線失敗</exception>
        public VisaCore AddInstrument(string name, string address)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new ArgumentNullException(nameof(name));

            if (string.IsNullOrWhiteSpace(address))
                throw new ArgumentNullException(nameof(address));

            if (_instruments.ContainsKey(name))
                throw new ArgumentException($"Instrument '{name}' already exists");

            try
            {
                // 建立新的 VISA 實例（會自動開啟連線）
                var instrument = new VisaCore(name, address);
                _instruments[name] = instrument;

                if (VisaSettingsCore.DebugMode)
                    Console.WriteLine($"[VISAManager] Added instrument: {name} ({address})");

                return instrument;
            }
            catch (Exception ex)
            {
                throw new VisaException($"Failed to add instrument '{name}'", ex);
            }
        }

        /// <summary>
        /// 根據名稱取得儀器
        /// </summary>
        /// <param name="name">儀器識別名稱</param>
        /// <returns>VISA 儀器實例，若不存在則為 null</returns>
        public VisaCore? GetInstrument(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return null;

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
            if (string.IsNullOrWhiteSpace(name))
                return false;

            if (_instruments.TryGetValue(name, out var instrument))
            {
                try
                {
                    instrument.Close();
                    instrument.Dispose();
                }
                catch (Exception ex)
                {
                    if (VisaSettingsCore.DebugMode)
                        Console.WriteLine($"[VISAManager] Error closing instrument '{name}': {ex.Message}");
                }

                _instruments.Remove(name);

                if (VisaSettingsCore.DebugMode)
                    Console.WriteLine($"[VISAManager] Removed instrument: {name}");

                return true;
            }

            return false;
        }

        /// <summary>
        /// 關閉所有儀器連線
        /// </summary>
        public void CloseAll()
        {
            if (VisaSettingsCore.DebugMode)
                Console.WriteLine($"[VISAManager] Closing all {_instruments.Count} instruments");

            foreach (var kvp in _instruments)
            {
                try
                {
                    kvp.Value.Close();
                    kvp.Value.Dispose();
                }
                catch (Exception ex)
                {
                    if (VisaSettingsCore.DebugMode)
                        Console.WriteLine($"[VISAManager] Error closing '{kvp.Key}': {ex.Message}");
                }
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
        /// 檢查儀器是否存在
        /// </summary>
        /// <param name="name">儀器識別名稱</param>
        /// <returns>存在返回 true，否則 false</returns>
        public bool HasInstrument(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return false;

            return _instruments.ContainsKey(name);
        }

        /// <summary>
        /// 取得已管理的儀器數量
        /// </summary>
        public int InstrumentCount => _instruments.Count;

        #endregion

        #region 靜態工具方法

        /// <summary>
        /// 發現可用的 VISA 資源
        /// 等同於 VisaCore.ListResources()
        /// </summary>
        /// <returns>可用 VISA 資源地址陣列</returns>
        public static string[] DiscoverInstruments()
        {
            return VisaCore.ListResources();
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
                    // 關閉所有儀器
                    CloseAll();
                }

                _disposed = true;
            }
        }

        /// <summary>
        /// 解構函式
        /// </summary>
        ~VISAManagerCore()
        {
            Dispose(false);
        }

        #endregion
    }
}
