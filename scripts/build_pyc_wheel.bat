@echo off
setlocal enabledelayedexpansion

REM =============================================================================
REM build_pyc_wheel.bat
REM Builds a cp311-cp311-win_amd64 wheel with visa_bundle .py files compiled to
REM .pyc and removed, with .pyi stubs retained for IDE support.
REM =============================================================================

set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
set VENV_PYTHON=%PROJECT_ROOT%\.venv\Scripts\python.exe
set SRC_PKG=%PROJECT_ROOT%\src\visa_bundle

echo ============================================================
echo  VISA Bundle - PYC Wheel Build
echo ============================================================
echo.

REM --- Validate Python venv ---
if not exist "%VENV_PYTHON%" (
    echo [ERROR] Virtual environment not found at: %VENV_PYTHON%
    echo         Run: call template_project\scripts\create_venv.bat -local -dev
    exit /b 1
)

echo [INFO] Using Python: %VENV_PYTHON%
"%VENV_PYTHON%" --version

REM --- Ensure wheel is installed ---
echo.
echo [STEP 1] Checking build dependencies...
"%VENV_PYTHON%" -c "import wheel" 2>nul
if errorlevel 1 (
    echo [INFO] Installing wheel...
    "%VENV_PYTHON%" -m pip install wheel
    if errorlevel 1 (
        echo [ERROR] Failed to install wheel
        exit /b 1
    )
)

REM --- Ensure mypy (stubgen) is installed ---
"%VENV_PYTHON%" -m mypy --version 2>nul
if errorlevel 1 (
    echo [INFO] Installing mypy for stubgen...
    "%VENV_PYTHON%" -m pip install mypy
    if errorlevel 1 (
        echo [ERROR] Failed to install mypy
        exit /b 1
    )
)
echo [OK] Build dependencies ready.

REM --- Run stubgen on modules that will be compiled ---
echo.
echo [STEP 2] Generating .pyi stubs...

set STUB_OUT=%PROJECT_ROOT%\build\_stubs_temp
if exist "%STUB_OUT%" rmdir /s /q "%STUB_OUT%"
mkdir "%STUB_OUT%"

set STUBGEN=%PROJECT_ROOT%\.venv\Scripts\stubgen.exe

REM Run stubgen on all protected files
"%STUBGEN%" ^
    "%SRC_PKG%\Setting.py" ^
    "%SRC_PKG%\VISA.py" ^
    -o "%STUB_OUT%"
if errorlevel 1 (
    echo [WARNING] stubgen encountered issues - some stubs may be incomplete
)

REM --- Copy generated stubs to source tree ---
set STUB_BASE=%STUB_OUT%\visa_bundle\src\visa_bundle

REM root package stubs
for %%F in ("%STUB_BASE%\*.pyi") do (
    copy /y "%%F" "%SRC_PKG%\%%~nxF" >nul
    echo [INFO] Copied: %%~nxF
)

echo [OK] Stub generation complete.

REM --- Ensure py.typed marker exists ---
if not exist "%SRC_PKG%\py.typed" (
    type nul > "%SRC_PKG%\py.typed"
    echo [INFO] Created py.typed marker
)

REM --- Clean previous build artifacts ---
echo.
echo [STEP 3] Cleaning previous build...
if exist "%PROJECT_ROOT%\build\lib" rmdir /s /q "%PROJECT_ROOT%\build\lib"
if exist "%PROJECT_ROOT%\build\bdist.win-amd64" rmdir /s /q "%PROJECT_ROOT%\build\bdist.win-amd64"
echo [OK] Build directory cleaned.

REM --- Build the wheel ---
echo.
echo [STEP 4] Building cp311-cp311-win_amd64 wheel...
cd /d "%PROJECT_ROOT%"
"%VENV_PYTHON%" setup.py bdist_wheel
if errorlevel 1 (
    echo [ERROR] Wheel build failed
    exit /b 1
)
echo [OK] Wheel build complete.

REM --- Find and verify wheel ---
echo.
echo [STEP 5] Verifying wheel contents...

set WHEEL_FILE=
for /f "delims=" %%F in ('dir /b /o-d "%PROJECT_ROOT%\dist\*cp311*.whl" 2^>nul') do (
    if not defined WHEEL_FILE set "WHEEL_FILE=%PROJECT_ROOT%\dist\%%F"
)

if not defined WHEEL_FILE (
    echo [ERROR] No cp311 wheel found in dist\
    exit /b 1
)

echo [INFO] Wheel: %WHEEL_FILE%
echo.
echo --- Wheel Contents ---
"%VENV_PYTHON%" -m zipfile -l "%WHEEL_FILE%"
echo.

REM Check that .pyc files ARE present
echo [CHECK] Verifying .pyc files present...
"%VENV_PYTHON%" -m zipfile -l "%WHEEL_FILE%" | findstr ".pyc"
if errorlevel 1 (
    echo [ERROR] No .pyc files found in wheel!
    exit /b 1
)
echo [OK] .pyc files confirmed in wheel.

REM Check that .pyi stubs ARE present
echo.
echo [CHECK] Verifying .pyi stub files present...
"%VENV_PYTHON%" -m zipfile -l "%WHEEL_FILE%" | findstr ".pyi"
if errorlevel 1 (
    echo [ERROR] No .pyi stub files found in wheel!
    exit /b 1
)
echo [OK] .pyi stubs confirmed in wheel.

REM Check that bare .py are NOT present (except __init__)
echo.
echo [CHECK] Verifying IP protection...
"%VENV_PYTHON%" -m zipfile -l "%WHEEL_FILE%" | findstr /i "visa_bundle" | findstr /v "__init__" | findstr /v ".pyi" | findstr /v "__pycache__" | findstr /v "py.typed" | findstr ".py"
if not errorlevel 1 (
    echo [WARNING] Unexpected .py files found in package - check above
) else (
    echo [OK] No unprotected .py files in package.
)

echo.
echo ============================================================
echo  Build SUCCESS: %WHEEL_FILE%
echo ============================================================
endlocal
exit /b 0
