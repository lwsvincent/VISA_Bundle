@echo off
REM Script to clean up build artifacts and test environment
REM Usage: cleanup_build.bat

echo Cleaning up build artifacts and test environment...

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

echo Warning: pyproject.toml not found. Cleaning current directory.
set PROJECT_ROOT=%SEARCH_DIR%

:found_root
echo Cleaning project at: %PROJECT_ROOT%
REM Save original working directory
set ORIGINAL_DIR=%CD%
cd /d "%PROJECT_ROOT%"

REM Remove build directories
if exist "build" (
    echo Removing build directory...
    rmdir /s /q build
)

if exist "dist" (
    echo Removing dist directory...
    rmdir /s /q dist
)

REM Remove egg-info directories (root level)
for /d %%d in (*.egg-info) do (
    if exist "%%d" (
        echo Removing %%d...
        rmdir /s /q "%%d"
    )
)

REM Remove egg-info directories in src/
if exist "src" (
    for /d %%d in (src\*.egg-info) do (
        if exist "%%d" (
            echo Removing %%d...
            rmdir /s /q "%%d"
        )
    )
)

REM Remove any nested egg-info directories
for /f "tokens=*" %%d in ('dir /s /b /a:d *.egg-info 2^>nul') do (
    if exist "%%d" (
        echo Removing %%d...
        rmdir /s /q "%%d"
    )
)

REM Remove test environment
if exist "test_env" (
    echo Removing test environment...
    rmdir /s /q test_env
)

REM Remove coverage files
if exist ".coverage" (
    echo Removing coverage data...
    del .coverage
)

if exist "htmlcov" (
    echo Removing coverage HTML report...
    rmdir /s /q htmlcov
)

REM Remove pytest cache
if exist ".pytest_cache" (
    echo Removing pytest cache...
    rmdir /s /q .pytest_cache
)

REM Remove Python cache
for /d /r %%d in (__pycache__) do (
    if exist "%%d" (
        echo Removing %%d...
        rmdir /s /q "%%d"
    )
)

REM Remove temporary files
if exist "release_notes.tmp" (
    del release_notes.tmp
)

REM Remove any .pyc files
for /r %%f in (*.pyc) do (
    if exist "%%f" (
        del "%%f"
    )
)

echo.
echo Cleanup completed!
echo Removed:
echo - build/ directory
echo - dist/ directory
echo - *.egg-info/ directories
echo - test_env/ directory
echo - Coverage files (.coverage, htmlcov/)
echo - pytest cache (.pytest_cache/)
echo - Python cache (__pycache__/)
echo - Temporary files

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"