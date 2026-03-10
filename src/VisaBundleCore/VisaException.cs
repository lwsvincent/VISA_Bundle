using System;

namespace VisaBundle.Core
{
    /// <summary>
    /// VISA 操作異常類別
    /// </summary>
    public class VisaException : Exception
    {
        /// <summary>
        /// 初始化 VisaException 類別的新實例
        /// </summary>
        public VisaException()
            : base()
        {
        }

        /// <summary>
        /// 使用指定的錯誤訊息初始化 VisaException 類別的新實例
        /// </summary>
        /// <param name="message">描述錯誤的訊息</param>
        public VisaException(string message)
            : base(message)
        {
        }

        /// <summary>
        /// 使用指定的錯誤訊息和內部異常初始化 VisaException 類別的新實例
        /// </summary>
        /// <param name="message">描述錯誤的訊息</param>
        /// <param name="innerException">導致目前異常的內部異常</param>
        public VisaException(string message, Exception innerException)
            : base(message, innerException)
        {
        }
    }
}
