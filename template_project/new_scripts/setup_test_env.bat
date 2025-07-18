@echo off
REM Script to create virtual environment and install dependencies
REM Usage: setup_test_env.bat [test]

set TEST_MODE=%1
set VENV_NAME=test_env

echo Setting up test environment...

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
exit /b 1

:found_root
echo Found project root: %PROJECT_ROOT%
REM Save original working directory
set ORIGINAL_DIR=%CD%
cd /d "%PROJECT_ROOT%"

REM Remove existing test environment
if exist "%VENV_NAME%" (
    echo Removing existing test environment...
    rmdir /s /q "%VENV_NAME%"
)

REM Create new virtual environment
echo Creating virtual environment '%VENV_NAME%'...
python -m venv "%VENV_NAME%"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create virtual environment
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call "%VENV_NAME%\Scripts\activate.bat"

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

if /i "%TEST_MODE%"=="test" (
    echo Installing test dependencies...
    REM Install test dependencies from pyproject.toml
    pip install -e .[test]
) else (
    echo Installing production dependencies...
    REM Install production dependencies
    pip install -e .
)

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install dependencies
    exit /b 1
)

echo.
echo Test environment setup completed successfully!
echo To activate: call %VENV_NAME%\Scripts\activate.bat
echo To deactivate: deactivate

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"