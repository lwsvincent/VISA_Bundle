@echo off
setlocal enabledelayedexpansion
REM Script to create and push git tag
REM Usage: create_tag.bat [version]
REM If no version is provided, it will be read from pyproject.toml

set VERSION=%1

if "%VERSION%"=="" (
    echo No version provided, reading from pyproject.toml...
    
    REM Find the script directory to call get_version.bat
    set SCRIPT_DIR=%~dp0
    
    REM Call get_version.bat -pyproject to get version
    for /f "tokens=*" %%a in ('"%SCRIPT_DIR%get_version.bat" -pyproject 2^>nul') do (
        set "VERSION=%%a"
        goto :version_found
    )
    
    echo ERROR: Failed to get version from pyproject.toml
    echo Make sure pyproject.toml exists and contains a version field
    exit /b 1
    
    :version_found
    echo Found version: !VERSION!
)

set TAG_NAME=v!VERSION!

echo Creating git tag !TAG_NAME!...

REM Check if tag already exists
git tag -l !TAG_NAME! | findstr !TAG_NAME! >nul
if %ERRORLEVEL% == 0 (
    echo ERROR: Tag !TAG_NAME! already exists
    exit /b 1
)

REM Check if there are uncommitted changes
git diff --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are uncommitted changes. Please commit or stash them first.
    exit /b 1
)

git diff --cached --quiet
if %ERRORLEVEL% neq 0 (
    echo ERROR: There are staged changes. Please commit them first.
    exit /b 1
)

REM Create annotated tag
echo Creating annotated tag !TAG_NAME!...
git tag -a !TAG_NAME! -m "Release version !VERSION!"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create tag
    exit /b 1
)

REM Push tag to remote
echo Pushing tag !TAG_NAME! to remote...
git push origin !TAG_NAME!

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to push tag to remote
    exit /b 1
)

echo.
echo Tag !TAG_NAME! created and pushed successfully!
echo Tag: !TAG_NAME!
echo Message: Release version !VERSION!