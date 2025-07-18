#!/bin/bash
# Setup template project in target project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    case $status in
        "success") echo -e "${GREEN}✓${NC} $message" ;;
        "error") echo -e "${RED}✗${NC} $message" ;;
        "warning") echo -e "${YELLOW}⚠${NC} $message" ;;
        "info") echo -e "${BLUE}ℹ${NC} $message" ;;
    esac
}

# Function to detect project type
detect_project_type() {
    local project_path="$1"
    
    if [ -f "$project_path/package.json" ]; then
        echo "javascript"
    elif [ -f "$project_path/requirements.txt" ] || [ -f "$project_path/setup.py" ] || [ -f "$project_path/pyproject.toml" ]; then
        echo "python"
    elif [ -f "$project_path/Cargo.toml" ]; then
        echo "rust"
    elif [ -f "$project_path/go.mod" ]; then
        echo "go"
    else
        echo "unknown"
    fi
}

# Function to create project-specific config
create_project_config() {
    local project_type="$1"
    local config_file="$2"
    
    case $project_type in
        "python")
            cat > "$config_file" << 'EOF'
# Pre-push rules configuration for Python project
settings:
  fail_fast: true
  verbose: true
  timeout: 300

python:
  enabled: true
  checks:
    - name: "flake8"
      command: "flake8"
      args: ". --exclude=build,dist,.git --max-line-length=100"
      required: true
      
    - name: "black"
      command: "black"
      args: "--check . --exclude='(build|dist|\\.git)'"
      required: true
      
    - name: "pytest"
      command: "pytest"
      args: "--tb=short"
      required: true
      condition: "file_exists:pytest.ini"

javascript:
  enabled: false

security:
  enabled: true
  checks:
    - name: "secret_scan"
      pattern: "(password|secret|key|token|api_key)"
      case_sensitive: false
      exclude_files: 
        - "*.md"
        - "*.txt"
        - "config/pre-push-rules.yml"

file_limits:
  max_file_size: "10MB"
  max_total_size: "100MB"
EOF
            ;;
        "javascript")
            cat > "$config_file" << 'EOF'
# Pre-push rules configuration for JavaScript/TypeScript project
settings:
  fail_fast: true
  verbose: true
  timeout: 300

python:
  enabled: false

javascript:
  enabled: true
  checks:
    - name: "eslint"
      command: "npx eslint"
      args: ". --ext .js,.jsx,.ts,.tsx"
      required: true
      
    - name: "typescript"
      command: "npx tsc"
      args: "--noEmit"
      required: true
      condition: "file_exists:tsconfig.json"
      
    - name: "jest"
      command: "npm test"
      args: ""
      required: true
      condition: "package_json_has:test"

security:
  enabled: true
  checks:
    - name: "secret_scan"
      pattern: "(password|secret|key|token|api_key)"
      case_sensitive: false
      exclude_files: 
        - "*.md"
        - "*.txt"
        - "config/pre-push-rules.yml"

file_limits:
  max_file_size: "10MB"
  max_total_size: "100MB"
EOF
            ;;
        *)
            # Use default configuration for unknown project types
            print_status "warning" "Unknown project type, using default configuration"
            ;;
    esac
}

print_status "info" "Setting up template project..."

# Check if we're in the template project directory
if [ ! -f ".git-hooks/pre-push" ]; then
    print_status "error" "Not in template project directory (missing .git-hooks/pre-push)"
    exit 1
fi

# Find the parent project directory
PARENT_PROJECT=$(dirname "$(pwd)")
PROJECT_TYPE=$(detect_project_type "$PARENT_PROJECT")

print_status "info" "Parent project: $PARENT_PROJECT"
print_status "info" "Detected project type: $PROJECT_TYPE"

# 1. Install git hooks
print_status "info" "Installing git hooks..."
if [ -f ".git-hooks/install-hooks.sh" ]; then
    cd "$PARENT_PROJECT" || exit 1
    bash "template_project/.git-hooks/install-hooks.sh"
    cd - > /dev/null || exit 1
    print_status "success" "Git hooks installed"
else
    print_status "error" "install-hooks.sh not found"
    exit 1
fi

# 2. Create project-specific configuration
print_status "info" "Creating project-specific configuration..."
if [ "$PROJECT_TYPE" != "unknown" ]; then
    create_project_config "$PROJECT_TYPE" "config/pre-push-rules.yml"
    print_status "success" "Project-specific configuration created"
fi

# 3. Create .gitignore entry for template project if needed
GITIGNORE_FILE="$PARENT_PROJECT/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    if ! grep -q "template_project" "$GITIGNORE_FILE"; then
        print_status "info" "Adding template_project to .gitignore is optional"
        print_status "info" "The template_project directory is meant to be committed with your project"
    fi
fi

# 4. Create CLAUDE.md if it doesn't exist
CLAUDE_MD="$PARENT_PROJECT/CLAUDE.md"
if [ ! -f "$CLAUDE_MD" ]; then
    print_status "info" "Creating CLAUDE.md for AI context..."
    cat > "$CLAUDE_MD" << EOF
# AI Context for $(basename "$PARENT_PROJECT")

## Project Overview
This project uses the template_project for standardized development workflows.

## Project Type
$PROJECT_TYPE

## Key Commands
- Run tests: \`pytest\` (Python) or \`npm test\` (JavaScript)
- Format code: \`black .\` (Python) or \`npx prettier --write .\` (JavaScript)
- Lint code: \`flake8 .\` (Python) or \`npx eslint .\` (JavaScript)

## Template Project Features
- Pre-push hooks for quality checks
- AI prompts for code review, testing, and documentation
- Standardized project structure

## Usage
- AI prompts are available in \`template_project/.ai-prompts/\`
- Configuration can be adjusted in \`template_project/config/pre-push-rules.yml\`
- Use \`template_project/scripts/subtree-sync.sh pull\` to get updates

## Custom Configuration
Project-specific settings have been applied based on detected project type: $PROJECT_TYPE
EOF
    print_status "success" "CLAUDE.md created"
fi

# 5. Show next steps
print_status "success" "Template project setup completed!"
echo ""
print_status "info" "Next steps:"
echo "1. Review and customize config/pre-push-rules.yml if needed"
echo "2. Test the pre-push hook: git push (or git commit and git push)"
echo "3. Explore AI prompts in .ai-prompts/ directory"
echo "4. Update template project: ./scripts/subtree-sync.sh pull $PARENT_PROJECT"
echo ""
print_status "info" "Available AI prompt templates:"
echo "- Code review: .ai-prompts/code-review.md"
echo "- Testing: .ai-prompts/testing.md"
echo "- Documentation: .ai-prompts/documentation.md"
echo ""
print_status "info" "Template project documentation:"
echo "- Project plan: PROJECT_PLAN.md"
echo "- Quick start: docs/quick-start.md (when available)"

# 6. Validate installation
print_status "info" "Validating installation..."
if [ -f "$PARENT_PROJECT/.git/hooks/pre-push" ]; then
    print_status "success" "Pre-push hook installed correctly"
else
    print_status "warning" "Pre-push hook not found, hooks may not work"
fi

if [ -f "config/pre-push-rules.yml" ]; then
    print_status "success" "Configuration file exists"
else
    print_status "warning" "Configuration file missing"
fi

print_status "success" "Setup validation completed!"