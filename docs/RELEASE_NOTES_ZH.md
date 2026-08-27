# Release Notes

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
