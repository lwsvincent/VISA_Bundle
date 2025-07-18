# 結構化工作流程

## 工作流程定義
```yaml
workflows:
  release_automation:
    name: "自動化發布流程"
    trigger: "用戶要求發布新版本"
    phases:
      - "準備階段"
      - "版本管理階段"
      - "Git Flow執行階段"
      - "驗證階段"
    
  troubleshooting:
    name: "故障排除流程"
    trigger: "用戶遇到錯誤或問題"
    phases:
      - "問題識別階段"
      - "診斷階段"
      - "解決階段"
      - "驗證階段"
  
  setup_assistance:
    name: "設置協助流程"
    trigger: "用戶需要配置或設置幫助"
    phases:
      - "需求分析階段"
      - "配置生成階段"
      - "安裝執行階段"
      - "測試驗證階段"
```

## 發布自動化工作流程
```yaml
release_workflow:
  phase_1_preparation:
    tasks:
      check_current_status:
        commands:
          - "git status"
          - "git branch"
          - "git log --oneline -5"
        validation:
          - "確認在develop分支"
          - "檢查工作目錄乾淨"
          - "確認最新提交"
      
      analyze_changes:
        commands:
          - "git log --oneline HEAD~10..HEAD"
          - "git diff HEAD~1..HEAD --name-only"
        analysis:
          - "識別變更類型"
          - "決定版本號遞增"
          - "生成變更摘要"
      
      version_decision:
        criteria:
          patch: "錯誤修復"
          minor: "新功能"
          major: "重大變更"
        output: "建議版本號"
  
  phase_2_version_management:
    tasks:
      update_version_files:
        files:
          - "setup.py"
          - "src/*//__init__.py"
          - "pyproject.toml"
        pattern: "version = \"X.X.X\""
      
      update_changelog:
        file: "CHANGELOG.md"
        format: "Keep a Changelog"
        sections:
          - "Added"
          - "Changed"
          - "Fixed"
          - "Removed"
      
      commit_changes:
        message: "Prepare release vX.X.X"
        files:
          - "所有版本相關文件"
          - "CHANGELOG.md"
  
  phase_3_git_flow:
    tasks:
      create_release_branch:
        commands:
          - "git checkout develop"
          - "git checkout -b release"
        validation: "確認分支創建成功"
      
      push_release_branch:
        command: "git push origin release"
        trigger: "自動化pre-push檢查"
        wait_for: "自動化完成"
      
      monitor_automation:
        checks:
          - "Pre-push檢查狀態"
          - "Wheel構建狀態"
          - "測試執行狀態"
          - "GitHub release狀態"
        timeout: "600秒"
      
      complete_git_flow:
        steps:
          - "git checkout main"
          - "git merge release"
          - "git tag -a vX.X.X -m 'Release X.X.X'"
          - "git checkout develop"
          - "git merge release"
          - "git branch -d release"
          - "git push origin main develop vX.X.X"
  
  phase_4_verification:
    tasks:
      verify_github_release:
        checks:
          - "GitHub release頁面存在"
          - "標籤正確創建"
          - "資產已上傳"
          - "版本號正確"
      
      verify_branches:
        checks:
          - "main分支包含新版本"
          - "develop分支已同步"
          - "release分支已刪除"
          - "標籤已推送"
      
      generate_report:
        content:
          - "發布版本號"
          - "包含的變更"
          - "GitHub release URL"
          - "下載連結"
```

## 故障排除工作流程
```yaml
troubleshooting_workflow:
  phase_1_identification:
    tasks:
      collect_error_info:
        sources:
          - "用戶提供的錯誤信息"
          - "命令輸出"
          - "日誌文件"
        analysis:
          - "識別錯誤類型"
          - "確定影響範圍"
          - "評估嚴重程度"
      
      categorize_issue:
        categories:
          pre_push_failure: "Pre-push檢查失敗"
          release_failure: "Release流程失敗"
          configuration_issue: "配置問題"
          environment_issue: "環境問題"
          dependency_issue: "依賴問題"
  
  phase_2_diagnosis:
    tasks:
      run_diagnostics:
        commands:
          system_check:
            - "git --version"
            - "python --version"
            - "pip --version"
          environment_check:
            - "which python"
            - "pip list"
            - "env | grep -E '(VIRTUAL_ENV|PATH)'"
          project_check:
            - "ls -la"
            - "git status"
            - "git remote -v"
      
      analyze_configuration:
        files:
          - "config/pre-push-rules.yml"
          - "config/release-config.yml"
          - "setup.py"
          - "requirements.txt"
        validation:
          - "語法正確性"
          - "配置完整性"
          - "路徑有效性"
  
  phase_3_resolution:
    tasks:
      provide_solution:
        approach:
          - "最直接的解決方案"
          - "替代方案"
          - "暫時性解決方案"
        format:
          - "具體命令"
          - "配置修改"
          - "環境設置"
      
      execute_fix:
        steps:
          - "備份當前狀態"
          - "執行修復命令"
          - "驗證修復效果"
          - "清理臨時文件"
  
  phase_4_verification:
    tasks:
      test_fix:
        commands:
          - "重新運行失敗的操作"
          - "執行基本功能測試"
          - "確認錯誤消失"
      
      provide_prevention:
        content:
          - "預防措施"
          - "最佳實踐"
          - "監控建議"
```

