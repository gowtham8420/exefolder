@echo off
setlocal enabledelayedexpansion
REM --------------------------------------------PostgreSQL service---------------------------------------------------------
set "fileLocation=%~dp0SQL\14\"
set "SERVERPATH=bin\pg_ctl"
set "port="
set EXE_PATH="%~dp0\Learnhub.exe"
set filePath1="%~dp0data\Learnhub_custom_input.txt"
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    :: Relaunch the script with administrator privileges
    powershell -command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: Use PowerShell to extract the values for PORT1, PORT2, and PORT3
for /f "tokens=2 delims=:" %%A in ('findstr /r "^sql.server.port:" "%filePath1%"') do set "port=%%A"

:: Trim spaces
for /f "delims= " %%A in ("%port%") do set "DB_PORT=%%A"


set "port="


:: Stop PostgreSQL using pg_ctl
"%fileLocation%%SERVERPATH%" stop -D "%fileLocation%data" -o "-p %port%"

if %errorlevel% neq 0 (
    echo Failed to stop PostgreSQL server.
) else (
    echo PostgreSQL server stopped successfully.
)

 

:: Find the process ID (PID) using port 5002
for /f "tokens=5" %%a in ('netstat -aon ^| findstr LISTENING ^| findstr :5002') do (
    set "PID=%%a"
)

:: Check if PID was found
if defined PID (
    :: Terminate the process using the found PID
    taskkill /PID %PID% /F
) else (
    echo Port 5002 is not in use.
)


:: Step 1: Find the process ID (PID) using port 5003
for /f "tokens=5" %%a in ('netstat -aon ^| findstr LISTENING ^| findstr :5003') do (
    set "PID=%%a"
)

:: Step 2: Check if PID was found
if defined PID (
    :: Step 3: Terminate the process using the found PID
    taskkill /PID %PID% /F
    ) else (
    echo Port 5003 is not in use.
)

endlocal








