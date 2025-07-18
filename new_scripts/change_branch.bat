@echo off
REM Script to change to existing branch or create new branch
REM Usage: change_branch.bat <branch_name>

if "%1"=="" (
    echo Usage: change_branch.bat ^<branch_name^>
    echo Example: change_branch.bat feature/new-feature
    exit /b 1
)

set BRANCH_NAME=%1

echo Checking if branch '%BRANCH_NAME%' exists...

REM Check if branch exists locally
git show-ref --verify --quiet refs/heads/%BRANCH_NAME%
if %ERRORLEVEL% == 0 (
    echo Branch '%BRANCH_NAME%' exists locally. Switching to it...
    git checkout %BRANCH_NAME%
) else (
    REM Check if branch exists on remote
    git ls-remote --heads origin %BRANCH_NAME% | find "%BRANCH_NAME%" >nul
    if %ERRORLEVEL% == 0 (
        echo Branch '%BRANCH_NAME%' exists on remote. Creating local branch and switching...
        git checkout -b %BRANCH_NAME% origin/%BRANCH_NAME%
    ) else (
        echo Branch '%BRANCH_NAME%' does not exist. Creating new branch...
        git checkout -b %BRANCH_NAME%
    )
)

if %ERRORLEVEL% == 0 (
    echo Successfully switched to branch '%BRANCH_NAME%'
) else (
    echo Failed to switch to branch '%BRANCH_NAME%'
    exit /b 1
)