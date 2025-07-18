@echo off
setlocal enabledelayedexpansion

echo Starting git pull for all repositories in TestMatrix...
echo.

set "BASE_DIR=D:\D\TestMatrix"
set "SUCCESS_COUNT=0"
set "FAIL_COUNT=0"
set "FAILED_REPOS="

for /d %%i in ("%BASE_DIR%\*") do (
    if exist "%%i\.git" (
        echo [INFO] Processing repository: %%~ni
        pushd "%%i"
        
        echo   Checking git status...
        git status --porcelain >nul 2>&1
        if !errorlevel! neq 0 (
            echo   [ERROR] Not a valid git repository or git not available
            set /a FAIL_COUNT+=1
            set "FAILED_REPOS=!FAILED_REPOS! %%~ni"
        ) else (
            echo   Pulling latest changes...
            git pull
            if !errorlevel! equ 0 (
                echo   [SUCCESS] Pull completed successfully
                set /a SUCCESS_COUNT+=1
            ) else (
                echo   [ERROR] Pull failed
                set /a FAIL_COUNT+=1
                set "FAILED_REPOS=!FAILED_REPOS! %%~ni"
            )
        )
        
        popd
        echo.
    ) else (
        echo [SKIP] Directory %%~ni is not a git repository
        echo.
    )
)

echo ========================================
echo Git pull summary:
echo   Successful: !SUCCESS_COUNT! repositories
echo   Failed: !FAIL_COUNT! repositories
if !FAIL_COUNT! gtr 0 (
    echo   Failed repositories:!FAILED_REPOS!
)
echo ========================================

pause