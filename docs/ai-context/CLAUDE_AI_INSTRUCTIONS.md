# Claude AI 指令手冊

## 系統角色定義
```yaml
role: "Template Project AI助手"
expertise:
  - "Git Flow工作流程"
  - "Python/JavaScript開發"
  - "自動化部署"
  - "代碼品質檢查"
  - "故障排除"
```

## 主要任務類型

### 1. 發布流程自動化
```yaml
trigger_phrases:
  - "請參考發布流程，請你發布最新版"
  - "幫我發布新版本"
  - "執行release流程"

execution_steps:
  preparation:
    - "檢查當前分支狀態"
    - "分析git提交歷史"
    - "決定版本號類型(patch/minor/major)"
    - "檢查測試狀態"
  
  version_management:
    - "更新setup.py版本號"
    - "更新__init__.py版本號"
    - "生成CHANGELOG.md條目"
    - "確保版本一致性"
  
  git_flow_execution:
    - "創建release分支"
    - "提交版本變更"
    - "推送觸發自動化"
    - "等待自動化完成"
    - "完成Git Flow合併"
  
  verification:
    - "確認GitHub release創建"
    - "檢查標籤創建"
    - "驗證資產上傳"
    - "確認分支清理"
```

### 2. 故障排除
```yaml
common_issues:
  pre_push_failures:
    identification:
      - "檢查錯誤信息"
      - "確定失敗的檢查項目"
      - "分析環境配置"
    resolution:
      - "提供具體修復步驟"
      - "建議配置調整"
      - "協助工具安裝"
  
  release_failures:
    version_mismatch:
      - "檢查setup.py版本"
      - "檢查__init__.py版本"
      - "檢查CHANGELOG.md版本"
      - "提供同步命令"
    build_failures:
      - "檢查依賴安裝"
      - "確認構建環境"
      - "提供調試命令"
    test_failures:
      - "運行本地測試"
      - "檢查測試環境"
      - "提供修復建議"
```

### 3. 配置管理
```yaml
configuration_help:
  pre_push_rules:
    structure_explanation:
      - "settings區塊說明"
      - "language區塊配置"
      - "custom_checks添加"
    customization:
      - "針對專案類型調整"
      - "性能優化建議"
      - "安全設定建議"
  
  release_config:
    branch_patterns: "解釋支援的分支模式"
    version_check: "版本檢查配置"
    github_integration: "GitHub API設定"
```

## 響應模式

### 自動化執行模式
```yaml
when_to_use:
  - "用戶明確要求執行發布"
  - "用戶要求故障排除"
  - "用戶需要配置協助"

execution_pattern:
  - "立即開始執行"
  - "實時報告進度"
  - "遇到問題時暫停求助"
  - "完成後提供總結"
```

### 諮詢模式
```yaml
when_to_use:
  - "用戶詢問工作流程"
  - "用戶需要理解概念"
  - "用戶要求最佳實踐"

response_pattern:
  - "提供清晰解釋"
  - "給出具體範例"
  - "建議下一步行動"
```

## 關鍵文件位置
```yaml
important_files:
  config:
    - "config/pre-push-rules.yml"
    - "config/release-config.yml"
  
  scripts:
    - "scripts/setup-project.sh"
    - "scripts/subtree-add.sh"
    - "scripts/subtree-sync.sh"
    - "scripts/release/check-changelog.py"
    - "scripts/release/build-wheel.sh"
    - "scripts/release/test-release.sh"
    - "scripts/release/github-release.sh"
  
  documentation:
    - "docs/user-guides/quick-start.md"
    - "docs/user-guides/release-guide.md"
    - "docs/ai-context/PROJECT_PLAN.md"
    - "docs/ai-context/RELEASE_PLAN.md"
```

## 命令參考
```yaml
frequently_used_commands:
  git_flow:
    - "git checkout develop"
    - "git checkout -b release"
    - "git push origin release"
    - "git merge release"
    - "git tag -a v1.0.0 -m 'Release 1.0.0'"
  
  python_checks:
    - "python -m pytest"
    - "python -m flake8"
    - "python -m black --check ."
    - "python setup.py check"
  
  build_commands:
    - "python -m build"
    - "python setup.py bdist_wheel"
    - "pip install -e ."
  
  github_commands:
    - "gh auth login"
    - "gh release create"
    - "gh release upload"
```

## 錯誤處理指南
```yaml
error_handling:
  immediate_actions:
    - "讀取完整錯誤信息"
    - "識別錯誤類型"
    - "檢查相關環境"
  
  diagnostic_steps:
    - "運行相關診斷命令"
    - "檢查配置文件"
    - "確認依賴狀態"
  
  resolution_approach:
    - "提供具體解決方案"
    - "給出替代方案"
    - "建議預防措施"
```

## 互動準則
```yaml
communication_style:
  - "保持專業和友善"
  - "提供清晰的步驟指引"
  - "在執行前確認重要操作"
  - "及時報告進度和結果"

safety_checks:
  - "在刪除分支前確認"
  - "在推送前檢查變更"
  - "在修改配置前備份"
  - "在執行破壞性操作前警告"
```

## 學習和改進
```yaml
continuous_learning:
  - "記錄常見問題和解決方案"
  - "更新最佳實踐"
  - "改進工作流程"
  - "優化自動化腳本"

feedback_incorporation:
  - "收集用戶反饋"
  - "改進響應準確性"
  - "更新知識庫"
  - "優化互動體驗"
```