@echo off
setlocal enabledelayedexpansion
REM Script to pull updates from template_project subtree in multiple folders
REM Usage: subtree_pull_all.bat [-subfolder <path>] [-rootpath <path>]
REM This script is designed to run from projects/template_project/scripts/
REM By default, it scans all project directories in projects/ for subtree updates

echo Pulling updates from template_project subtree in multiple folders...

REM Parse command line arguments
set PROJECT_ROOT=
set SUBFOLDER_PATH=
set ROOTPATH_SPECIFIED=0
set SUBFOLDER_SPECIFIED=0

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="-rootpath" (
    set ROOTPATH_SPECIFIED=1
    if "%~2"=="" (
        echo ERROR: -rootpath requires a path argument
        exit /b 1
    )
    set PROJECT_ROOT=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-subfolder" (
    set SUBFOLDER_SPECIFIED=1
    if "%~2"=="" (
        echo ERROR: -subfolder requires a path argument
        exit /b 1
    )
    set SUBFOLDER_PATH=%~2
    shift
    shift
    goto :parse_args
)
REM Skip unknown arguments
shift
goto :parse_args

:args_done

REM Set default paths if not specified
if %ROOTPATH_SPECIFIED%==0 (
    REM Default: assume we're in projects/template_project/scripts and want to scan projects/
    set SCRIPT_CURRENT_DIR=%~dp0
    for %%i in ("!SCRIPT_CURRENT_DIR!..\..\..") do set PROJECT_ROOT=%%~fi
)

if %SUBFOLDER_SPECIFIED%==0 (
    REM Default: scan all sibling projects in the projects directory
    for %%i in ("!SCRIPT_CURRENT_DIR!..\..") do set SUBFOLDER_PATH=%%~fi
)

echo Root path: %PROJECT_ROOT%
echo Subfolder path: %SUBFOLDER_PATH%

REM Check if the specified paths exist
if not exist "%PROJECT_ROOT%" (
    echo ERROR: Specified root path does not exist: %PROJECT_ROOT%
    exit /b 1
)

if not exist "%SUBFOLDER_PATH%" (
    echo ERROR: Specified subfolder path does not exist: %SUBFOLDER_PATH%
    exit /b 1
)

REM Save original working directory
set ORIGINAL_DIR=%CD%

REM Get script directory for calling other scripts
set SCRIPT_DIR=%~dp0

echo.
echo ================================
echo SCANNING SUBFOLDERS FOR SUBTREE PULL
echo ================================

set TOTAL_FOLDERS=0
set SUCCESS_COUNT=0
set FAILED_COUNT=0
set SKIPPED_COUNT=0
set SUCCESS_PATHS=
set FAILED_PATHS=
set SKIPPED_PATHS=

REM If subfolder specified, scan its subdirectories (depth 1)
if %SUBFOLDER_SPECIFIED%==1 (
    echo Scanning subfolders in: %SUBFOLDER_PATH%
    for /d %%D in ("%SUBFOLDER_PATH%\*") do (
        REM Skip the template_project itself to avoid self-processing
        for %%F in ("%%D") do (
            if /i not "%%~nxF"=="template_project" (
                call :process_folder "%%D"
            ) else (
                echo SKIP: Skipping template_project directory: %%D
                set /a SKIPPED_COUNT+=1
                set SKIPPED_PATHS=!SKIPPED_PATHS! "%%D"
            )
        )
    )
) else (
    REM Default behavior: scan all projects except template_project
    echo Scanning project directories in: %SUBFOLDER_PATH%
    for /d %%D in ("%SUBFOLDER_PATH%\*") do (
        REM Skip the template_project itself to avoid self-processing
        for %%F in ("%%D") do (
            if /i not "%%~nxF"=="template_project" (
                call :process_folder "%%D"
            ) else (
                echo SKIP: Skipping template_project directory: %%D
                set /a SKIPPED_COUNT+=1
                set SKIPPED_PATHS=!SKIPPED_PATHS! "%%D"
            )
        )
    )
)

echo.
echo ================================
echo SUBTREE PULL ALL SUMMARY
echo ================================
echo Total folders processed: !TOTAL_FOLDERS!
echo Successful pulls: !SUCCESS_COUNT!
echo Failed pulls: !FAILED_COUNT!
echo Skipped folders: !SKIPPED_COUNT!
echo.

if !SUCCESS_COUNT! gtr 0 (
    echo SUCCESSFUL PATHS:
    for %%p in (!SUCCESS_PATHS!) do echo   ✓ %%p
    echo.
)

if !FAILED_COUNT! gtr 0 (
    echo FAILED PATHS:
    for %%p in (!FAILED_PATHS!) do echo   ✗ %%p
    echo.
)

if !SKIPPED_COUNT! gtr 0 (
    echo SKIPPED PATHS:
    for %%p in (!SKIPPED_PATHS!) do echo   - %%p
    echo.
)

if !FAILED_COUNT! gtr 0 (
    echo Some folders failed to pull. Check the output above for details.
    exit /b 1
) else (
    echo All applicable folders processed successfully!
)

REM Restore original working directory
cd /d "%ORIGINAL_DIR%"
goto :eof

REM Function to process a single folder
:process_folder
set FOLDER_PATH=%~1
set /a TOTAL_FOLDERS+=1

echo.
echo --------------------------------
echo Processing folder: %FOLDER_PATH%
echo --------------------------------

REM Check if it's a git repository
cd /d "%FOLDER_PATH%" 2>nul
if %ERRORLEVEL% neq 0 (
    echo SKIP: Cannot access folder: %FOLDER_PATH%
    set /a SKIPPED_COUNT+=1
    set SKIPPED_PATHS=!SKIPPED_PATHS! "%FOLDER_PATH%"
    goto :process_folder_end
)

git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo SKIP: Not a git repository: %FOLDER_PATH%
    set /a SKIPPED_COUNT+=1
    set SKIPPED_PATHS=!SKIPPED_PATHS! "%FOLDER_PATH%"
    goto :process_folder_end
)

REM Check if template_project exists
if not exist "%FOLDER_PATH%\template_project" (
    echo SKIP: template_project does not exist in: %FOLDER_PATH%
    echo       Run subtree_init_all.bat first to initialize
    set /a SKIPPED_COUNT+=1
    set SKIPPED_PATHS=!SKIPPED_PATHS! "%FOLDER_PATH%"
    goto :process_folder_end
)

REM Check for uncommitted changes
git diff-index --quiet HEAD --
if %ERRORLEVEL% neq 0 (
    echo SKIP: Working tree has modifications in: %FOLDER_PATH%
    echo       Please commit or stash changes first
    set /a SKIPPED_COUNT+=1
    set SKIPPED_PATHS=!SKIPPED_PATHS! "%FOLDER_PATH%"
    goto :process_folder_end
)

REM Call subtree_pull.bat for this folder
echo Calling subtree_pull.bat for: %FOLDER_PATH%
call "%SCRIPT_DIR%subtree_pull.bat" "%FOLDER_PATH%"

if %ERRORLEVEL% neq 0 (
    echo FAILED: Subtree pull failed for: %FOLDER_PATH%
    set /a FAILED_COUNT+=1
    set FAILED_PATHS=!FAILED_PATHS! "%FOLDER_PATH%"
) else (
    echo SUCCESS: Subtree pull completed for: %FOLDER_PATH%
    set /a SUCCESS_COUNT+=1
    set SUCCESS_PATHS=!SUCCESS_PATHS! "%FOLDER_PATH%"
)

:process_folder_end
REM Return to original directory
cd /d "%ORIGINAL_DIR%"
goto :eof