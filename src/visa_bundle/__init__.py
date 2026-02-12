# VISA Bundle - Python Package for Instrument Control
"""
VISA Bundle - 高效的 Python VISA 儀器控制包

提供統一的 VISA 介面管理，包含連線追蹤、錯誤處理和全域設定功能。
"""

__version__ = "0.1.1"
__author__ = "DS Platform Team"
__email__ = "support@dsplatform.com"

import os as _os

if not _os.path.exists(r"\\pnt52\研發測試共用資料夾\Vincent"):
    raise EnvironmentError(
        "VISA Bundle 環境驗證失敗，請聯繫系統管理員。"
    )

# 主要匯出
from .VISA import VISA, VISAManager, opened_connections, Opened_List
from . import Setting
import pyvisa

__all__ = ["VISA", "VISAManager",
           "opened_connections", "Opened_List", "Setting"]
