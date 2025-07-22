@echo off
setlocal enabledelayedexpansion
REM Script to create virtual environment
REM Usage: create_venv.bat [-local] [-test] [-dev]
REM   -local: Creates .venv folder
REM   -test: Creates test-venv folder
REM   -dev: Install dev dependencies

set VENV_NAME=.venv
set PYTHON_EXE=python
set INSTALL_DEV=0

REM Parse arguments
:parse_args
if "%~1"=="" goto :done_parsing
if /i "%~1"=="-local" (
    set VENV_NAME=.venv
    shift
    goto :parse_args
)
if /i "%~1"=="-test" (
    set VENV_NAME=test-venv
    shift
    goto :parse_args
)
if /i "%~1"=="-dev" (
    set INSTALL_DEV=1
    shift
    goto :parse_args
)
echo ERROR: Unknown argument: %~1
echo Usage: create_venv.bat [-local] [-test] [-dev]
echo   -local: Creates .venv folder (default)
echo   -test: Creates test-venv folder
echo   -dev: Install dev dependencies
exit /b 1

:done_parsing

echo Creating virtual environment: %VENV_NAME%

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

echo ERROR: Project root not found (no pyproject.toml found)
echo Searched in:
echo   %SEARCH_DIR%
echo   %PARENT_DIR%
echo   %GRANDPARENT_DIR%
exit /b 1

:found_root
echo Found project root: %PROJECT_ROOT%
REM Save original working directory
set ORIGINAL_DIR=%CD%
cd /d "%PROJECT_ROOT%"

REM Set full path for virtual environment
set VENV_PATH=%PROJECT_ROOT%\%VENV_NAME%

REM Check if virtual environment already exists
if exist "%VENV_PATH%" (
    echo Virtual environment already exists at: %VENV_PATH%
    echo.
    echo What would you like to do?
    echo   1. Delete and reinstall
    echo   2. Cancel operation
    echo.
    set /p CHOICE="Enter your choice (1 or 2): "
    
    if "!CHOICE!"=="1" (
        echo Deleting existing virtual environment...
        rmdir /s /q "%VENV_PATH%"
        if !ERRORLEVEL! neq 0 (
            echo ERROR: Failed to delete existing virtual environment
            exit /b 1
        )
        echo Existing virtual environment deleted successfully.
        echo.
    ) else if "!CHOICE!"=="2" (
        echo Operation cancelled.
        exit /b 0
    ) else (
        echo Invalid choice. Operation cancelled.
        exit /b 1
    )
)

REM Create virtual environment
echo Creating virtual environment at: %VENV_PATH%
%PYTHON_EXE% -m venv "%VENV_PATH%"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create virtual environment
    exit /b 1
)

echo.
echo Virtual environment created successfully!
echo Location: %VENV_PATH%
echo.

REM Install dependencies
echo Installing dependencies from pyproject.toml...
echo DEBUG: INSTALL_DEV=!INSTALL_DEV!
if !INSTALL_DEV!==1 (
    echo Installing with dev dependencies...
    "%VENV_PATH%\Scripts\pip" install -e ".[dev]"
) else (
    echo Installing core dependencies...
    "%VENV_PATH%\Scripts\pip" install -e .
)

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install dependencies
    exit /b 1
)

echo.
echo Setup complete!
echo To activate the virtual environment, run:
if "%VENV_NAME%"==".venv" (
    echo   %PROJECT_ROOT%\.venv\Scripts\activate
) else (
    echo   %PROJECT_ROOT%\%VENV_NAME%\Scripts\activate
)
echo.
echo Dependencies installed from pyproject.toml
if !INSTALL_DEV!==1 (
    echo   - Core dependencies
    echo   - Dev dependencies (pytest, flake8, black, pytest-cov)
) else (
    echo   - Core dependencies only
    echo   - To install dev dependencies later: pip install -e ".[dev]"
)

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"