# Closed Intentions

## [2026-11-05 12:40] 任務意圖：全廠區通用 VISA Bundle 環境驗證機制 (Universal Multi-Site Validation) [Status: Completed]
- **核心目標 (Objective)**：
  - 解決多廠區（台灣總部、泰國廠、外網/備用站點）維護多個 Git 分支與套件命名碎片化的問題。
  - 將驗證機制升級為「全廠區通用版（Universal Multi-Site Validation）」，套件名稱統一維持 `visa_bundle`，使 `tm_updater` 不需修改任何 `updater.toml` 即可自動偵測與更新。
  - 運作規則：
    1. 台灣廠驗證：檢查 PNT52 網芳（`\\pnt52\研發測試共用資料夾\Vincent`）。
    2. 泰國廠驗證：Ping 泰國 MES IP `10.51.64.67`（支援 `ACBEL_MES_IP` 環境變數）。
    3. 備用站點驗證：Ping Fallback hosts（`dq-ework.apitech.com.tw`、`LWS.acbel.com`）。
    4. 任一站點通過即允許使用 VISA Bundle；全數失敗則拋出 `EnvironmentError`。
- **驗收標準 (Acceptance Criteria)**：
  - `src/visa_bundle/VISA.py` 整合多廠區聯集容錯判定（Short-circuiting 依序驗證，降低延遲）。
  - 套件名稱與結構保持與 `tm_updater` 100% 相容（標準 PEP 440 與 wheel 命名）。
  - 單元測試涵蓋：
    - 台灣 PNT52 成功的情境。
    - 泰國 MES IP Ping 成功的情境。
    - Fallback 主機成功的情境。
    - 全數失敗拋出 `EnvironmentError` 的情境。
  - 所有既有測試 (pytest) 全數通過（47/47 passed）。
- **範疇邊界 (In-Scope & Out-of-Scope)**：
  - 涵蓋範圍：
    - `src/visa_bundle/VISA.py` 驗證邏輯重構為多站點通用。
    - 規格文件 `docs/specs/universal_environment_validation.md`。
    - 單元測試 `tests/test_universal_validation.py`。
  - 本次不做 (Non-Goals)：
    - 不改動 VISA 核心通訊（Open/Close/Query/Write）功能邏輯。
