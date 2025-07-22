# Git Subtree 使用指南

## 什麼是Git Subtree
Git Subtree是Git的一個功能，允許將一個Git倉庫作為另一個Git倉庫的子目錄。與Git Submodule不同，Subtree將外部代碼完全集成到主倉庫中。

## 為什麼使用Subtree
- **完整集成**：子項目代碼完全包含在主倉庫中
- **簡化克隆**：克隆主倉庫就能獲得所有代碼
- **獨立開發**：可以在主倉庫中修改子項目代碼
- **雙向同步**：可以將修改推送回子項目

## Template Project中的Subtree使用

### 架構概述
```
主專案倉庫/
├── src/                    # 主專案代碼
├── tests/                  # 主專案測試
├── template_project/       # Subtree目錄
│   ├── .git-hooks/         # Git hooks
│   ├── .ai-prompts/        # AI提示模板
│   ├── scripts/            # 管理腳本
│   └── config/             # 配置文件
└── other_files
```

### 工作流程
1. Template Project作為獨立倉庫開發
2. 使用Subtree將其集成到各個專案中
3. 在專案中使用template功能
4. 將改進推送回template倉庫

## 基本操作

### 1. 添加Subtree
```bash
# 語法
git subtree add --prefix=<目錄名> <遠程倉庫> <分支> --squash

# 使用我們的腳本（推薦）
./new_scripts/subtree_init.bat -rootpath <目標專案路徑>

# 手動添加範例
cd /path/to/your/project
git subtree add --prefix=template_project /path/to/template_project main --squash
```

### 2. 拉取更新
```bash
# 語法
git subtree pull --prefix=<目錄名> <遠程倉庫> <分支> --squash

# 使用我們的腳本（推薦）
./new_scripts/subtree_pull.bat -rootpath <目標專案路徑>

# 手動拉取範例
git subtree pull --prefix=template_project /path/to/template_project main --squash
```

### 3. 推送修改
```bash
# 語法
git subtree push --prefix=<目錄名> <遠程倉庫> <分支>

# 批量操作已移至new_scripts
# 建議使用Git直接管理推送操作

# 手動推送範例
git subtree push --prefix=template_project /path/to/template_project main
```

## 實際使用場景

### 場景1：新專案集成Template Project
```bash
# 1. 創建新專案
mkdir my_new_project
cd my_new_project
git init

# 2. 添加一些初始代碼
echo "# My New Project" > README.md
git add .
git commit -m "Initial commit"

# 3. 添加template project
/path/to/template_project/new_scripts/subtree_init.bat -rootpath .

# 4. 設置環境
cd template_project
./new_scripts/create_venv.bat -local -dev
```

### 場景2：現有專案集成Template Project
```bash
# 1. 進入現有專案
cd /path/to/existing/project

# 2. 添加template project
/path/to/template_project/new_scripts/subtree_init.bat -rootpath .

# 3. 設置環境
cd template_project
./new_scripts/create_venv.bat -local -dev
```

### 場景3：同步Template Project更新
```bash
# 在專案根目錄
./template_project/new_scripts/subtree_pull.bat -rootpath .

# 重新安裝hooks（如果有更新）
cd template_project
./new_scripts/create_venv.bat -local -dev
```

### 場景4：貢獻改進回Template Project
```bash
# 1. 在專案中修改template_project內容
vim template_project/config/pre-push-rules.yml

# 2. 提交到專案倉庫
git add .
git commit -m "Improve pre-push rules"

# 3. 推送改進回template project
# 批量推送功能已移至new_scripts
# 建議直接使用Git提交並推送改進
```

## 多專案管理

### 批量操作
```bash
# 創建批量更新腳本
cat > update_all_projects.sh << 'EOF'
#!/bin/bash
PROJECTS=(
    "/path/to/am_report_generator"
    "/path/to/am_shared" 
    "/path/to/gui_export_single_report"
)

for project in "${PROJECTS[@]}"; do
    echo "Updating $project..."
    ./new_scripts/subtree_pull.bat -rootpath "$project"
done
EOF

chmod +x update_all_projects.sh
./update_all_projects.sh
```

