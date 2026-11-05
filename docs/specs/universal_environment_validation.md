# Specification: Universal Multi-Site Validation Protocol

## 1. 概述 (Overview)
為避免不同廠區（台灣總部、泰國廠等）維護獨立分支與不同套件名稱，本規格定義通用型多廠區環境授權驗證機制。保持標準套件名稱 `visa_bundle`，完全相容於 `tm_updater` 套件更新器。

## 2. 驗證策略與短路求值 (Short-Circuit Verification Strategy)

驗證邏輯採短路求值（Short-circuit evaluation），以確保最低的模組載入延遲：

1. **第一順位（台灣研發環境）**：
   - 檢查路徑：`_os.path.exists(r"\\pnt52\研發測試共用資料夾\Vincent")`
   - 若通過，立即判定成功，略過後續所有網路 Ping（延遲 0ms）。

2. **第二順位（泰國廠環境）**：
   - 若第一順位未通過，Ping 泰國 MES IP：`_os.getenv("ACBEL_MES_IP", "10.51.64.67")`。
   - 若 Ping 成功，立即判定成功，略過後續備用主機 Ping。

3. **第三順位（備用外網/總部連線）**：
   - 若前兩者皆未通過，依序 Ping 備用清單：
     - `dq-ework.apitech.com.tw`
     - `LWS.acbel.com`
   - 任一主機 Ping 成功即判定通過。

4. **終止條件**：
   - 若以上全部失敗，拋出 `EnvironmentError("VISA Bundle 環境驗證失敗，請聯繫系統管理員。")`。

## 3. 程式碼契約 (Code Contract in `src/visa_bundle/VISA.py`)

```python
_THAILAND_MES_IP = _os.getenv("ACBEL_MES_IP", "10.51.64.67")

_FALLBACK_NETWORK_HOSTS: Tuple[str, ...] = (
    "dq-ework.apitech.com.tw",
    "LWS.acbel.com",
)

# 1. 台灣總部 PNT52
_pnt52_ok = _os.path.exists(r"\\pnt52\研發測試共用資料夾\Vincent")

# 2. 泰國廠 MES IP
_thailand_mes_ok = not _pnt52_ok and _ping(_THAILAND_MES_IP)

# 3. 備用網路主機
_fallback_ok = not (_pnt52_ok or _thailand_mes_ok) and any(
    _ping(host) for host in _FALLBACK_NETWORK_HOSTS
)

if not (_pnt52_ok or _thailand_mes_ok or _fallback_ok):
    raise EnvironmentError(
        "VISA Bundle 環境驗證失敗，請聯繫系統管理員。"
    )
```

## 4. `tm_updater` 相容性
- **套件名稱**：`visa_bundle`（標準不變）。
- **wheel 檔名格式**：`visa_bundle-{version}-py3-none-any.whl`。
- **updater.toml 欄位**：`packages = [ ... "visa_bundle" ... ]` 完全不需要任何改動。

