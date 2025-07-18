@echo off
setlocal enabledelayedexpansion

:: Version Information Retrieval Tool
:: Usage: get_version.bat [-changelog] [-pyproject] [-github_latest_tag] [-changelog -hasunreleased]

set "MODE="
set "CHECK_UNRELEASED="

:: Parse command line arguments
:parse_args
if "%~1"=="" goto main
if /i "%~1"=="-changelog" (
    set "MODE=changelog"
    if /i "%~2"=="-hasunreleased" (
        set "CHECK_UNRELEASED=true"
        shift
    )
    shift
    goto parse_args
)
if /i "%~1"=="-pyproject" (
    set "MODE=pyproject"
    shift
    goto parse_args
)
if /i "%~1"=="-github_latest_tag" (
    set "MODE=github"
    shift
    goto parse_args
)
shift
goto parse_args

:main
if "%MODE%"=="" (
    echo Usage: get_version.bat [-changelog] [-pyproject] [-github_latest_tag] [-changelog -hasunreleased]
    echo.
    echo Options:
    echo   -changelog              Get latest version from CHANGELOG.md
    echo   -pyproject              Get version from pyproject.toml
    echo   -github_latest_tag      Get latest version tag from Git ^(vx.x.x format^)
    echo   -changelog -hasunreleased  Check if CHANGELOG.md has Unreleased section
    exit /b 1
)

:: Find project root (look for pyproject.toml or CHANGELOG.md)
set "PROJECT_ROOT=%CD%"
:find_root
if exist "%PROJECT_ROOT%\pyproject.toml" goto found_root
if exist "%PROJECT_ROOT%\CHANGELOG.md" goto found_root
for %%i in ("%PROJECT_ROOT%") do set "PARENT=%%~dpi"
if "%PARENT%"=="%PROJECT_ROOT%\" (
    echo Error: Could not find project root ^(pyproject.toml or CHANGELOG.md not found^)
    exit /b 1
)
set "PROJECT_ROOT=%PARENT:~0,-1%"
goto find_root

:found_root

if "%MODE%"=="changelog" goto get_changelog_version
if "%MODE%"=="pyproject" goto get_pyproject_version
if "%MODE%"=="github" goto get_github_version

:get_changelog_version
set "CHANGELOG_FILE=%PROJECT_ROOT%\CHANGELOG.md"
if not exist "%CHANGELOG_FILE%" (
    echo Error: CHANGELOG.md not found in %PROJECT_ROOT%
    exit /b 1
)

if "%CHECK_UNRELEASED%"=="true" (
    findstr /i "unreleased" "%CHANGELOG_FILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo true
    ) else (
        echo false
    )
    exit /b 0
)

:: Extract first version number from changelog (skip header references)
:: Create temp file to filter out header lines
set "TEMP_FILE=%TEMP%\changelog_versions.tmp"
findstr "^## \[" "%CHANGELOG_FILE%" | findstr /v "Keep a Changelog" | findstr /v "Semantic Versioning" > "%TEMP_FILE%"

for /f "usebackq tokens=2 delims=[]" %%a in ("%TEMP_FILE%") do (
    set "VERSION=%%a"
    if /i "!VERSION!" neq "unreleased" (
        del "%TEMP_FILE%" 2>nul
        echo !VERSION!
        exit /b 0
    )
)

del "%TEMP_FILE%" 2>nul

echo Error: No version found in CHANGELOG.md
exit /b 1

:get_pyproject_version
set "PYPROJECT_FILE=%PROJECT_ROOT%\pyproject.toml"
if not exist "%PYPROJECT_FILE%" (
    echo Error: pyproject.toml not found in %PROJECT_ROOT%
    exit /b 1
)

for /f "tokens=2 delims==" %%a in ('findstr "^version" "%PYPROJECT_FILE%"') do (
    set "VERSION=%%a"
    :: Remove quotes and spaces
    set "VERSION=!VERSION: =!"
    set "VERSION=!VERSION:"=!"
    echo !VERSION!
    exit /b 0
)

echo Error: No version found in pyproject.toml
exit /b 1

:get_github_version
:: Check if in a git repository
git status >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Not in a git repository
    exit /b 1
)

:: Fetch latest tags from remote
git fetch --tags >nul 2>&1

:: Get latest tag that matches vx.x.x pattern
set "LATEST_TAG="
for /f "tokens=*" %%a in ('git tag -l "v*" --sort=-version:refname 2^>nul') do (
    set "LATEST_TAG=%%a"
    goto found_tag
)

:found_tag
if "%LATEST_TAG%"=="" (
    echo Error: No version tags found ^(looking for vx.x.x pattern^)
    exit /b 1
)

echo %LATEST_TAG%
exit /b 0
