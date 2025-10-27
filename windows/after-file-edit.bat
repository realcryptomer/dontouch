@echo off
setlocal enabledelayedexpansion

REM Hook: afterFileEdit
REM This hook runs after the agent edits a file
REM Input: JSON with file_path, edits, and other metadata

REM Debug log file
REM set "LOG_FILE=%TEMP%\dontouch_after_edit_debug.log"
REM echo [%date% %time%] === afterFileEdit hook started === > "%LOG_FILE%"

REM Read input from stdin
set "input="
for /f "delims=" %%i in ('more') do set "input=!input!%%i"

REM echo [%date% %time%] Input length: !input:~0,100!... >> "%LOG_FILE%"
REM echo [%date% %time%] Full input: !input! >> "%LOG_FILE%"

REM Extract file_path from JSON using PowerShell script with temp file
set "file_path="
set "temp_json=%TEMP%\dontouch_input.json"
echo !input! > "!temp_json!"
for /f "delims=" %%a in ('powershell -ExecutionPolicy Bypass -File "%~dp0parse_json.ps1" -JsonFile "!temp_json!" -FieldName "file_path"') do set "file_path=%%a"
del "!temp_json!" 2>nul
if not defined file_path set "file_path=NO_FILE_PATH"

REM echo [%date% %time%] Extracted file_path: !file_path! >> "%LOG_FILE%"

REM Normalize file path (remove double backslashes)
set "file_path=!file_path:\\=\!"
REM echo [%date% %time%] Normalized file_path: !file_path! >> "%LOG_FILE%"

REM Check if file exists and read first 2 lines for DONTOUCH or common typos
REM Matches: DONTOUCH, DONTTOUCH, DON'TOUCH, DON'TTOUCH
if exist "!file_path!" (
    REM echo [%date% %time%] File exists: !file_path! >> "%LOG_FILE%"
    set "line_count=0"
    set "found_dontouch=0"
    for /f "usebackq delims=" %%a in ("!file_path!") do (
        REM echo [%date% %time%] Line !line_count!: %%a >> "%LOG_FILE%"
        REM Use simple case-insensitive search (findstr regex is limited)
        echo %%a | findstr /i "dontouch donttouch don'touch don'ttouch" >nul
        if !errorlevel! equ 0 (
            set "found_dontouch=1"
            REM echo [%date% %time%] DONTOUCH detected on line !line_count! >> "%LOG_FILE%"
        )
        set /a line_count+=1
        if !line_count! geq 2 goto :check_protection
    )
    
    :check_protection
    REM echo [%date% %time%] DONTOUCH found: !found_dontouch! >> "%LOG_FILE%"
    if !found_dontouch! equ 1 (
        REM Get workspace root using PowerShell script with temp file
        set "workspace_root="
        set "temp_json=%TEMP%\dontouch_input.json"
        echo !input! > "!temp_json!"
        for /f "delims=" %%a in ('powershell -ExecutionPolicy Bypass -File "%~dp0parse_json.ps1" -JsonFile "!temp_json!" -FieldName "workspace_roots"') do set "workspace_root=%%a"
        del "!temp_json!" 2>nul
        if not defined workspace_root set "workspace_root=NO_WORKSPACE_ROOT"
        
        REM echo [%date% %time%] Workspace root: !workspace_root! >> "%LOG_FILE%"
        
        REM Convert Unix-style path to Windows-style path
        if "!workspace_root:~0,1!" equ "/" (
            set "workspace_root=!workspace_root:~1!"
            set "workspace_root=!workspace_root:/=\!"
        )
        REM echo [%date% %time%] Converted workspace_root: !workspace_root! >> "%LOG_FILE%"
        
        REM Create hash from file path (consistent hashing - matches beforeReadFile)
        for /f %%i in ('powershell -command "$md5 = [System.Security.Cryptography.MD5]::Create(); $hash = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(\"!file_path!\")); [System.BitConverter]::ToString($hash).Replace(\"-\",\"\").ToLower()" 2^>nul') do set "file_hash=%%i"
        set "backup_file=!workspace_root!\.dontouch\!file_hash!"
        
        REM echo [%date% %time%] File hash: !file_hash! >> "%LOG_FILE%"
        REM echo [%date% %time%] Backup file: !backup_file! >> "%LOG_FILE%"
        
        REM Extract filename for display
        for %%f in ("!file_path!") do set "filename=%%~nxf"
        
        REM Check if backup exists
        if exist "!backup_file!" (
            REM echo [%date% %time%] Backup exists, showing dialog >> "%LOG_FILE%"
            REM Show popup asking to revert
            powershell -command "Add-Type -AssemblyName System.Windows.Forms; $result = [System.Windows.Forms.MessageBox]::Show('Cursor just changed a DONTOUCH file:' + [Environment]::NewLine + [Environment]::NewLine + '!filename!' + [Environment]::NewLine + [Environment]::NewLine + 'Revert changes?', 'DONTOUCH Protection', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning, [System.Windows.Forms.MessageBoxDefaultButton]::Button1); if ($result -eq 'Yes') { exit 0 } else { exit 1 }" >nul 2>&1
            
            if !errorlevel! equ 0 (
                REM echo [%date% %time%] User clicked Yes - reverting >> "%LOG_FILE%"
                REM User clicked Yes - revert
                copy "!backup_file!" "!file_path!" >nul 2>&1
                echo {"action":"reverted","file":"!filename!"}
            ) else (
                REM echo [%date% %time%] User clicked No - updating backup >> "%LOG_FILE%"
                REM User clicked No - update backup
                copy "!file_path!" "!backup_file!" >nul 2>&1
                echo {"action":"approved","file":"!filename!"}
            )
        ) else (
            REM echo [%date% %time%] Backup does NOT exist >> "%LOG_FILE%"
            REM No backup available
            powershell -command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Cursor just changed a DONTOUCH file:' + [Environment]::NewLine + [Environment]::NewLine + '!filename!' + [Environment]::NewLine + [Environment]::NewLine + 'We do not have a copy to revert.', 'DONTOUCH Protection', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)" >nul 2>&1
            echo {"action":"no_backup","file":"!filename!"}
        )
        REM echo [%date% %time%] Exiting after DONTOUCH processing >> "%LOG_FILE%"
        exit /b 0
    )
) else (
    REM echo [%date% %time%] File does NOT exist: !file_path! >> "%LOG_FILE%"
)

REM echo [%date% %time%] Not a DONTOUCH file or file not found >> "%LOG_FILE%"
REM Not a DONTOUCH file, no action needed
exit /b 0






