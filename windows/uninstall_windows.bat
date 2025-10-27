@echo off
setlocal enabledelayedexpansion

echo DONTOUCH Uninstaller (Windows)
echo ==============================
echo.

REM Check if hooks.json exists
if not exist "%USERPROFILE%\.cursor\hooks.json" (
    echo No hooks.json found - nothing to uninstall
    pause
    exit /b 0
)

echo This will remove %USERPROFILE%\.cursor\hooks.json
echo.
set /p "REPLY=Continue? (Y/n): "
if /i not "!REPLY!"=="Y" if not "!REPLY!"=="" (
    echo Uninstall cancelled
    pause
    exit /b 0
)

REM Backup the existing file before removing
set "timestamp=%date:~-4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "timestamp=!timestamp: =0!"
copy "%USERPROFILE%\.cursor\hooks.json" "%USERPROFILE%\.cursor\hooks.json.backup.!timestamp!" >nul
echo Backed up existing hooks.json to: hooks.json.backup.!timestamp!

REM Remove hooks.json
del "%USERPROFILE%\.cursor\hooks.json"
echo Removed hooks.json

echo.
echo Uninstall complete!
echo Please restart Cursor for changes to take effect
echo.
echo Note: .dontouch backup folders in your projects were NOT removed.
echo You can safely delete them manually if needed.
echo.
pause

