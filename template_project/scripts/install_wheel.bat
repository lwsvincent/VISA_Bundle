@echo off
REM Script to install wheel package
REM Usage: install_wheel.bat [--global] [--venv path]

set GLOBAL_INSTALL=0
set CUSTOM_VENV=

REM Parse arguments
:parse_args
if "%~1"=="" goto :done_parsing
if /i "%~1"=="--global" (
    set GLOBAL_INSTALL=1
    shift
    goto :parse_args
)
if /i "%~1"=="--venv" (
    set CUSTOM_VENV=%~2
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:done_parsing

echo Installing wheel package...

REM Find project root by looking for pyproject.toml or dist directory
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

REM Check if dist directory exists
if not exist "dist" (
    echo ERROR: dist directory not found. Run build_wheel.bat first.
    exit /b 1
)

REM Find the wheel file
for %%f in (dist\*.whl) do set WHEEL_FILE=%%f

if "%WHEEL_FILE%"=="" (
    echo ERROR: No wheel file found in dist directory
    exit /b 1
)

echo Found wheel file: %WHEEL_FILE%

REM Determine Python executable to use
set PYTHON_EXE=python
set PIP_EXE=pip
set INSTALL_LOCATION=

if %GLOBAL_INSTALL%==1 (
    echo Installing to global Python environment...
    set INSTALL_LOCATION=global Python
) else if not "%CUSTOM_VENV%"=="" (
    echo Using custom virtual environment: %CUSTOM_VENV%
    if not exist "%CUSTOM_VENV%\Scripts\python.exe" (
        echo ERROR: Virtual environment not found at %CUSTOM_VENV%
        exit /b 1
    )
    set PYTHON_EXE="%CUSTOM_VENV%\Scripts\python.exe"
    set PIP_EXE="%CUSTOM_VENV%\Scripts\pip.exe"
    set INSTALL_LOCATION=%CUSTOM_VENV%
) else (
    REM Search for .venv directory
    set VENV_PATH=
    
    REM Check current directory
    if exist "%PROJECT_ROOT%\.venv\Scripts\python.exe" (
        set VENV_PATH=%PROJECT_ROOT%\.venv
        goto :found_venv
    )
    
    REM Check parent directory
    for %%i in ("%PROJECT_ROOT%") do set PARENT_DIR=%%~dpi
    set PARENT_DIR=%PARENT_DIR:~0,-1%
    if exist "%PARENT_DIR%\.venv\Scripts\python.exe" (
        set VENV_PATH=%PARENT_DIR%\.venv
        goto :found_venv
    )
    
    REM Check grandparent directory
    for %%i in ("%PARENT_DIR%") do set GRANDPARENT_DIR=%%~dpi
    set GRANDPARENT_DIR=%GRANDPARENT_DIR:~0,-1%
    if exist "%GRANDPARENT_DIR%\.venv\Scripts\python.exe" (
        set VENV_PATH=%GRANDPARENT_DIR%\.venv
        goto :found_venv
    )
    
    echo ERROR: No .venv found and --global not specified.
    echo.
    echo Options:
    echo   1. Use --global to install to global Python environment
    echo   2. Use --venv ^<path^> to specify a virtual environment
    echo   3. Create a .venv in project root, parent, or grandparent directory
    echo.
    echo Example: install_wheel.bat --global
    echo Example: install_wheel.bat --venv C:\path\to\venv
    exit /b 1
    
    :found_venv
    echo Found virtual environment: %VENV_PATH%
    set PYTHON_EXE="%VENV_PATH%\Scripts\python.exe"
    set PIP_EXE="%VENV_PATH%\Scripts\pip.exe"
    set INSTALL_LOCATION=%VENV_PATH%
)

:install_wheel
REM Install wheel
echo Installing wheel: %WHEEL_FILE%
echo Target: %INSTALL_LOCATION%
%PIP_EXE% install "%WHEEL_FILE%" --force-reinstall

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install wheel
    exit /b 1
)

echo.
echo Wheel installed successfully!
echo Installed: %WHEEL_FILE%
echo Location: %INSTALL_LOCATION%

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"