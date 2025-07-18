@echo off
setlocal enabledelayedexpansion
REM Script to run tests with coverage
REM Usage: run_tests.bat [full] [-global] [-venv <env_name>] [-testvenv <test_env_name>]

REM Parse command line arguments
set TEST_MODE=
set USE_GLOBAL=0
set VENV_NAME=.venv
set TEST_VENV_NAME=test-venv
set VENV_SPECIFIED=0
set TESTVENV_SPECIFIED=0

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="full" (
    set TEST_MODE=full
    shift
    goto :parse_args
)
if /i "%~1"=="-global" (
    set USE_GLOBAL=1
    shift
    goto :parse_args
)
if /i "%~1"=="-venv" (
    set VENV_SPECIFIED=1
    REM Check if next argument exists and is not another flag
    if "%~2"=="" goto :venv_default
    if /i "%~2"=="-testvenv" goto :venv_default
    if /i "%~2"=="-global" goto :venv_default
    if /i "%~2"=="full" goto :venv_default
    set VENV_NAME=%~2
    shift
    shift
    goto :parse_args
    
    :venv_default
    set VENV_NAME=.venv
    shift
    goto :parse_args
)
if /i "%~1"=="-testvenv" (
    set TESTVENV_SPECIFIED=1
    REM Check if next argument exists and is not another flag
    if "%~2"=="" goto :testvenv_default
    if /i "%~2"=="-venv" goto :testvenv_default
    if /i "%~2"=="-global" goto :testvenv_default
    if /i "%~2"=="full" goto :testvenv_default
    set TEST_VENV_NAME=%~2
    shift
    shift
    goto :parse_args
    
    :testvenv_default
    set TEST_VENV_NAME=test-venv
    shift
    goto :parse_args
)
REM Skip unknown arguments
shift
goto :parse_args

:args_done

echo Running tests...

REM Find project root by looking for pyproject.toml or tests directory
set PROJECT_ROOT=
set SEARCH_DIR=%CD%

REM Check current directory first
if exist "%SEARCH_DIR%\tests" (
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
if exist "%PARENT_DIR%\tests" (
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
if exist "%GRANDPARENT_DIR%\tests" (
    set PROJECT_ROOT=%GRANDPARENT_DIR%
    goto :found_root
)
if exist "%GRANDPARENT_DIR%\pyproject.toml" (
    set PROJECT_ROOT=%GRANDPARENT_DIR%
    goto :found_root
)

echo ERROR: Project root not found (no tests or pyproject.toml found)
exit /b 1

:found_root
echo Found project root: %PROJECT_ROOT%
REM Save original working directory
set ORIGINAL_DIR=%CD%
cd /d "%PROJECT_ROOT%"
echo 123
REM Handle virtual environment activation
if %USE_GLOBAL%==1 (
    echo Using global Python environment
) else (
    REM Determine which virtual environment to use
    if %VENV_SPECIFIED%==1 (
        set ACTIVE_VENV=%VENV_NAME%
        echo Using specified virtual environment: %VENV_NAME%
        goto :venv_selected
    )
    if %TESTVENV_SPECIFIED%==1 (
        set ACTIVE_VENV=%TEST_VENV_NAME%
        echo Using specified test virtual environment: %TEST_VENV_NAME%
        goto :venv_selected
    )
    REM Default behavior: use .venv for basic tests, test-venv for full tests
    if /i "%TEST_MODE%"=="full" (
        set ACTIVE_VENV=%TEST_VENV_NAME%
        echo Using default test virtual environment: %TEST_VENV_NAME%
    ) else (
        set ACTIVE_VENV=%VENV_NAME%
        echo Using default virtual environment: %VENV_NAME%
    )
    
    :venv_selected
    REM Check if virtual environment exists
    if not exist "%PROJECT_ROOT%\!ACTIVE_VENV!\Scripts\activate.bat" (
        echo ERROR: Virtual environment '!ACTIVE_VENV!' not found at %PROJECT_ROOT%\!ACTIVE_VENV!
        echo Please create the virtual environment first or use -global flag
        exit /b 1
    )
    
    REM Activate virtual environment
    call "%PROJECT_ROOT%\!ACTIVE_VENV!\Scripts\activate.bat"
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to activate virtual environment '!ACTIVE_VENV!'
        exit /b 1
    )
    echo Virtual environment '!ACTIVE_VENV!' activated
)

REM Check if pytest is available
python -c "import pytest" 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: pytest not found. Make sure test dependencies are installed.
    exit /b 1
)

REM Run tests based on mode
if /i "%TEST_MODE%"=="full" (
    echo Running full test suite with coverage...
    python -m pytest tests/ -v --cov=. --cov-report=html --cov-report=term --cov-fail-under=80
) else (
    echo Running basic test suite...
    python -m pytest tests/ -v
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo ================================
    echo TEST FAILURES DETECTED!
    echo ================================
    echo Please fix the failing tests before proceeding with release.
    exit /b 1
)

echo.
echo ================================
echo ALL TESTS PASSED!
echo ================================

if /i "%TEST_MODE%"=="full" (
    echo Coverage report generated in htmlcov/
    echo Open htmlcov/index.html to view detailed coverage report
)

echo Tests completed successfully!

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"