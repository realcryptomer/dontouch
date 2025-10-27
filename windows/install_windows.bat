@echo off
setlocal enabledelayedexpansion

echo DONTOUCH Installer (Windows)
echo ============================
echo.

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
cd /d "%SCRIPT_DIR%\.."
set "INSTALL_DIR=%CD%"

REM Check if hooks.json already exists
if exist "%USERPROFILE%\.cursor\hooks.json" (
    echo WARNING: Existing hooks.json found at %USERPROFILE%\.cursor\hooks.json
    echo.
    set /p "REPLY=Overwrite existing hooks? (Y/n): "
    if /i not "!REPLY!"=="Y" if not "!REPLY!"=="" (
        echo Installation cancelled
        pause
        exit /b 0
    )
    
    REM Backup existing file
    set "timestamp=%date:~-4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "timestamp=!timestamp: =0!"
    copy "%USERPROFILE%\.cursor\hooks.json" "%USERPROFILE%\.cursor\hooks.json.backup.!timestamp!" >nul
    echo Backed up existing hooks.json
)

REM Ensure the .cursor directory exists
if not exist "%USERPROFILE%\.cursor" mkdir "%USERPROFILE%\.cursor"

REM Create a temporary file for the modified hooks.json
set "TEMP_FILE=%TEMP%\dontouch_hooks_%RANDOM%.json"

REM Read hooks.json, replace FOLDER with absolute path and .sh with .bat for Windows
powershell -Command "(Get-Content '%INSTALL_DIR%\hooks.json') -replace 'FOLDER/', '%INSTALL_DIR:\=\\%\\windows\\' -replace '\.sh', '.bat' | Set-Content '%TEMP_FILE%'"

REM Copy the modified file to .cursor directory
copy "%TEMP_FILE%" "%USERPROFILE%\.cursor\hooks.json" >nul

REM Clean up
del "%TEMP_FILE%"

echo.
echo Installation complete!
echo hooks.json has been copied to %USERPROFILE%\.cursor\hooks.json
echo All command paths have been updated to absolute paths in windows folder
echo.
echo Please restart Cursor for changes to take effect.
echo.
pause
