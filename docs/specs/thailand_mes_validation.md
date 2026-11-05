# Specification: Thailand MES Validation Protocol

## 1. 概述 (Overview)
泰國廠產線與自動化測試環境無法存取台灣總部內網網芳路徑（`\\pnt52\...`）。本規格定義泰國廠專用 VISA Bundle 之環境授權驗證機制：改為 ping 泰國廠 MES 伺服器之 IP（預設 `10.51.64.67`）。只要成功 ping 通即授權使用。

## 2. 驗證流程與規格 (Verification Flow)

### 2.1 目標主機 (Target Hosts)
- 泰國廠 MES IP：`10.51.64.67`。
- 支援環境變數 `ACBEL_MES_IP` 覆寫，若未設定則預設為 `"10.51.64.67"`。
- Ping 策略：
  - Windows 平台執行 `ping -n 1 -w 1000 <host>`。
  - 若回傳碼為 0（`returncode == 0`），環境驗證成功。
  - 若無法 ping 通，拋出 `EnvironmentError("VISA Bundle 環境驗證失敗，請聯繫系統管理員。")`。

### 2.2 核心實作結構 (Implementation Detail in `src/visa_bundle/VISA.py`)
```python
def _ping(host: str) -> bool:
    try:
        result = _subprocess.run(
            ["ping", "-n", "1", "-w", "1000", host],
            stdout=_subprocess.DEVNULL,
            stderr=_subprocess.DEVNULL,
        )
        return result.returncode == 0
    except Exception:
        return False


_THAILAND_MES_IP = _os.getenv("ACBEL_MES_IP", "10.51.64.67")

_mes_ok = _ping(_THAILAND_MES_IP)
if not _mes_ok:
    raise EnvironmentError(
        "VISA Bundle 環境驗證失敗，請聯繫系統管理員。"
    )
```

### 2.3 邊界條件與除錯性 (Boundary Conditions)
1. **未在泰國廠內網或網路斷線**：`_ping` 捕獲逾時或異常並返回 `False`，明確引發 `EnvironmentError`。
2. **測試環境隔離**：在離線開發或 CI 測試環境中，可藉由設定 `ACBEL_MES_IP=127.0.0.1` 進行無干擾測試。
