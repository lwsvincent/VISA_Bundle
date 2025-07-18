@echo off
REM Script to build wheel package
REM Usage: build_wheel.bat

echo Building wheel package...

REM Find project root by looking for pyproject.toml
set PROJECT_ROOT=
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

echo ERROR: pyproject.toml not found in current, parent, or grandparent directory
echo Current: %SEARCH_DIR%
echo Parent: %PARENT_DIR%
echo Grandparent: %GRANDPARENT_DIR%
exit /b 1

:found_root
echo Found project root: %PROJECT_ROOT%
REM Save original working directory
set ORIGINAL_DIR=%CD%
cd /d "%PROJECT_ROOT%"

REM Check for virtual environment, create if doesn't exist
set VENV_PATH=%PROJECT_ROOT%\.venv
if not exist "%VENV_PATH%\Scripts\activate.bat" (
    echo Virtual environment not found, creating one...
    call "%~dp0create_venv.bat" -local -dev
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to create virtual environment
        exit /b 1
    )
)

REM Activate virtual environment
echo Activating virtual environment...
call "%VENV_PATH%\Scripts\activate.bat"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to activate virtual environment
    exit /b 1
)

REM Clean previous builds
if exist "dist" (
    echo Cleaning previous builds...
    rmdir /s /q dist
)

if exist "build" (
    rmdir /s /q build
)

REM Ensure build tools are available
echo Ensuring build tools are available...
python -m pip install --upgrade pip build

REM Build wheel
echo Running: python -m build --wheel
python -m build --wheel

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build wheel
    exit /b 1
)

echo Wheel built successfully!
echo Built files:
dir dist\*.whl /b

echo.
echo Build completed successfully.

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"