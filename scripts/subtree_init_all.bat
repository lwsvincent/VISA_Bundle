@echo off
setlocal enabledelayedexpansion
REM Script to initialize git subtree for template_project in multiple folders
REM Usage: subtree_init_all.bat [-subfolder <path>] [-rootpath <path>]
REM This script can scan subfolders and apply subtree init to each (depth 1)

echo Initializing git subtree for template_project in multiple folders...

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
    set PROJECT_ROOT=%CD%
)

if %SUBFOLDER_SPECIFIED%==0 (
    set SUBFOLDER_PATH=%PROJECT_ROOT%
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
echo SCANNING SUBFOLDERS FOR SUBTREE INIT
echo ================================

set TOTAL_FOLDERS=0
set SUCCESS_COUNT=0
set FAILED_COUNT=0

REM If subfolder specified, scan its subdirectories (depth 1)
if %SUBFOLDER_SPECIFIED%==1 (
    echo Scanning subfolders in: %SUBFOLDER_PATH%
    for /d %%D in ("%SUBFOLDER_PATH%\*") do (
        call :process_folder "%%D"
    )
) else (
    REM Process the single root folder
    call :process_folder "%PROJECT_ROOT%"
)

echo.
echo ================================
echo SUBTREE INIT ALL SUMMARY
echo ================================
echo Total folders processed: !TOTAL_FOLDERS!
echo Successful initializations: !SUCCESS_COUNT!
echo Failed initializations: !FAILED_COUNT!
echo.

if !FAILED_COUNT! gtr 0 (
    echo Some folders failed to initialize. Check the output above for details.
    exit /b 1
) else (
    echo All folders initialized successfully!
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
    set /a FAILED_COUNT+=1
    goto :process_folder_end
)

git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo SKIP: Not a git repository: %FOLDER_PATH%
    set /a FAILED_COUNT+=1
    goto :process_folder_end
)

REM Check if template_project already exists
if exist "%FOLDER_PATH%\template_project" (
    echo SKIP: template_project already exists in: %FOLDER_PATH%
    set /a FAILED_COUNT+=1
    goto :process_folder_end
)

REM Call subtree_init.bat for this folder
echo Calling subtree_init.bat for: %FOLDER_PATH%
call "%SCRIPT_DIR%subtree_init.bat" -rootpath "%FOLDER_PATH%"

if %ERRORLEVEL% neq 0 (
    echo FAILED: Subtree init failed for: %FOLDER_PATH%
    set /a FAILED_COUNT+=1
) else (
    echo SUCCESS: Subtree init completed for: %FOLDER_PATH%
    set /a SUCCESS_COUNT+=1
)

:process_folder_end
REM Return to original directory
cd /d "%ORIGINAL_DIR%"
goto :eof