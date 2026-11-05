# Change Log

### [2026-11-05 13:35] 發佈 visa_bundle 2.0.6 (正式版)

- **對應意圖 (Intention)**：`docs/archive/intentions_closed.md` (全廠區通用 VISA Bundle 環境驗證機制)
- **對應規格 (Spec/Schema)**：`docs/specs/universal_environment_validation.md`
- **修改原因 (Why)**：完成全廠區通用環境驗證機制（台灣 PNT52 + 泰國 MES 10.51.64.67 + 備用網路主機），升級版本至 2.0.6 正式發佈。
- **解耦與修改方式 (Decoupling & How)**：
  - 更新版本號至 `2.0.6`：`src/visa_bundle/__init__.py`, `pyproject.toml`
  - 更新文件：`CHANGELOG.md`, `README.md`, `docs/RELEASE_NOTES_ZH.md`, `docs/RELEASE_NOTES_EN.md`
  - 封存結案意圖至 `docs/archive/intentions_closed.md`
- **驗證與測試 (Verification & Testing)**：
  - 執行指令：`pytest`
  - 測試結果：47/47 passed。
- **結果 (Result)**：準備合併與建立 `v2.0.6` Git Tag 並編譯 protected wheel。

### [2026-11-05 12:40] 重構為通用型多廠區環境驗證機制 (Universal Multi-Site Validation)

- **對應意圖 (Intention)**：`docs/intention.md` (全廠區通用 VISA Bundle 環境驗證機制)
- **對應規格 (Spec/Schema)**：`docs/specs/universal_environment_validation.md`
- **修改原因 (Why)**：為兼顧 `tm_updater` 命名比對與全廠區自動更新需求，將驗證架構升級為通用版，避免多分支與版本碎片化。
- **解耦與修改方式 (Decoupling & How)**：
  - 受影響檔案：`src/visa_bundle/VISA.py`
  - 核心架構改動：
    - 依序以短路求值（Short-circuiting）檢查：
      1. 台灣總部 PNT52 網芳（路徑存在即通過，不發起網路 ping，零延遲）
      2. 泰國廠 MES IP `10.51.64.67`（支援 `ACBEL_MES_IP` 環境變數）
      3. 備用網路主機清單 (`dq-ework.apitech.com.tw`, `LWS.acbel.com`)
    - 任一站點條件達成即允許使用，全數失敗才拋出 `EnvironmentError`。
    - 套件名稱維持標準 `visa_bundle`，完全相容於 `tm_updater` 的 `packages = ["visa_bundle"]`。
  - 測試架構：新增 `tests/test_universal_validation.py`，完整涵蓋台灣 PNT52 命中、泰國 MES 命中、Fallback 命中及全數失敗等四種邊界條件。
- **驗證與測試 (Verification & Testing)**：
  - 執行指令：`pytest`
  - 涵蓋範圍：既有 43 項測試 + 新增 4 項通用驗證測試（共 47 項測試全數通過）。
- **結果 (Result)**：47 passed in 13.33s。

### [2026-11-05 11:42] 實作泰國廠 MES IP (10.51.64.67) Ping 驗證機制與單元測試

- **對應意圖 (Intention)**：`docs/intention.md` (泰國廠 VISA Bundle 環境驗證改為 MES IP Ping)
- **對應規格 (Spec/Schema)**：`docs/specs/thailand_mes_validation.md`
- **修改原因 (Why)**：依照使用者提供之泰國廠 MES 系統 IP `10.51.64.67`，將台灣網芳及備用主機檢查改為 ping 該 MES IP。
- **解耦與修改方式 (Decoupling & How)**：
  - 替換驗證邏輯並加入環境變數覆寫機制。
- **驗證與測試 (Verification & Testing)**：`pytest` 通過。
- **結果 (Result)**：驗證通過。
