# AI 輔助發布工作流程

## 📋 **標準作業程序（SOP）**

### **觸發指令**
當您需要發布新版本時，只需說：
```
請參考發布流程，請你發布最新版
```

---

## 🔄 **完整發布流程**

### **第一階段：準備檢查**
1. **檢查當前狀態**
   - 確認在 `develop` 分支
   - 檢查是否有未提交的變更
   - 驗證測試是否通過

2. **版本號決策**
   - **Patch** (1.0.x): 錯誤修復
   - **Minor** (1.x.0): 新功能
   - **Major** (x.0.0): 重大變更

3. **版本一致性檢查**
   - `setup.py` 版本號
   - `src/*//__init__.py` 版本號
   - `CHANGELOG.md` 最新條目

### **第二階段：版本準備**
4. **更新版本號**
   - 自動遞增版本號（根據變更類型）
   - 同步所有版本文件

5. **更新 CHANGELOG.md**
   - 添加新版本條目
   - 根據 git 提交歷史生成變更摘要
   - 確保符合 Keep a Changelog 格式

6. **清理環境**
   - 移除 build artifacts
   - 清理快取文件

### **第三階段：Git Flow 執行**
7. **創建 Release 分支**
   ```bash
   git checkout develop
   git checkout -b release
   ```

8. **提交版本變更**
   ```bash
   git add -A
   git commit -m "Prepare release vX.X.X"
   ```

9. **推送觸發自動化**
   ```bash
   git push origin release
   ```

### **第四階段：自動化處理**
10. **等待自動化完成**
    - Pre-push 檢查執行
    - Wheel 構建和驗證
    - 測試在隔離環境執行
    - GitHub release 自動創建
    - 資產上傳（wheel, CHANGELOG.md）

### **第五階段：完成合併**
11. **Git Flow 標準合併**
    ```bash
    # 合併到 main
    git checkout main
    git merge release
    git tag -a vX.X.X -m "Release X.X.X"
    
    # 合併回 develop
    git checkout develop
    git merge release
    
    # 清理 release 分支
    git branch -d release
    
    # 推送所有變更
    git push origin main develop vX.X.X
    ```

---

## 🎯 **AI 助手執行重點**

### **自動判斷項目**
- [x] **版本類型**: 根據變更內容決定 patch/minor/major
- [x] **變更摘要**: 分析 git 提交生成有意義的 CHANGELOG
- [x] **錯誤處理**: 發布失敗時提供詳細診斷
- [x] **狀態驗證**: 確保每個步驟成功完成

### **人工確認點**
- [ ] **版本號確認**: 在開始前確認版本號正確
- [ ] **CHANGELOG 檢查**: 確認變更說明準確
- [ ] **測試通過**: 確認所有測試通過
- [ ] **發布成功**: 確認 GitHub release 創建成功

### **安全機制**
- **回滾計劃**: 如果發布失敗，立即回滾到上一個穩定狀態
- **分支保護**: 確保 main 分支不被污染
- **版本追蹤**: 所有版本通過 Git tags 永久記錄

---

## 📊 **發布檢查清單**

### **發布前檢查 ✅**
- [ ] 所有測試通過
- [ ] 代碼格式檢查通過
- [ ] 版本號一致性
- [ ] CHANGELOG.md 已更新
- [ ] GitHub 認證有效

### **發布中監控 🔄**
- [ ] Release 分支創建成功
- [ ] 自動化檢查通過
- [ ] GitHub release 創建成功
- [ ] 資產上傳完成

### **發布後驗證 ✅**
- [ ] Main 分支包含新版本
- [ ] Develop 分支已同步
- [ ] Release 分支已刪除
- [ ] Git tag 已創建
- [ ] GitHub release 頁面正確

---

## 🚨 **常見問題處理**

### **發布失敗情況**
1. **測試失敗**: 回到 develop，修復後重新發布
2. **GitHub API 錯誤**: 檢查認證和權限
3. **版本衝突**: 檢查遠端是否有新的提交
4. **Build 失敗**: 檢查依賴和環境配置

### **回滾程序**
```bash
# 如果需要回滾
git checkout develop
git branch -D release  # 刪除失敗的 release 分支
git reset --hard HEAD~1  # 回到上一個提交
```

---

## 📝 **發布日誌範例**

### **輸入**
```
使用者：請參考發布流程，請你發布最新版
```

### **AI 輸出範例**
```
🚀 開始發布流程...

✅ 檢查當前狀態
- 當前分支: develop  
- 未提交變更: 5 個文件
- 上次版本: v1.0.4

🔍 分析變更類型
- 檢測到: 2 個新功能, 3 個錯誤修復
- 建議版本: v1.1.0 (minor release)
- 確認版本號? [Y/n]

📝 更新版本文件
- setup.py: 1.0.4 → 1.1.0
- __init__.py: 1.0.4 → 1.1.0  
- CHANGELOG.md: 添加 v1.1.0 條目

🌳 執行 Git Flow
- 創建 release 分支 ✅
- 提交版本變更 ✅
- 推送觸發自動化 ✅

⏳ 等待自動化完成...
- Pre-push 檢查: ✅ 通過
- Wheel 構建: ✅ 完成
- 測試執行: ✅ 13/13 通過
- GitHub release: ✅ 已創建

🔄 完成 Git Flow 合併
- 合併到 main: ✅
- 創建標籤 v1.1.0: ✅
- 合併回 develop: ✅
- 清理 release 分支: ✅

🎉 發布完成！
- 版本: v1.1.0
- GitHub: https://github.com/user/project/releases/tag/v1.1.0
- 下載: project-1.1.0-py3-none-any.whl
```

---

## 🔧 **輔助腳本**

### **檢查發布準備**
```bash
./scripts/check-release-ready.sh
```

### **準備發布（不推送）**
```bash
./scripts/prepare-release.sh [patch|minor|major] "變更說明"
```

---

**此文檔為 AI 輔助發布的標準作業程序，請妥善保存以便後續參考。**