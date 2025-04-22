@echo off
setlocal enabledelayedexpansion
REM --------------------------------------------PostgreSQL service---------------------------------------------------------
set "fileLocation=%~dp0SQL\15\"
set "SERVERPATH=bin\pg_ctl"
set "port="
set EXE_PATH="%~dp0\mediajungle.exe"
set ReactFilePath="%~dp0mediaReact"
set filePath1="%~dp0data\media_custom_input.txt"
REM Start the PostgreSQL server


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

REM Stop the PostgreSQL server
"%fileLocation%%SERVERPATH%" stop -D "%fileLocation%data" -o "-p %port%"

echo Launching SQL server...
"%fileLocation%%SERVERPATH%" start -D "%fileLocation%data" -o "-p %port%"

REM Wait for the server to initialize
timeout /t 2 /nobreak >nul


:: Find the process ID (PID) using port 4002
for /f "tokens=5" %%a in ('netstat -aon ^| findstr LISTENING ^| findstr :4002') do (
    set "PID=%%a"
)

:: Check if PID was found
if defined PID (
   :: Terminate the process using the found PID
    taskkill /PID %PID% /F
) else (
    echo .
)

if not exist %EXE_PATH% (
    echo media.exe not found at %EXE_PATH%. Exiting...
    exit /b 1
)

echo Launching Tomcat ...
start "" %EXE_PATH%
set "port="


REM Wait for the server to initialize
timeout /t 10 /nobreak >nul

:: Find the process ID (PID) using port 4003
for /f "tokens=5" %%a in ('netstat -aon ^| findstr LISTENING ^| findstr :4003') do (
    set "PID=%%a"
)

:: Check if PID was found
if defined PID (
    :: Terminate the process using the found PID
    taskkill /PID %PID% /F
) else (
    echo .
)

REM Wait for the server to initialize
timeout /t 5 /nobreak >nul

REM Clear the screen before exiting
cls

REM Step 2: Run npm start in the background
echo Launching ....
cd /d "%ReactFilePath%"
start http://localhost:4003
:: Start the server silently in the background without any window appearing
start "" /B cmd /c "serve -s build -l 4003>nul 2>&1"


REM Close the batch file immediately after starting the server
exit

REM Reset errorlevel to 0 before executing the script
cmd /c exit 0

endlocal
