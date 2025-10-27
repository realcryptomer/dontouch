@echo off
setlocal enabledelayedexpansion

REM Hook: beforeReadFile
REM This hook runs before the agent reads a file
REM Input: JSON with file_path, content, and attachments
REM Output: JSON with permission: "allow" or "deny"

REM Debug log file
REM set "LOG_FILE=%TEMP%\dontouch_before_read_debug.log"
REM echo [%date% %time%] === beforeReadFile hook started === > "%LOG_FILE%"

REM Read input from stdin
set "input="
for /f "delims=" %%i in ('more') do set "input=!input!%%i"

REM echo [%date% %time%] Input length: !input:~0,100!... >> "%LOG_FILE%"
REM echo [%date% %time%] Full input: !input! >> "%LOG_FILE%"

REM Extract file_path from JSON using PowerShell script with temp file
set "file_path="
set "temp_json=%TEMP%\dontouch_before_read_input.json"
echo !input! > "!temp_json!"
for /f "delims=" %%a in ('powershell -ExecutionPolicy Bypass -File "%~dp0parse_json.ps1" -JsonFile "!temp_json!" -FieldName "file_path"') do set "file_path=%%a"
del "!temp_json!" 2>nul
if not defined file_path set "file_path=NO_FILE_PATH"

REM echo [%date% %time%] Extracted file_path: !file_path! >> "%LOG_FILE%"

REM Normalize file path (remove double backslashes)
set "file_path=!file_path:\\=\!"
REM echo [%date% %time%] Normalized file_path: !file_path! >> "%LOG_FILE%"

REM Get workspace root using PowerShell script with temp file
set "workspace_root="
set "temp_json=%TEMP%\dontouch_before_read_input.json"
echo !input! > "!temp_json!"
for /f "delims=" %%a in ('powershell -ExecutionPolicy Bypass -File "%~dp0parse_json.ps1" -JsonFile "!temp_json!" -FieldName "workspace_roots"') do set "workspace_root=%%a"
del "!temp_json!" 2>nul
if not defined workspace_root set "workspace_root=NO_WORKSPACE_ROOT"

REM echo [%date% %time%] Extracted workspace_root: !workspace_root! >> "%LOG_FILE%"

REM Convert Unix-style path to Windows-style path
if "!workspace_root:~0,1!" equ "/" (
    set "workspace_root=!workspace_root:~1!"
    set "workspace_root=!workspace_root:/=\!"
)
REM echo [%date% %time%] Converted workspace_root: !workspace_root! >> "%LOG_FILE%"

REM Check if file exists and read first 2 lines
if exist "!file_path!" (
    REM echo [%date% %time%] File exists: !file_path! >> "%LOG_FILE%"
    REM Read first 2 lines and check for DONTOUCH or common typos
    REM Matches: DONTOUCH, DONTTOUCH, DON'TOUCH, DON'TTOUCH
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
        if !line_count! geq 2 goto :check_result
    )
    
    :check_result
    REM echo [%date% %time%] DONTOUCH found: !found_dontouch! >> "%LOG_FILE%"
    if !found_dontouch! equ 1 (
        REM echo [%date% %time%] Creating backup... >> "%LOG_FILE%"
        REM Create .dontouch folder
        if not exist "!workspace_root!\.dontouch" (
            mkdir "!workspace_root!\.dontouch"
            REM echo [%date% %time%] Created .dontouch folder >> "%LOG_FILE%"
        )
        
        REM Create hash from file path (consistent hashing)
        for /f %%i in ('powershell -command "$md5 = [System.Security.Cryptography.MD5]::Create(); $hash = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes(\"!file_path!\")); [System.BitConverter]::ToString($hash).Replace(\"-\",\"\").ToLower()" 2^>nul') do set "file_hash=%%i"
        REM echo [%date% %time%] File hash: !file_hash! >> "%LOG_FILE%"
        REM echo [%date% %time%] Backup path: !workspace_root!\.dontouch\!file_hash! >> "%LOG_FILE%"
        copy "!file_path!" "!workspace_root!\.dontouch\!file_hash!" >nul 2>&1
        REM echo [%date% %time%] Backup created >> "%LOG_FILE%"
    )
) else (
    REM echo [%date% %time%] File does NOT exist: !file_path! >> "%LOG_FILE%"
)

REM Always allow the operation
REM echo [%date% %time%] Returning: allow >> "%LOG_FILE%"
echo {"permission":"allow"}
exit /b 0