## 設置協助工作流程
```yaml
setup_workflow:
  phase_1_analysis:
    tasks:
      assess_project_type:
        detection:
          python:
            - "setup.py存在"
            - "pyproject.toml存在"
            - "requirements.txt存在"
          javascript:
            - "package.json存在"
            - "node_modules存在"
          mixed:
            - "同時存在多種類型"
        output: "專案類型識別"
      
      check_existing_setup:
        checks:
          - "template_project目錄存在"
          - "git hooks已安裝"
          - "配置文件存在"
        output: "現有設置狀態"
  
  phase_2_configuration:
    tasks:
      generate_pre_push_rules:
        template: "config/pre-push-rules.yml"
        customization:
          - "根據專案類型調整"
          - "根據用戶需求修改"
          - "添加專案特定檢查"
      
      generate_release_config:
        template: "config/release-config.yml"
        customization:
          - "設置分支模式"
          - "配置GitHub設定"
          - "設置測試參數"
  
  phase_3_installation:
    tasks:
      install_template_project:
        method: "subtree"
        commands:
          - "./scripts/subtree-add.sh <project-path>"
          - "cd template_project"
          - "./scripts/setup-project.sh"
        validation: "安裝成功確認"
      
      setup_environment:
        tasks:
          - "創建虛擬環境"
          - "安裝依賴"
          - "配置IDE"
          - "設置git hooks"
  
  phase_4_testing:
    tasks:
      test_pre_push:
        commands:
          - "git add ."
          - "git commit -m 'Test commit'"
          - "git push --dry-run"
        validation: "Pre-push檢查正常"
      
      test_ai_prompts:
        tasks:
          - "測試代碼審查模板"
          - "測試文檔生成模板"
          - "測試測試生成模板"
        validation: "AI模板可用"
```

## 決策樹
```yaml
decision_trees:
  error_classification:
    root: "錯誤類型"
    branches:
      syntax_error:
        condition: "語法錯誤信息"
        action: "檢查配置文件語法"
      permission_error:
        condition: "權限拒絕"
        action: "檢查文件權限和腳本執行權限"
      network_error:
        condition: "網絡連接失敗"
        action: "檢查網絡連接和GitHub認證"
      dependency_error:
        condition: "模塊或工具未找到"
        action: "安裝缺少的依賴"
  
  version_increment:
    root: "變更類型"
    branches:
      breaking_change:
        condition: "API變更或不兼容修改"
        action: "major版本遞增"
      new_feature:
        condition: "新功能添加"
        action: "minor版本遞增"
      bug_fix:
        condition: "錯誤修復"
        action: "patch版本遞增"
  
  branch_strategy:
    root: "當前分支"
    branches:
      on_develop:
        condition: "在develop分支"
        action: "可以創建release分支"
      on_feature:
        condition: "在feature分支"
        action: "需要先合併到develop"
      on_main:
        condition: "在main分支"
        action: "需要切換到develop"
```

## 狀態管理
```yaml
state_tracking:
  workflow_state:
    current_phase: "當前執行階段"
    completed_tasks: "已完成的任務"
    pending_tasks: "待執行的任務"
    error_state: "錯誤狀態"
  
  project_state:
    current_branch: "當前分支"
    version_info: "版本信息"
    test_status: "測試狀態"
    build_status: "構建狀態"
  
  user_context:
    last_action: "上次執行的操作"
    preferences: "用戶偏好設置"
    common_issues: "常見問題記錄"
```