@echo off
setlocal enabledelayedexpansion
REM --------------------------------------------PostgreSQL service---------------------------------------------------------
set "fileLocation=%~dp0SQL\14\"
set "SERVERPATH=bin\pg_ctl"
set "port="
set EXE_PATH="%~dp0\Learnhub.exe"
set ReactFilePath="%~dp0knowledgeVistaFrontend"
set filePath1="%~dp0data\Learnhub_custom_input.txt"
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


:: Find the process ID (PID) using port 5002
for /f "tokens=5" %%a in ('netstat -aon ^| findstr LISTENING ^| findstr :5002') do (
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
    echo Learnhub.exe not found at %EXE_PATH%. Exiting...
    exit /b 1
)

echo Launching Tomcat ...
start "" %EXE_PATH%
set "port="


REM Wait for the server to initialize
timeout /t 10 /nobreak >nul

:: Find the process ID (PID) using port 5003
for /f "tokens=5" %%a in ('netstat -aon ^| findstr LISTENING ^| findstr :5003') do (
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
start http://localhost:5003
:: Start the server silently in the background without any window appearing
start "" /B cmd /c "serve -s build -l 5003>nul 2>&1"

REM Close the batch file immediately after starting the server
exit

REM Reset errorlevel to 0 before executing the script
cmd /c exit 0

endlocal
