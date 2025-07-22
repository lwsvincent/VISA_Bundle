@echo off
REM Script to create GitHub release
REM Usage: release_to_remote.bat <version>

if "%1"=="" (
    echo Usage: release_to_remote.bat ^<version^>
    echo Example: release_to_remote.bat 1.2.0
    exit /b 1
)

set VERSION=%1
set TAG_NAME=v%VERSION%

echo Creating GitHub release for %TAG_NAME%...

REM Find project root by looking for dist directory or pyproject.toml
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
echo 123
REM Check if gh CLI is available
gh --version >nul 2>&1
echo 456
if errorlevel 1 (
    echo ERROR: "GitHub CLI (gh) not found. Please install it first."
    echo Visit: https://cli.github.com/
    exit /b 1
)
echo 456
REM Check if tag exists
git tag -l %TAG_NAME% | findstr %TAG_NAME% >nul
if errorlevel 1 (
    echo ERROR: Tag %TAG_NAME% not found. Create tag first using create_tag.bat
    exit /b 1
)
echo 789
REM Check if wheel file exists
dir "dist\*.whl" >nul 2>&1
if errorlevel 1 (
    echo ERROR: No wheel file found in dist directory. Run build_wheel.bat first.
    exit /b 1
)
echo 111
REM Find the wheel file
for %%f in (dist\*.whl) do set WHEEL_FILE=%%f
echo 222
REM Extract release notes from CHANGELOG.md
echo Extracting release notes from CHANGELOG.md...
powershell -Command "$content = Get-Content CHANGELOG.md -Encoding UTF8; $start = $content | Select-String -Pattern '## \[%VERSION%\]' | Select-Object -First 1; if ($start) { $startIndex = $start.LineNumber; $nextVersion = $content | Select-String -Pattern '## \[.*\]' | Where-Object { $_.LineNumber -gt $startIndex } | Select-Object -First 1; if ($nextVersion) { $endIndex = $nextVersion.LineNumber - 2 } else { $endIndex = $content.Length }; $releaseNotes = $content[($startIndex)..($endIndex)] -join \"`n\"; [System.IO.File]::WriteAllText('release_notes.tmp', $releaseNotes, [System.Text.Encoding]::UTF8) }"
echo 333
if exist "release_notes.tmp" (
    echo Release notes extracted successfully
) else (
    echo Warning: Could not extract release notes from CHANGELOG.md
    echo Creating default release notes...
    powershell -Command "[System.IO.File]::WriteAllText('release_notes.tmp', 'Release %VERSION%', [System.Text.Encoding]::UTF8)"
)
echo 444
REM Create GitHub release
echo Creating GitHub release...
gh release create %TAG_NAME% "%WHEEL_FILE%" --title "Release %VERSION%" --notes-file release_notes.tmp

if errorlevel 1 (
    echo ERROR: Failed to create GitHub release
    del release_notes.tmp 2>nul
    exit /b 1
)

REM Clean up
del release_notes.tmp 2>nul

echo.
echo GitHub release created successfully!
echo Release: %TAG_NAME%
echo Attached: %WHEEL_FILE%
echo.
echo View release at: https://github.com/$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')/releases/tag/%TAG_NAME%

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"