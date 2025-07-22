@echo off
REM Script to merge current branch to main
REM Usage: merge_to_main.bat

echo Merging to main branch...

REM Get current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i

if "%CURRENT_BRANCH%"=="" (
    echo ERROR: Could not determine current branch
    exit /b 1
)

echo Current branch: %CURRENT_BRANCH%

REM Check if we're already on main
if /i "%CURRENT_BRANCH%"=="main" (
    echo Already on main branch
    exit /b 0
)

REM Check if there are uncommitted changes
git diff --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are uncommitted changes. Please commit them first.
    exit /b 1
)

git diff --cached --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are staged changes. Please commit them first.
    exit /b 1
)

REM Switch to main branch
echo Switching to main branch...
git checkout main

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to switch to main branch
    exit /b 1
)

REM Pull latest changes from main
echo Pulling latest changes from main...
git pull origin main

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to pull latest changes from main
    exit /b 1
)

REM Merge the feature branch
echo Merging %CURRENT_BRANCH% into main...
git merge %CURRENT_BRANCH%

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to merge %CURRENT_BRANCH% into main
    echo You may need to resolve conflicts manually
    exit /b 1
)

REM Push main branch
echo Pushing main branch to origin...
git push origin main

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push main branch
    exit /b 1
)

echo.
echo Successfully merged %CURRENT_BRANCH% into main!
echo Current branch: main
echo Previous branch: %CURRENT_BRANCH%