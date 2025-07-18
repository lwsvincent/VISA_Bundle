@echo off
setlocal enabledelayedexpansion
REM Script to pull updates from template_project subtree
REM Usage: subtree_pull.bat [-rootpath <path>]
REM This script can be run from anywhere and will find the project root

echo Pulling updates from template_project subtree...

REM Parse command line arguments
set PROJECT_ROOT=
set ROOTPATH_SPECIFIED=0

echo DEBUG: Processing arguments: %*

:parse_args
echo DEBUG: Current argument: "%~1"
if "%~1"=="" goto :args_done
if /i "%~1"=="-rootpath" (
    echo DEBUG: Found -rootpath argument
    set ROOTPATH_SPECIFIED=1
    if "%~2"=="" (
        echo ERROR: -rootpath requires a path argument
        exit /b 1
    )
    set PROJECT_ROOT=%~2
    echo DEBUG: Set PROJECT_ROOT to: %~2
    shift
    shift
    goto :parse_args
)
REM Skip unknown arguments
echo DEBUG: Skipping unknown argument: %~1
shift
goto :parse_args

:args_done
echo DEBUG: ROOTPATH_SPECIFIED=%ROOTPATH_SPECIFIED%
echo DEBUG: ROOTPATH_SPECIFIED with delayed expansion=!ROOTPATH_SPECIFIED!
echo DEBUG: PROJECT_ROOT=%PROJECT_ROOT%
echo DEBUG: About to check if !ROOTPATH_SPECIFIED!==0

REM If no rootpath specified, find project root by looking for pyproject.toml
if !ROOTPATH_SPECIFIED!==1 goto :validate_rootpath

echo DEBUG: Entering auto-detection branch - THIS SHOULD NOT HAPPEN
set SEARCH_DIR=%CD%

REM Check current directory first
if exist "%SEARCH_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%SEARCH_DIR%
    goto :found_root
)

REM Check parent directory
for %%i in ("%SEARCH_DIR%") do set PARENT_DIR=%%~dpi
set PARENT_DIR=%PARENT_DIR:~0,-1%
if exist "%PARENT_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%PARENT_DIR%
    goto :found_root
)

REM Check grandparent directory
for %%i in ("%PARENT_DIR%") do set GRANDPARENT_DIR=%%~dpi
set GRANDPARENT_DIR=%GRANDPARENT_DIR:~0,-1%
if exist "%GRANDPARENT_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%GRANDPARENT_DIR%
    goto :found_root
)

REM Check great-grandparent directory
for %%i in ("%GRANDPARENT_DIR%") do set GREAT_GRANDPARENT_DIR=%%~dpi
set GREAT_GRANDPARENT_DIR=%GREAT_GRANDPARENT_DIR:~0,-1%
if exist "%GREAT_GRANDPARENT_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%GREAT_GRANDPARENT_DIR%
    goto :found_root
)

echo ERROR: Project root not found (no pyproject.toml found)
echo Please run this script from within the project directory structure or use -rootpath
exit /b 1

:validate_rootpath
echo DEBUG: Entering rootpath validation branch
REM Rootpath was specified, validate it
echo DEBUG: Validating rootpath: !PROJECT_ROOT!
if not exist "!PROJECT_ROOT!" (
    echo ERROR: Specified root path does not exist: !PROJECT_ROOT!
    exit /b 1
)
echo DEBUG: Rootpath validation passed

:found_root
echo Found project root: !PROJECT_ROOT!
REM Save original working directory
set ORIGINAL_DIR=%CD%
cd /d "!PROJECT_ROOT!"

REM Check if we're in a git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Not in a git repository
    exit /b 1
)

REM Check for ongoing merge and clean up if needed
git merge --abort >nul 2>&1
if exist ".git\.MERGE_MSG.swp" (
    echo WARNING: Found merge swap file, removing it...
    del ".git\.MERGE_MSG.swp" >nul 2>&1
)

REM Check git status
git status --porcelain >nul 2>&1
echo Current git status checked

REM Fixed values for template_project
set REMOTE_URL=https://github.com/lwsvincent/template_project.git
set PREFIX=template_project
set BRANCH=master

echo Remote URL: %REMOTE_URL%
echo Prefix: %PREFIX%
echo Branch: %BRANCH%

REM Check if template_project directory exists
if not exist "%PROJECT_ROOT%\template_project" (
    echo ERROR: template_project directory does not exist at %PROJECT_ROOT%\template_project
    echo Please run subtree_init.bat first to initialize the subtree
    exit /b 1
)

REM Pull from subtree
echo Pulling from subtree...
git subtree pull --prefix=%PREFIX% %REMOTE_URL% %BRANCH% --squash -m "Update subtree template_project from %REMOTE_URL%"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to pull from subtree
    echo This might be due to merge conflicts or connection issues
    echo Checking if there are merge conflicts to resolve...
    
    REM Check for merge conflicts
    git status --porcelain | findstr "^UU\|^AA\|^DD" >nul
    if %ERRORLEVEL% equ 0 (
        echo.
        echo MERGE CONFLICTS DETECTED!
        echo Please resolve the conflicts manually:
        echo 1. Edit the conflicted files
        echo 2. Run: git add .
        echo 3. Run: git commit -m "Resolve subtree pull conflicts"
        echo.
        echo Current status:
        git status
        exit /b 1
    ) else (
        echo No merge conflicts detected, but pull failed
        exit /b 1
    )
)

REM Check if there are changes to commit
git diff --cached --quiet >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo Auto-committing subtree pull changes...
    git commit -m "Update template_project subtree from %REMOTE_URL%

    - Pulled latest changes from %BRANCH% branch
    - Updated template_project at %PROJECT_ROOT%\template_project
    - Auto-committed by subtree_pull.bat script"
    
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to commit subtree changes
        exit /b 1
    )
    
    echo Subtree changes committed successfully!
) else (
    echo No changes to commit (subtree already up to date)
)

REM Show what changed
echo.
echo Showing recent changes:
git log --oneline -5

echo.
echo ================================
echo SUBTREE PULL COMPLETED!
echo ================================
echo Template project has been updated at: %PROJECT_ROOT%\template_project
echo Changes have been automatically committed to your current branch.

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"