### 版本管理
```bash
# 在template project中創建版本標籤
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0

# 在專案中使用特定版本
git subtree add --prefix=template_project /path/to/template_project v1.0.0 --squash
```

## 最佳實踐

### 1. 目錄結構
```
專案根目錄/
├── template_project/       # 固定名稱，便於腳本處理
│   ├── .git-hooks/
│   ├── .ai-prompts/
│   ├── scripts/
│   └── config/
├── src/                    # 專案源代碼
├── tests/                  # 專案測試
└── docs/                   # 專案文檔
```

### 2. 提交訊息
```bash
# 添加subtree
git commit -m "Add template_project subtree"

# 更新subtree
git commit -m "Update template_project to latest version"

# 推送改進
git commit -m "Improve template_project configuration"
```

### 3. 衝突處理
```bash
# 如果遇到衝突
git status
git diff

# 手動解決衝突後
git add .
git commit -m "Resolve subtree merge conflicts"
```

### 4. 備份和恢復
```bash
# 備份當前狀態
git tag backup-$(date +%Y%m%d_%H%M%S)

# 如果需要恢復
git reset --hard <backup-tag>
```

## 進階技巧

### 1. 自定義前綴
```bash
# 使用不同的目錄名
git subtree add --prefix=dev_tools /path/to/template_project main --squash
```

### 2. 過濾歷史
```bash
# 只包含相關的提交歷史
git subtree add --prefix=template_project /path/to/template_project main --squash
```

### 3. 腳本自動化
```bash
# 創建自動化腳本
cat > auto_sync.sh << 'EOF'
#!/bin/bash
cd template_project
git fetch origin
if [ $(git rev-list HEAD...origin/main --count) -gt 0 ]; then
    echo "Updates available, syncing..."
    ./scripts/subtree-sync.sh pull ..
    ./scripts/setup-project.sh
fi
EOF
```

### 4. 鉤子集成
```bash
# 在.git/hooks/post-merge中添加
#!/bin/bash
if [ -f "template_project/scripts/setup-project.sh" ]; then
    cd template_project
    ./scripts/setup-project.sh
fi
```

## 故障排除

### 常見問題

#### 1. Subtree命令失敗
```bash
# 檢查git版本
git --version

# 確保使用正確的路徑
ls -la /path/to/template_project

# 檢查權限
chmod +x template_project/scripts/*.sh
```

#### 2. 衝突處理
```bash
# 查看衝突文件
git status

# 手動編輯衝突
vim <conflicted_file>

# 解決後提交
git add .
git commit -m "Resolve conflicts"
```

#### 3. 歷史記錄問題
```bash
# 查看subtree歷史
git log --oneline template_project/

# 查看最後一次subtree操作
git log --grep="Subtree"
```

#### 4. 腳本執行錯誤
```bash
# 檢查腳本權限
ls -la template_project/scripts/

# 手動執行腳本查看錯誤
bash -x template_project/scripts/setup-project.sh
```

### 調試技巧
```bash
# 啟用詳細輸出
git subtree pull --prefix=template_project /path/to/template_project main --squash -v

# 查看git配置
git config --list | grep subtree

# 檢查遠程倉庫
git remote -v
```

## 替代方案比較

### Subtree vs Submodule
| 特性 | Subtree | Submodule |
|------|---------|-----------|
| 集成度 | 完全集成 | 引用鏈接 |
| 克隆簡便性 | 簡單 | 需要額外命令 |
| 修改能力 | 可以修改 | 需要切換到子模塊 |
| 學習曲線 | 中等 | 較陡峭 |
| 適用場景 | 模板、工具 | 獨立庫 |

### 選擇建議
- **使用Subtree**：模板專案、共享工具、小型依賴
- **使用Submodule**：大型獨立庫、版本敏感依賴

---

*此指南涵蓋了Git Subtree在Template Project中的完整使用方法*