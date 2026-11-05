# Release Notes

## v2.0.6 - 2026-11-05

### Summary
新增通用多廠區環境驗證支援（支援泰國廠 MES IP 與自訂環境變數）。

### Added
- 泰國廠 MES IP 驗證：Ping `10.51.64.67`。
- 支援環境變數 `ACBEL_MES_IP` 覆寫 MES IP。

### Changed
- 升級為通用多廠區驗證架構（Universal Multi-Site Validation）：依序以短路求值檢查台灣 PNT52 網芳、泰國 MES 系統與備用網路主機，任一站點符合即授權啟用。
- 測試套件補齊多站點驗證之單元測試（47 項測試通過）。

### Upgrade Notes
- 無 API 變更，與 `tm_updater` 100% 相容。

## v2.0.5 - 2026-08-27

### Summary
恢復實際 PNT52 環境驗證，並新增 LWS 備用網路主機。

### Fixed
- 移除 `VISA.py` 中強制 `_pnt52_ok = True` 的 bypass。

### Changed
- 當 PNT52 share 無法使用時，環境驗證現在可接受 `dq-ework.apitech.com.tw` 或 `LWS.acbel.com` 任一 fallback host。

### Upgrade Notes
- 無 API 變更。
- 若 PNT52 與兩個 fallback host 都無法連線，package 會再次拋出環境驗證錯誤。
