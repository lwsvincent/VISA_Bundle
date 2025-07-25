# Template Project

> Unified multi-project collaboration development toolkit

## Overview

Template Project is a unified development toolkit designed for multi-person collaboration and multiple small projects, providing:

- 🤖 **AI Collaboration Templates**: Structured AI assistant interaction templates
- 🌲 **Git Subtree Integration**: Simplified cross-project tool management
- 🔧 **Smart Project Detection**: Automatic identification of Python, JavaScript project types
- 🚀 **Automated Release Management**: Complete Git Flow release process automation
- 💻 **Windows Batch Scripts**: Comprehensive development tool automation
- 📦 **One-Click Release**: Complete end-to-end release automation

## Quick Start

### 1. Add to Existing Project
```bash
# Add template project as subtree
./scripts/subtree_init.bat -rootpath /path/to/your/project

# Setup project environment
./scripts/create_venv.bat -local -dev
```

### 2. Immediate Usage
```bash
# Use AI prompt templates
cat docs/ai-context/CLAUDE_AI_INSTRUCTIONS.md

# Run one-click release
./scripts/release_project.bat
```

## Windows Batch Scripts (scripts/)

### 🔧 Environment Management

#### create_venv.bat - Create Virtual Environment
```batch
REM Basic usage - create default .venv environment
create_venv.bat

REM Create local environment (.venv)
create_venv.bat -local

REM Create test environment (test-venv)
create_venv.bat -test

REM Create environment with development dependencies
create_venv.bat -local -dev
create_venv.bat -test -dev
```

#### setup_test_env.bat - Setup Test Environment
```batch
REM Setup test environment
setup_test_env.bat

REM Setup environment named 'test'
setup_test_env.bat test
```

#### cleanup_build.bat - Clean Build Files
```batch
REM Clean all build files and cache
cleanup_build.bat
```

### 🧪 Testing and Quality Checks

#### run_tests.bat - Run Tests
```batch
REM Basic tests
run_tests.bat

REM Full tests (with coverage)
run_tests.bat full

REM Use global Python environment
run_tests.bat -global
run_tests.bat full -global

REM Specify virtual environment
run_tests.bat -venv myenv
run_tests.bat -testvenv mytest
run_tests.bat full -venv custom_env

REM Combined usage
run_tests.bat full -testvenv production_test
```

### 📦 Build and Installation

#### build_wheel.bat - Build Wheel Package
```batch
REM Build wheel package (automatically creates and manages virtual environment)
build_wheel.bat
```

#### install_wheel.bat - Install Wheel Package
```batch
REM Install to global environment
install_wheel.bat --global

REM Install to specified virtual environment
install_wheel.bat --venv C:\path\to\venv
install_wheel.bat --venv .venv

REM Auto-find and install to nearest virtual environment
install_wheel.bat
```

### 🔖 Version Management

#### get_version.bat - Get Version Information
```batch
REM Get version from pyproject.toml
get_version.bat -pyproject

REM Get version from CHANGELOG.md
get_version.bat -changelog

REM Check if CHANGELOG.md has Unreleased section
get_version.bat -changelog -hasunreleased

REM Get latest version from Git tags
get_version.bat -github_latest_tag
```

#### update_version.bat - Update Version Number
```batch
REM Update version to 1.2.3
update_version.bat 1.2.3
```

#### create_tag.bat - Create Git Tag
```batch
REM Manually specify version
create_tag.bat 1.2.3

REM Auto-read version from pyproject.toml
create_tag.bat
```

### 🌿 Git Branch Management

#### change_branch.bat - Switch Branch
```batch
REM Switch to existing branch
change_branch.bat main
change_branch.bat develop

REM Create and switch to new branch
change_branch.bat feature/new-feature
```

#### delete_branch.bat - Delete Branch
```batch
REM Delete local branch
delete_branch.bat feature/old-feature

REM Delete local and remote branch
delete_branch.bat feature/old-feature --remote
```

#### merge_to_main.bat - Merge to Main Branch
```batch
REM Merge current branch to main
merge_to_main.bat
```

