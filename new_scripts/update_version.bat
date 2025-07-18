@echo off
setlocal enabledelayedexpansion
REM Script to update version in pyproject.toml, README, and CHANGELOG
REM Usage: update_version.bat <new_version_or_increment_type>
REM Examples: 
REM   update_version.bat 1.2.0
REM   update_version.bat -major
REM   update_version.bat -minor  
REM   update_version.bat -patch

if "%1"=="" (
    echo Usage: update_version.bat ^<new_version_or_increment_type^>
    echo Examples:
    echo   update_version.bat 1.2.0
    echo   update_version.bat -major
    echo   update_version.bat -minor
    echo   update_version.bat -patch
    exit /b 1
)

set INPUT_PARAM=%1
set NEW_VERSION=

REM Check if input is a version increment type or direct version
if "%INPUT_PARAM%"=="-major" (
    set INCREMENT_TYPE=major
    goto :calculate_version
) else if "%INPUT_PARAM%"=="-minor" (
    set INCREMENT_TYPE=minor
    goto :calculate_version
) else if "%INPUT_PARAM%"=="-patch" (
    set INCREMENT_TYPE=patch
    goto :calculate_version
) else (
    set NEW_VERSION=%INPUT_PARAM%
    goto :find_project_root
)

:calculate_version
echo Calculating new version with increment type: %INCREMENT_TYPE%...

REM Find project root first to get current version
:find_project_root
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

REM If we need to calculate version, get current version first
if defined INCREMENT_TYPE (
    echo Getting current version from pyproject.toml...
    for /f "tokens=*" %%a in ('findstr /r "^version" pyproject.toml') do set VERSION_LINE=%%a
    for /f "tokens=2 delims==" %%a in ("!VERSION_LINE!") do set CURRENT_VERSION=%%a
    set CURRENT_VERSION=!CURRENT_VERSION: =!
    set CURRENT_VERSION=!CURRENT_VERSION:"=!
    echo Current version: !CURRENT_VERSION!
    call :calculate_new_version !CURRENT_VERSION! !INCREMENT_TYPE!
    echo Calculated new version: !NEW_VERSION!
)

echo Updating version to !NEW_VERSION!...

REM Check if files exist
if not exist "pyproject.toml" (
    echo ERROR: pyproject.toml not found
    exit /b 1
)

if not exist "README.md" (
    echo ERROR: README.md not found
    exit /b 1
)

if not exist "CHANGELOG.md" (
    echo ERROR: CHANGELOG.md not found
    exit /b 1
)

REM Update pyproject.toml version
echo Updating pyproject.toml...
powershell -Command "$content = (Get-Content pyproject.toml -Encoding UTF8) -replace '^version = \".*\"', 'version = \"%NEW_VERSION%\"'; [System.IO.File]::WriteAllLines((Resolve-Path 'pyproject.toml'), $content, [System.Text.UTF8Encoding]::new($false))"

REM Update README.md if it contains version references
echo Updating README.md...
powershell -Command "$content = (Get-Content README.md -Encoding UTF8) -replace 'version [0-9]+\.[0-9]+\.[0-9]+', 'version %NEW_VERSION%'; [System.IO.File]::WriteAllLines((Resolve-Path 'README.md'), $content, [System.Text.UTF8Encoding]::new($false))"

REM Update CHANGELOG.md - replace [Unreleased] with version and date
echo Updating CHANGELOG.md...
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set CURRENT_DATE=%%c-%%a-%%b
)
powershell -Command "$content = (Get-Content CHANGELOG.md -Encoding UTF8) -replace '## \[Unreleased\]', '## [%NEW_VERSION%] - %CURRENT_DATE%'; [System.IO.File]::WriteAllLines((Resolve-Path 'CHANGELOG.md'), $content, [System.Text.UTF8Encoding]::new($false))"

echo.
echo Version updated successfully!
echo Updated files:
echo - pyproject.toml: version = "%NEW_VERSION%"
echo - README.md: version references updated
echo - CHANGELOG.md: [Unreleased] → [%NEW_VERSION%] - %CURRENT_DATE%
echo.
echo Remember to review and commit these changes.

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"
goto :eof

REM Function to calculate new version based on increment type
:calculate_new_version
setlocal enabledelayedexpansion
set "current_ver=%~1"
set "increment=%~2"

REM Remove 'v' prefix if present
if "!current_ver:~0,1!"=="v" set current_ver=!current_ver:~1!

REM Parse version components (major.minor.patch)
for /f "tokens=1,2,3 delims=." %%a in ("!current_ver!") do (
    set "major=%%a"
    set "minor=%%b"
    set "patch=%%c"
)

REM Increment based on type
if "!increment!"=="major" (
    set /a major+=1
    set minor=0
    set patch=0
) else if "!increment!"=="minor" (
    set /a minor+=1
    set patch=0
) else if "!increment!"=="patch" (
    set /a patch+=1
)

REM Construct new version
set "NEW_VERSION=!major!.!minor!.!patch!"
endlocal & set "NEW_VERSION=%NEW_VERSION%"
goto :eof