@echo off
setlocal enabledelayedexpansion
REM Script to initialize git subtree for template_project
REM Usage: subtree_init.bat [-rootpath <path>]
REM This script should be run from the project root or specify -rootpath

echo Initializing git subtree for template_project...

REM Parse command line arguments
set PROJECT_ROOT=
set ROOTPATH_SPECIFIED=0

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="-rootpath" (
    set ROOTPATH_SPECIFIED=1
    if "%~2"=="" (
        echo ERROR: -rootpath requires a path argument
        exit /b 1
    )
    set PROJECT_ROOT=%~2
    shift
    shift
    goto :parse_args
)
REM Skip unknown arguments
shift
goto :parse_args

:args_done

REM If no rootpath specified, use current directory
if %ROOTPATH_SPECIFIED%==0 (
    set PROJECT_ROOT=%CD%
)

echo Project root: %PROJECT_ROOT%

REM Check if the specified path exists
if not exist "%PROJECT_ROOT%" (
    echo ERROR: Specified root path does not exist: %PROJECT_ROOT%
    exit /b 1
)

REM Save original working directory
set ORIGINAL_DIR=%CD%
REM Change to the project root directory
cd /d "%PROJECT_ROOT%"

REM Check if we're in a git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Not in a git repository: %PROJECT_ROOT%
    exit /b 1
)

REM Check for uncommitted changes
git diff-index --quiet HEAD --
if %ERRORLEVEL% neq 0 (
    echo ERROR: Working tree has modifications. Cannot add subtree.
    echo Please commit or stash your changes first:
    echo   git add .
    echo   git commit -m "Your commit message"
    echo Or:
    echo   git stash
    echo.
    echo Current status:
    git status --porcelain
    exit /b 1
)

REM Fixed values for template_project
set REMOTE_URL=https://github.com/lwsvincent/template_project.git
set PREFIX=template_project

echo Remote URL: %REMOTE_URL%
echo Prefix: %PREFIX%

REM Check if template_project directory already exists
echo DEBUG: PROJECT_ROOT=!PROJECT_ROOT!
echo DEBUG: Checking if template_project exists...

REM Skip directory check for now to avoid hanging
echo DEBUG: Skipping directory check, proceeding with subtree add...
REM Add the subtree
echo Adding subtree...
git subtree add --prefix=%PREFIX% %REMOTE_URL% master --squash

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to add subtree
    exit /b 1
)

echo.
echo ================================
echo SUBTREE INITIALIZATION COMPLETE!
echo ================================
echo Template project has been added to: %PROJECT_ROOT%\template_project
echo You can now use subtree_pull.bat to update the subtree in the future.

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"