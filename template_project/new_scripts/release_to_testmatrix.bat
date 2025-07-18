@echo off
REM Script to release to TestMatrix repository
REM Usage: release_to_testmatrix.bat

echo Releasing to TestMatrix repository...

REM Find project root by looking for dist directory or pyproject.toml
set PROJECT_ROOT=
set SEARCH_DIR=%CD%

REM Check current directory first
if exist "%SEARCH_DIR%\dist" (
    set PROJECT_ROOT=%SEARCH_DIR%
    goto :found_root
)
if exist "%SEARCH_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%SEARCH_DIR%
    goto :found_root
)

REM Check parent directory
for %%i in ("%SEARCH_DIR%") do set PARENT_DIR=%%~dpi
set PARENT_DIR=%PARENT_DIR:~0,-1%
if exist "%PARENT_DIR%\dist" (
    set PROJECT_ROOT=%PARENT_DIR%
    goto :found_root
)
if exist "%PARENT_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%PARENT_DIR%
    goto :found_root
)

REM Check grandparent directory
for %%i in ("%PARENT_DIR%") do set GRANDPARENT_DIR=%%~dpi
set GRANDPARENT_DIR=%GRANDPARENT_DIR:~0,-1%
if exist "%GRANDPARENT_DIR%\dist" (
    set PROJECT_ROOT=%GRANDPARENT_DIR%
    goto :found_root
)
if exist "%GRANDPARENT_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%GRANDPARENT_DIR%
    goto :found_root
)

echo ERROR: Project root not found (no dist or pyproject.toml found)
exit /b 1

:found_root
echo Found project root: %PROJECT_ROOT%
REM Save original working directory
set ORIGINAL_DIR=%CD%
cd /d "%PROJECT_ROOT%"

REM Check if wheel file exists
if not exist "dist\*.whl" (
    echo ERROR: No wheel file found in dist directory. Run build_wheel.bat first.
    exit /b 1
)

REM Find the wheel file
for %%f in (dist\*.whl) do set WHEEL_FILE=%%f

echo Found wheel file: %WHEEL_FILE%

REM Check if TestMatrix remote exists
git remote | findstr "testmatrix" >nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: TestMatrix remote not found. Please add it first:
    echo git remote add testmatrix ^<testmatrix_repo_url^>
    exit /b 1
)

REM Get current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i

REM Push to TestMatrix remote
echo Pushing %CURRENT_BRANCH% to TestMatrix...
git push testmatrix %CURRENT_BRANCH%

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push to TestMatrix remote
    exit /b 1
)

REM Push tags to TestMatrix
echo Pushing tags to TestMatrix...
git push testmatrix --tags

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push tags to TestMatrix remote
    exit /b 1
)

REM Copy wheel to TestMatrix releases directory (if exists)
if exist "..\testmatrix\releases" (
    echo Copying wheel to TestMatrix releases directory...
    copy "%WHEEL_FILE%" "..\testmatrix\releases\"
    if %ERRORLEVEL% == 0 (
        echo Wheel copied to TestMatrix releases directory
    ) else (
        echo Warning: Failed to copy wheel to TestMatrix releases directory
    )
) else (
    echo Warning: TestMatrix releases directory not found at ..\testmatrix\releases
)

echo.
echo Successfully released to TestMatrix!
echo Branch: %CURRENT_BRANCH%
echo Wheel: %WHEEL_FILE%
echo Remote: testmatrix

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"