### 🚀 Release Management

#### release_project.bat - Automated Complete Release Process 🌟
```batch
REM Fully automated release process (recommended)
release_project.bat

REM Support version increment type parameters
release_project.bat -patch    # Increment patch version (default)
release_project.bat -minor    # Increment minor version
release_project.bat -major    # Increment major version
```
**Features**: Complete end-to-end release automation, including all steps:
- Check uncommitted changes and branch status
- Automatically calculate new version number (supports major/minor/patch increment)
- Version validation and comparison
- **Update version files BEFORE wheel build** (ensures updated documentation)
- Automatic build and test with updated version
- Create GitHub release and tags
- Merge to main branch and cleanup release branch
- **Automatic rollback on failure** - reverts all changes if release fails

#### push_to_release.bat - Push to Release Branch
```batch
REM Push to release branch (automatically copy wheel files and documentation)
push_to_release.bat
```

#### release_to_remote.bat - Create GitHub Release
```batch
REM Create GitHub release
release_to_remote.bat 1.2.3
```

#### release_to_testmatrix.bat - Release to TestMatrix
```batch
REM Release to TestMatrix repository
release_to_testmatrix.bat
```

### 🌲 Subtree Management

#### subtree_init.bat - Initialize Subtree
```batch
REM Initialize from project root directory
subtree_init.bat

REM Specify project root directory from any location
subtree_init.bat -rootpath "E:\TestMatrix\my_project"
```

#### subtree_init_all.bat - Initialize Subtree for Multiple Folders 🌟
```batch
REM Initialize subtree for single folder
subtree_init_all.bat -rootpath "E:\TestMatrix\my_project"

REM Scan subfolders and initialize subtree for each (depth 1)
subtree_init_all.bat -subfolder "E:\TestMatrix\projects"

REM Scan subfolders from specific root path
subtree_init_all.bat -subfolder "E:\TestMatrix\projects" -rootpath "E:\TestMatrix"
```

#### subtree_pull.bat - Update Subtree
```batch
REM Auto-find project root directory and update
subtree_pull.bat

REM Specify project root directory
subtree_pull.bat -rootpath "E:\TestMatrix\my_project"
```

#### subtree_pull_all.bat - Update Subtree for Multiple Folders 🌟
```batch
REM Update subtree for single folder
subtree_pull_all.bat -rootpath "E:\TestMatrix\my_project"

REM Scan subfolders and update subtree for each (depth 1)
subtree_pull_all.bat -subfolder "E:\TestMatrix\projects"

REM Scan subfolders from specific root path
subtree_pull_all.bat -subfolder "E:\TestMatrix\projects" -rootpath "E:\TestMatrix"
```

## Key Features

### 🧠 AI Collaboration Templates
- **Code Review**: Security, performance, quality check templates
- **Test Generation**: Unit tests, integration tests, E2E tests
- **Documentation Generation**: API docs, user guides, technical documentation

### 📁 Smart Project Adaptation
- Automatic project type detection (Python, JavaScript, mixed)
- Generate corresponding configuration files
- Create project-specific AI context

### 💻 Windows Batch Script Features
- **UTF-8 Encoding Support**: Correctly handles Chinese and special characters
- **Directory Protection**: All scripts maintain original working directory after execution
- **Virtual Environment Management**: Automatically creates and manages Python virtual environments
- **Error Handling**: Complete error checking and friendly error messages
- **Parameterization**: Flexible command-line parameter support

## Directory Structure

