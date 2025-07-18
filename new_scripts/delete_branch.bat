@echo off
REM Script to delete a branch (local and remote)
REM Usage: delete_branch.bat <branch_name>

if "%1"=="" (
    echo Usage: delete_branch.bat ^<branch_name^>
    echo Example: delete_branch.bat feature/old-feature
    echo.
    echo This script will delete both local and remote branches.
    exit /b 1
)

set BRANCH_NAME=%1

REM Check if trying to delete protected branches
if /i "%BRANCH_NAME%"=="main" (
    echo ERROR: Cannot delete 'main' branch - it is protected
    exit /b 1
)

if /i "%BRANCH_NAME%"=="master" (
    echo ERROR: Cannot delete 'master' branch - it is protected
    exit /b 1
)

REM Get current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i

REM Check if we're trying to delete the current branch
if /i "%BRANCH_NAME%"=="%CURRENT_BRANCH%" (
    echo ERROR: Cannot delete branch '%BRANCH_NAME%' - you are currently on this branch
    echo Switch to another branch first using: change_branch.bat ^<other_branch^>
    exit /b 1
)

echo.
echo ================================
echo         WARNING: DANGEROUS OPERATION!
echo ================================
echo This will PERMANENTLY DELETE both LOCAL and REMOTE branches:
echo   Branch: %BRANCH_NAME%
echo   Local:  Will be deleted from your local repository
echo   Remote: Will be deleted from origin (this affects all team members)
echo.
echo This action CANNOT be undone!
echo ================================
echo.
set /p CONFIRM=Are you sure you want to delete branch '%BRANCH_NAME%'? (Y/N): 
if /i not "%CONFIRM%"=="Y" (
    echo Operation cancelled.
    exit /b 0
)
echo.
echo Proceeding with deletion of branch '%BRANCH_NAME%'...

REM Check if branch exists locally
git show-ref --verify --quiet refs/heads/%BRANCH_NAME%
if %ERRORLEVEL% == 0 (
    echo Deleting local branch '%BRANCH_NAME%'...
    git branch -D %BRANCH_NAME%
    if %ERRORLEVEL% == 0 (
        echo Local branch '%BRANCH_NAME%' deleted successfully
    ) else (
        echo Failed to delete local branch '%BRANCH_NAME%'
        exit /b 1
    )
) else (
    echo Local branch '%BRANCH_NAME%' does not exist
)

REM Delete remote branch
echo Checking if remote branch exists...
git ls-remote --heads origin %BRANCH_NAME% | find "%BRANCH_NAME%" >nul
if %ERRORLEVEL% == 0 (
    echo Deleting remote branch '%BRANCH_NAME%'...
    git push origin --delete %BRANCH_NAME%
    if %ERRORLEVEL% == 0 (
        echo Remote branch '%BRANCH_NAME%' deleted successfully
    ) else (
        echo Failed to delete remote branch '%BRANCH_NAME%'
        exit /b 1
    )
) else (
    echo Remote branch '%BRANCH_NAME%' does not exist
)

echo Local and remote branch deletion completed.