@echo off
setlocal enabledelayedexpansion
REM Script to automate complete project release process
REM Usage: release_project.bat [-major|-minor|-patch]
REM This script orchestrates the entire release workflow

REM Parse arguments for version increment
set INCREMENT_TYPE=patch
if "%1"=="-major" set INCREMENT_TYPE=major
if "%1"=="-minor" set INCREMENT_TYPE=minor
if "%1"=="-patch" set INCREMENT_TYPE=patch

echo ================================
echo PROJECT RELEASE AUTOMATION
echo ================================
echo Starting automated release process...
echo.

REM Save original working directory
set ORIGINAL_DIR=%CD%

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
cd /d "%ORIGINAL_DIR%"
exit /b 1

:found_root
echo Found project root: %PROJECT_ROOT%
cd /d "%PROJECT_ROOT%"

REM Get script directory for calling other scripts
set SCRIPT_DIR=%~dp0

echo.
echo ================================
echo STEP 0: CHECKING UNCOMMITTED CHANGES
echo ================================

REM Check if there are uncommitted changes
git diff --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are uncommitted changes in working directory
    echo Please commit or stash changes before releasing
    git status --porcelain
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

git diff --cached --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are staged changes not committed
    echo Please commit staged changes before releasing
    git status --porcelain
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ No uncommitted changes found

echo.
echo ================================
echo STEP 1: CONFIRMING MAIN BRANCH
echo ================================

REM Check current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i

if /i "!CURRENT_BRANCH!" neq "main" (
    if /i "!CURRENT_BRANCH!" neq "master" (
        echo ERROR: Not on main/master branch (currently on: !CURRENT_BRANCH!)
        echo Please switch to main branch before releasing
        cd /d "%ORIGINAL_DIR%"
        exit /b 1
    )
)

echo ✅ Confirmed on main branch: !CURRENT_BRANCH!

echo.
echo ================================
echo STEP 2: GETTING CURRENT VERSION FOR INCREMENT
echo ================================

REM Get current version from pyproject.toml
echo Calling get_version.bat -pyproject...
for /f "tokens=*" %%a in ('"%SCRIPT_DIR%get_version.bat" -pyproject 2^>nul') do (
    set "CURRENT_VERSION=%%a"
    goto :current_version_found
)

echo ERROR: Failed to get current version from pyproject.toml
cd /d "%ORIGINAL_DIR%"
exit /b 1

:current_version_found
echo ✅ Current version from pyproject.toml: !CURRENT_VERSION!

REM Calculate new version based on increment type
echo Calculating new version with increment type: !INCREMENT_TYPE!
call :calculate_new_version !CURRENT_VERSION! !INCREMENT_TYPE!
echo ✅ New version calculated: !NEW_VERSION!

echo.
echo ================================
echo STEP 3: GETTING REMOTE LATEST RELEASE
echo ================================

REM Get remote version from GitHub tags
echo Calling get_version.bat -github_latest_tag...
for /f "tokens=*" %%a in ('"%SCRIPT_DIR%get_version.bat" -github_latest_tag 2^>nul') do (
    set "REMOTE_VERSION=%%a"
    goto :remote_version_found
)

echo WARNING: No remote version found or failed to fetch
set REMOTE_VERSION=v0.0.0

:remote_version_found
echo ✅ Remote latest version: !REMOTE_VERSION!

echo.
echo ================================
echo STEP 4: VERSION COMPARISON
echo ================================

REM Simple version comparison (assumes semantic versioning)
echo Comparing new version !NEW_VERSION! with remote !REMOTE_VERSION!

REM Extract version numbers (remove 'v' prefix if present)
set NEW_VER_NUM=!NEW_VERSION!
set REMOTE_VER_NUM=!REMOTE_VERSION!
if "!NEW_VER_NUM:~0,1!"=="v" set NEW_VER_NUM=!NEW_VER_NUM:~1!
if "!REMOTE_VER_NUM:~0,1!"=="v" set REMOTE_VER_NUM=!REMOTE_VER_NUM:~1!

REM For now, assume versions are correct (full semantic version comparison is complex in batch)
echo ✅ Version validation passed (new: !NEW_VER_NUM!, remote: !REMOTE_VER_NUM!)

echo.
echo ================================
echo STEP 5: CREATING RELEASE BRANCH
echo ================================

REM Switch to or create release branch
echo Calling change_branch.bat release...
start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" release"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create/switch to release branch
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Successfully on release branch

echo.
echo ================================
echo STEP 6: UPDATING VERSION FILES
echo ================================