```
template_project/
├── scripts/                   # Windows batch scripts
│   ├── build_wheel.bat        # Build wheel package
│   ├── cleanup_build.bat      # Clean build files
│   ├── create_tag.bat         # Create Git tag
│   ├── create_venv.bat        # Create virtual environment
│   ├── get_version.bat        # Get version information
│   ├── install_wheel.bat      # Install wheel package
│   ├── release_project.bat    # 🌟 Automated complete release process
│   ├── release_to_remote.bat  # Create GitHub release
│   ├── run_tests.bat          # Run tests
│   ├── setup_test_env.bat     # Setup test environment
│   ├── subtree_init.bat       # Initialize Subtree
│   ├── subtree_init_all.bat   # 🌟 Initialize Subtree for Multiple Folders
│   ├── subtree_pull.bat       # Update Subtree
│   ├── subtree_pull_all.bat   # 🌟 Update Subtree for Multiple Folders
│   ├── update_version.bat     # Update version number
│   └── ... (other scripts)
├── config/                    # Configuration files
│   └── release-config.yml     # Release configuration
├── docs/                      # Documentation directory
│   ├── user-guides/           # User guides
│   │   ├── quick-start.md     # Quick start
│   │   ├── release-guide.md   # Release guide
│   │   ├── subtree-guide.md   # Subtree guide
│   │   └── development-best-practices.md # Development best practices
│   └── ai-context/            # AI assistant documentation
│       ├── PROJECT_PLAN.md    # Project plan
│       ├── RELEASE_PLAN.md    # Release plan
│       ├── AI-ASSISTED-RELEASE-WORKFLOW.md # AI-assisted release workflow
│       ├── TEMPLATE_PROJECT_CONTEXT.md # System context
│       ├── CLAUDE_AI_INSTRUCTIONS.md # AI instruction manual
│       └── STRUCTURED_WORKFLOWS.md # Structured workflows
└── templates/                 # Project templates
    ├── python-lib/
    └── web-app/
```

## Use Cases

### 🏢 Team Collaboration
- Unified code style and quality standards
- Standardized AI collaboration processes
- Consistent development tool configuration

### 📦 Multi-Project Management
- Cross-project tool and rule sharing
- Unified updates and maintenance
- Best practice propagation between projects

### 🔄 Git Flow Release Automation
- Standard Git Flow branch strategy support
- Automated release process (single release branch)
- GitHub integration: automatic tag and release creation
- Version consistency checking and wheel building

### 💻 Windows Development Environment
- Complete Windows batch script support
- Automatic virtual environment management
- Correct UTF-8 encoding handling
- Working directory protection

## Common Workflows

### 🚀 Automated Release Process (Recommended) ⭐
```batch
REM One-click complete release process
./scripts/release_project.bat

REM Specify version increment type
release_project.bat -patch    # Patch version (x.x.X)
release_project.bat -minor    # Minor version (x.X.0)
release_project.bat -major    # Major version (X.0.0)
```
**Features**: 
- Fully automated: 14 steps from check to release
- Version management: Smart calculation of new version numbers (major/minor/patch)
- **Build order optimization**: Version files updated before wheel build for accurate documentation
- **Automatic rollback**: Complete git rollback on any failure after version commit
- **Security**: Multi-layer validation and error rollback
- Completeness: Includes testing, building, tagging, GitHub release
- Intelligence: Automatic version detection and environment management
- Cleanup mechanism: Automatic deletion of release branch and cleanup of build files

### 🔄 Daily Development Workflow
```batch
REM 1. Create development environment
create_venv.bat -local -dev

REM 2. Run tests
run_tests.bat

REM 3. Clean build files
cleanup_build.bat

REM 4. Switch branch
change_branch.bat feature/new-feature
```

### 🌲 Subtree Management Workflow
```batch
REM 1. Initialize subtree for single project
./scripts/subtree_init.bat -rootpath "E:\TestMatrix\my_project"

REM 2. Update subtree for single project
./scripts/subtree_pull.bat -rootpath "E:\TestMatrix\my_project"

REM 3. Bulk operations for multiple projects
./scripts/subtree_init_all.bat -subfolder "E:\TestMatrix\all_projects"
./scripts/subtree_pull_all.bat -subfolder "E:\TestMatrix\all_projects"
```

## AI Collaboration Examples

### Code Review Template
```markdown
Please review the following code for security issues:

Code snippet:
[YOUR_CODE_HERE]

Key checks:
1. Are there potential security vulnerabilities
2. Is there a risk of sensitive information leakage
3. Is input validation sufficient
4. Are permission controls appropriate

Please provide specific suggestions and improvement plans.
```

