namespace VisaBundle.Core
{
    /// <summary>
    /// VISA 全域設定（靜態類別）
    /// 對應 Python Setting 模組的全域變數
    /// </summary>
    public static class VisaSettingsCore
    {
        /// <summary>
        /// 是否實際發送 VISA 指令
        /// 設為 false 時進入測試模式，不會執行實際的 VISA 操作
        /// 預設值：false（安全起見）
        /// </summary>
        public static bool SendEnabled { get; set; } = false;

        /// <summary>
        /// 是否列印除錯訊息到 Console
        /// 設為 true 時會輸出所有 VISA 命令和回應
        /// 預設值：false
        /// </summary>
        public static bool PrintEnabled { get; set; } = false;

        /// <summary>
        /// 除錯模式旗標
        /// 用於額外的除錯功能
        /// 預設值：false
        /// </summary>
        public static bool DebugMode { get; set; } = false;

        /// <summary>
        /// 伺服器模式旗標
        /// 用於指示是否在伺服器環境中運行
        /// 預設值：false
        /// </summary>
        public static bool IsServer { get; set; } = false;

        /// <summary>
        /// 中斷處理旗標
        /// 用於中斷相關的控制邏輯
        /// 預設值：false
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
}