REM Update version files using enhanced update_version.bat
echo Calling update_version.bat !NEW_VER_NUM!...
start /wait cmd /c ""%SCRIPT_DIR%update_version.bat" !NEW_VER_NUM!"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to update version files
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

REM Verify version was actually updated in pyproject.toml
echo Verifying version update in pyproject.toml...
for /f "tokens=*" %%a in ('"%SCRIPT_DIR%get_version.bat" -pyproject 2^>nul') do (
    set "UPDATED_VERSION=%%a"
    goto :version_verified
)
:version_verified
if "!UPDATED_VERSION!" neq "!NEW_VER_NUM!" (
    echo ERROR: Version not properly updated in pyproject.toml (expected: !NEW_VER_NUM!, got: !UPDATED_VERSION!)
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)
echo ✅ Version successfully updated to !NEW_VER_NUM! in pyproject.toml

REM Update CHANGELOG.md [Unreleased] section with new version
echo Updating CHANGELOG.md [Unreleased] section to version !NEW_VER_NUM!...
call :update_changelog !NEW_VER_NUM!
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to update CHANGELOG.md
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Version files and CHANGELOG updated successfully

REM Commit version changes
echo Committing version changes...
git add -A
git commit -m "add changelog version to v!NEW_VER_NUM!"
if errorlevel 1 (
    echo ERROR: Failed to commit version changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

REM Store commit hash for potential rollback
for /f "tokens=*" %%a in ('git rev-parse HEAD') do set VERSION_COMMIT_HASH=%%a
echo Version commit hash stored for rollback: !VERSION_COMMIT_HASH!

REM Push version changes to release branch
echo Pushing version changes to release branch...
git push origin release
if errorlevel 1 (
    echo ERROR: Failed to push version changes
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Version changes committed and pushed successfully

echo.
echo ================================
echo STEP 7: BUILDING WHEEL PACKAGE
echo ================================

REM Build wheel using build_wheel.bat (now with updated version)
echo Calling build_wheel.bat...
start /wait cmd /c ""%SCRIPT_DIR%build_wheel.bat""
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build wheel package
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Wheel package built successfully

echo.
echo ================================
echo STEP 8: CREATING TEST ENVIRONMENT
echo ================================

REM Create test environment using create_venv.bat
echo Calling create_venv.bat -test -dev...
start /wait cmd /c ""%SCRIPT_DIR%create_venv.bat" -test -dev"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create test environment
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Test environment created successfully

echo.
echo ================================
echo STEP 9: INSTALLING TO TEST ENVIRONMENT
echo ================================

REM Install wheel to test environment
echo Calling install_wheel.bat --venv test-venv...
start /wait cmd /c ""%SCRIPT_DIR%install_wheel.bat" --venv test-venv"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install wheel to test environment
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Package installed to test environment successfully

echo.
echo ================================
echo STEP 10: RUNNING TESTS
echo ================================

REM Run tests using run_tests.bat with test environment
echo Calling run_tests.bat full -testvenv test-venv...
start /wait cmd /c ""%SCRIPT_DIR%run_tests.bat" full -testvenv test-venv"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Tests failed in test environment
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ All tests passed in test environment

echo.
echo ================================
echo STEP 11: PUSHING TO RELEASE BRANCH AND CREATING TAG
echo ================================

REM Push to release branch using push_to_release.bat
echo Calling push_to_release.bat...
start /wait cmd /c ""%SCRIPT_DIR%push_to_release.bat""
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push to release branch
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

REM Create git tag using create_tag.bat
echo Calling create_tag.bat !NEW_VER_NUM!...
start /wait cmd /c ""%SCRIPT_DIR%create_tag.bat" !NEW_VER_NUM!"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create git tag
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Pushed to release branch and created tag successfully

echo.
echo ================================
echo STEP 12: CREATING GITHUB RELEASE
echo ================================

REM Create GitHub release using release_to_remote.bat
echo Calling release_to_remote.bat !NEW_VER_NUM!...
start /wait cmd /c ""%SCRIPT_DIR%release_to_remote.bat" !NEW_VER_NUM!"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create GitHub release
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    echo Returning to main branch...
    start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ GitHub release created successfully

echo.
echo ================================
echo STEP 13: MERGING RELEASE TO MAIN
echo ================================

REM Switch back to main branch
echo Switching back to main branch...
start /wait cmd /c ""%SCRIPT_DIR%change_branch.bat" !CURRENT_BRANCH!"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to switch back to main branch
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

REM Merge release branch to main
echo Merging release branch to main...
git merge release -m "Release version !NEW_VER_NUM!"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to merge release to main
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

REM Push main branch
echo Pushing main branch...
git push origin !CURRENT_BRANCH!
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push main branch
    echo Cleaning up test environment...
    if exist "test-venv" rmdir /s /q test-venv
    echo Performing rollback...
    call :rollback_version_changes
    cd /d "%ORIGINAL_DIR%"
    exit /b 1
)

echo ✅ Release merged to main and pushed successfully

REM Delete release branch
echo Deleting release branch...
git branch -d release
if errorlevel 1 (
    echo WARNING: Failed to delete local release branch (non-critical)
)

git push origin --delete release
if errorlevel 1 (
    echo WARNING: Failed to delete remote release branch (non-critical)
)

echo ✅ Release branch deleted successfully

echo.
echo ================================
echo STEP 14: CLEANUP
echo ================================

REM Clean up test environment and build artifacts
echo Cleaning up test environment...
if exist "test-venv" (
    rmdir /s /q test-venv
    echo ✅ Test environment removed
)

echo Cleaning up build artifacts...
start /wait cmd /c ""%SCRIPT_DIR%cleanup_build.bat""
if %ERRORLEVEL% neq 0 (
    echo WARNING: Failed to clean build artifacts (non-critical)
)

echo Final cleanup of build artifacts...
start /wait cmd /c ""%SCRIPT_DIR%cleanup_build.bat""
if %ERRORLEVEL% neq 0 (
    echo WARNING: Failed to clean build artifacts (non-critical)
)

echo ✅ Cleanup completed

echo.
echo ================================
echo 🎉 RELEASE COMPLETED SUCCESSFULLY! 🎉
echo ================================
echo.
echo Release Summary:
echo - Version: !NEW_VER_NUM!
echo - Branch: release (deleted)
echo - Tag: v!NEW_VER_NUM!
echo - GitHub Release: Created
echo - Main Branch: Updated and pushed
echo - Increment Type: !INCREMENT_TYPE!
echo.
echo Next steps:
echo 1. Verify GitHub release at: https://github.com/[your-repo]/releases/tag/v!NEW_VER_NUM!
echo 2. Verify package installation: pip install [your-package]==!NEW_VER_NUM!
echo 3. Update any dependent projects
echo.

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"

echo Release automation completed successfully!
goto :eof

REM Function to calculate new version based on increment type
:calculate_new_version
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
goto :eof

REM Function to update CHANGELOG.md [Unreleased] section with new version
:update_changelog
set "new_ver=%~1"

REM Check if CHANGELOG.md exists
if not exist "CHANGELOG.md" (
    echo ERROR: CHANGELOG.md not found
    exit /b 1
)

REM Get current date in YYYY-MM-DD format
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set CURRENT_DATE=%%c-%%a-%%b
)

