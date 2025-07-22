@echo off
REM Script to push current branch to release branch
REM Usage: push_to_release.bat

echo Pushing to release branch...

REM Get current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i

if "%CURRENT_BRANCH%"=="" (
    echo ERROR: Could not determine current branch
    exit /b 1
)

echo Current branch: %CURRENT_BRANCH%

REM Check if there are uncommitted changes
git diff --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are uncommitted changes. Please commit them first.
    exit /b 1
)

git diff --cached --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are staged changes. Please commit them first.
    exit /b 1
)

REM Push current branch to origin
echo Pushing %CURRENT_BRANCH% to origin...
git push origin %CURRENT_BRANCH%

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push to origin
    exit /b 1
)

REM Check if release branch exists
git ls-remote --heads origin release | find "release" >nul
if %ERRORLEVEL% == 0 (
    echo Release branch exists, merging %CURRENT_BRANCH% into release...
    git checkout release
    git pull origin release
    git merge %CURRENT_BRANCH%
    git push origin release
    git checkout %CURRENT_BRANCH%
) else (
    echo Creating new release branch from %CURRENT_BRANCH%...
    git checkout -b release
    git push origin release
    git checkout %CURRENT_BRANCH%
)

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push to release branch
    exit /b 1
)

REM Find and copy wheel files and documentation
echo.
echo Copying wheel files and documentation...

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

echo WARNING: Could not find project root, skipping file copying
goto :skip_copy

:found_root
echo Found project root: %PROJECT_ROOT%

REM Copy wheel files from dist directory
if exist "%PROJECT_ROOT%\dist\*.whl" (
    echo Copying wheel files...
    for %%f in ("%PROJECT_ROOT%\dist\*.whl") do (
        echo Copying: %%f
        copy "%%f" "%PROJECT_ROOT%\" >nul
        git add "%%~nxf"
    )
) else (
    echo No wheel files found in dist directory
)

REM Copy README files
if exist "%PROJECT_ROOT%\README.md" (
    echo README.md already in root
) else (
    echo No README.md found
)

REM Copy CHANGELOG files
if exist "%PROJECT_ROOT%\CHANGELOG.md" (
    echo CHANGELOG.md already in root
) else (
    echo No CHANGELOG.md found
)

REM Commit the copied files if any were added
git diff --cached --quiet >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Committing copied files...
    git commit -m "Add wheel files and documentation for release"
    
    REM Push the updated release branch
    git checkout release
    git pull origin release
    git merge %CURRENT_BRANCH%
    git push origin release
    git checkout %CURRENT_BRANCH%
    
    echo Updated release branch with wheel files and documentation
) else (
    echo No new files to commit
)

:skip_copy
echo.
echo Successfully pushed to release branch!
echo Current branch: %CURRENT_BRANCH%
echo Release branch updated