### Test Generation Template
```markdown
Please generate complete unit tests for the following code:

Code snippet:
[YOUR_CODE_HERE]

Test requirements:
1. Cover all main functional paths
2. Include boundary condition tests
3. Test exception handling
4. Use appropriate testing framework
```

## Management Operations

### Subtree Management
```bash
# Add template project to new project
./scripts/subtree_init.bat -rootpath /path/to/target/project

# Get latest template project updates
./scripts/subtree_pull.bat -rootpath /path/to/target/project

# Batch operations for multiple projects
./scripts/subtree_init_all.bat -subfolder /path/to/projects
./scripts/subtree_pull_all.bat -subfolder /path/to/projects
```

### Batch Management
```batch
# Update all projects with subtree
./scripts/subtree_pull_all.bat -subfolder /path/to/projects

# Initialize subtree for all projects
./scripts/subtree_init_all.bat -subfolder /path/to/projects
```

## Supported Project Types

- ✅ **Python**: Django, Flask, FastAPI, general Python projects
- ✅ **JavaScript/TypeScript**: React, Vue, Node.js, Express
- ✅ **Mixed Projects**: Python + JavaScript
- 🔄 **Planned**: Rust, Go, Java

## System Requirements

### General Requirements
- Git 2.7+
- Corresponding development tools (Python: pip, JavaScript: npm/yarn)

### Windows Batch Scripts
- Windows 10/11
- PowerShell 5.1+ (for UTF-8 support)
- Python 3.7+
- Git for Windows

### Cross-Platform Support
- Primary: Windows batch scripts (scripts/)
- Full automation support for Windows environments

## Troubleshooting

### Common Issues
1. **Script permission issues**: Ensure Windows batch scripts are executable
2. **Release branch detection failure**: Ensure using single `release` branch (not `release/*`)
3. **Windows encoding issues**: Ensure files are saved with UTF-8 encoding
4. **Virtual environment issues**: Check Python environment and permission settings

### Debug Mode
```yaml
settings:
  fail_fast: false
  verbose: true
  timeout: 600
```

## Contributing

1. Fork this project
2. Create feature branch
3. Submit improvements
4. Create Pull Request

### Development Setup
```batch
git clone <your-fork>
cd template_project
./scripts/create_venv.bat -local -dev
./scripts/run_tests.bat
```

## Version History

- **v1.2.2**: Bulk subtree management and enhanced automation (current version)
  - **Added bulk subtree operations**: New subtree_init_all.bat and subtree_pull_all.bat
  - **Subfolder scanning**: Process multiple projects with -subfolder argument
  - **Error resilience**: Skip failed folders and continue processing others
  - **Comprehensive reporting**: Detailed success/failure statistics
  - **Smart validation**: Automatic checks for git repos and existing subtrees

- **v1.2.1**: Release process optimization and rollback mechanism
  - **Reordered build process**: Version files now updated before wheel build
  - **Added automatic rollback**: Complete git rollback on release failure
  - **Enhanced error handling**: All post-commit errors trigger rollback
  - **Improved build accuracy**: Documentation reflects correct version numbers
  - **Better step organization**: Reorganized from 12 to 14 logical steps

- **v1.2.0**: Release automation enhancements
  - Added version increment parameter support (major/minor/patch)
  - Implemented automatic version calculation and CHANGELOG.md updates
  - Improved UTF-8 encoding handling (UTF8NoBOM)
  - Added automatic release branch cleanup
  - Fixed GitHub CLI error handling

- **v1.1.0**: Complete Windows batch script support
  - Added 18 Windows batch scripts
  - UTF-8 encoding support
  - Automatic virtual environment management
  - Working directory protection
  - Complete error handling

- **v1.0.0**: Basic functionality implementation
  - AI prompt templates
  - Git subtree integration
  - Basic documentation

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contact

- Project Homepage: [GitHub Repository]
- Issue Reports: [GitHub Issues]
- Documentation: [docs/](docs/)

---

*Template Project - Making multi-project collaboration simpler and more standardized*