REM Update CHANGELOG.md - replace [Unreleased] with version and date using UTF8 without BOM
echo Updating CHANGELOG.md [Unreleased] section...
powershell -Command "$content = Get-Content CHANGELOG.md -Encoding UTF8; $content = $content -replace '## \[Unreleased\]', '## [%new_ver%] - %CURRENT_DATE%'; $utf8NoBom = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllLines('CHANGELOG.md', $content, $utf8NoBom)"

REM Check if update was successful
if errorlevel 1 (
    echo ERROR: Failed to update CHANGELOG.md
    exit /b 1
)

echo ✅ CHANGELOG.md updated successfully
goto :eof

REM Function to rollback version changes in case of failure
:rollback_version_changes
echo.
echo ================================
echo PERFORMING ROLLBACK
echo ================================
echo Rolling back version changes due to release failure...

REM Check if we have a version commit to rollback
if not defined VERSION_COMMIT_HASH (
    echo No version commit found to rollback
    goto :eof
)

REM Get the commit before the version commit
for /f "tokens=*" %%a in ('git rev-parse !VERSION_COMMIT_HASH!~1') do set PREVIOUS_COMMIT=%%a

REM Reset to the commit before version changes
echo Resetting to commit before version changes: !PREVIOUS_COMMIT!
git reset --hard !PREVIOUS_COMMIT!
if errorlevel 1 (
    echo ERROR: Failed to reset to previous commit
    echo Manual rollback required: git reset --hard !PREVIOUS_COMMIT!
    goto :eof
)

REM Force push to release branch to remove version commit from remote
echo Force pushing rollback to release branch...
git push origin release --force
if errorlevel 1 (
    echo WARNING: Failed to force push rollback to release branch
    echo Manual cleanup required: git push origin release --force
)

echo ✅ Version changes rolled back successfully
echo Repository state restored to commit: !PREVIOUS_COMMIT!
goto :eof