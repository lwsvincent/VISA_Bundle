@echo off
REM Script to update version in pyproject.toml, README, and CHANGELOG
REM Usage: update_version.bat <new_version>

if "%1"=="" (
    echo Usage: update_version.bat ^<new_version^>
    echo Example: update_version.bat 1.2.0
    exit /b 1
)

set NEW_VERSION=%1

echo Updating version to %NEW_VERSION%...

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