# Template Project AI Context

## 系統概述
```yaml
project_name: "Template Project"
purpose: "統一的多專案協作開發工具集"
target_audience: "開發團隊、AI助手"
primary_functions:
  - "標準化Git Pre-push檢查"
  - "AI協作提示模板"
  - "Git Subtree集成"
  - "Git Flow Release自動化"
```

## 目錄結構
```yaml
template_project/:
  core_directories:
    - name: ".git-hooks"
      purpose: "Git hooks模板"
      files: ["pre-push", "install-hooks.sh"]
    - name: ".ai-prompts"
      purpose: "AI協作模板"
      files: ["code-review.md", "testing.md", "documentation.md"]
    - name: "scripts"
      purpose: "管理腳本"
      subdirs: ["release", "utils"]
    - name: "config"
      purpose: "配置文件"
      files: ["pre-push-rules.yml", "release-config.yml"]
    - name: "docs"
      purpose: "文檔"
      subdirs: ["user-guides", "ai-context"]
```

## 核心功能
```yaml
pre_push_checks:
  languages:
    python:
      tools: ["flake8", "black", "pytest", "mypy"]
      auto_detect: true
    javascript:
      tools: ["eslint", "prettier", "jest"]
      auto_detect: true
  security:
    - "敏感信息掃描"
    - "大文件檢測"
  configuration: "config/pre-push-rules.yml"

git_flow_release:
  supported_branches: ["release"]
  workflow:
    - "版本一致性檢查"
    - "Wheel構建"
    - "隔離環境測試"
    - "GitHub release創建"
    - "資產自動上傳"
  config_file: "config/release-config.yml"

subtree_integration:
  add_script: "scripts/subtree-add.sh"
  sync_script: "scripts/subtree-sync.sh"
  setup_script: "scripts/setup-project.sh"
```

## 支援的專案類型
```yaml
project_types:
  python:
    - "Django"
    - "Flask"
    - "FastAPI"
    - "通用Python專案"
  javascript:
    - "React"
    - "Vue"
    - "Node.js"
    - "Express"
  mixed:
    - "Python + JavaScript"
  planned:
    - "Rust"
    - "Go"
    - "Java"
```

## 使用流程
```yaml
initial_setup:
  - "使用subtree-add.sh添加到專案"
  - "執行setup-project.sh設置環境"
  - "配置pre-push-rules.yml"

daily_workflow:
  - "開發功能"
  - "Git push觸發自動檢查"
  - "使用AI prompts進行代碼審查"
  - "定期同步模板更新"

release_workflow:
  - "從develop創建release分支"
  - "更新版本號和CHANGELOG.md"
  - "推送release分支觸發自動化"
  - "完成Git Flow合併"
```

## 配置參數
```yaml
pre_push_rules:
  structure:
    settings:
      - "fail_fast: boolean"
      - "verbose: boolean"
      - "timeout: integer"
      - "use_venv: boolean"
    language_sections:
      - "python"
      - "javascript"
      - "custom_checks"

release_config:
  structure:
    branch_patterns: ["release", "main", "master"]
    version_check:
      - "enabled: boolean"
      - "changelog_file: string"
    build:
      - "enabled: boolean"
      - "clean_before_build: boolean"
    testing:
      - "enabled: boolean"
      - "test_command: string"
    github:
      - "enabled: boolean"
      - "create_tag: boolean"
      - "create_release: boolean"
```

## 常見問題解決
```yaml
troubleshooting:
  pre_push_failures:
    - "檢查工具安裝"
    - "確認虛擬環境"
    - "檢查配置文件語法"
  release_failures:
    - "版本號不匹配"
    - "構建失敗"
    - "測試失敗"
    - "GitHub認證問題"
  subtree_issues:
    - "檢查git版本"
    - "確認路徑正確"
    - "檢查腳本權限"
```

## AI助手指導原則
```yaml
ai_guidelines:
  when_helping_with_setup:
    - "檢查專案類型"
    - "確認依賴工具"
    - "協助配置文件編寫"
  when_helping_with_release:
    - "確認版本號一致性"
    - "檢查CHANGELOG.md格式"
    - "驗證測試通過"
  when_troubleshooting:
    - "從錯誤信息定位問題"
    - "提供具體解決步驟"
    - "建議最佳實踐"
```

## 系統需求
```yaml
requirements:
  git: "2.7+"
  python: "3.8+"
  shell: "Bash (Windows可用Git Bash)"
  optional_tools:
    - "GitHub CLI (gh)"
    - "各語言的代碼檢查工具"
```

## 版本歷史
```yaml
version_history:
  v1.0.0:
    - "基本功能實現"
    - "Git hooks管理"
    - "AI提示模板"
    - "Git subtree集成"
```