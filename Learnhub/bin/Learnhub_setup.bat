@echo off

set POSTGRES_INSTALLER="%~dp0postgresql-14.exe"
set INSTALL_DIR="%~dp0SQL\14"
set DATA_DIR="%~dp0SQL\14\data"
set SUPERUSER=postgres 
set SUPERUSER_PASSWORD=admin
set "DB_PORT="
set DB_NAME=learnhub
set ReactFilePath=%~dp0knowledgeVistaFrontend
set filePath1="%~dp0data\Learnhub_custom_input.txt"
:: Define JDK installer path (current directory)
set "JDK_INSTALLER=%~dp0jdk-17.exe"
set "INSTALLDIR=C:\Program Files\Java\jdk-17"
set "CURRENT_DIR=%~dp0"
:: Get current directory
set "INSTALLER_PATH=%~dp0node-v22.msi"

:: Check for Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator access...
    powershell -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)


:: Check if the installer exists
if not exist %POSTGRES_INSTALLER% (
    echo Installer not found at %POSTGRES_INSTALLER%. Exiting...
    exit /b 1
)


:: Use PowerShell to extract the values for PORT1, PORT2, and PORT3
for /f "tokens=2 delims=:" %%A in ('findstr /r "^sql.server.port:" "%filePath1%"') do set "DB_PORT=%%A"

:: Trim spaces
for /f "delims= " %%A in ("%DB_PORT%") do set "DB_PORT=%%A"

echo port %DB_PORT%. 

:: Continue with the PostgreSQL installation...
:: Create installation and data directories
mkdir %INSTALL_DIR%

:: Install PostgreSQL
echo Installing PostgreSQL...
%POSTGRES_INSTALLER% --mode unattended ^
    --prefix %INSTALL_DIR% ^
    --datadir %DATA_DIR% ^
    --superaccount %SUPERUSER% ^
    --superpassword %SUPERUSER_PASSWORD% ^
    --servicename "postgresql-14" ^
    --serverport %DB_PORT%

:: Check if installation succeeded
if %errorlevel% neq 0 (
    echo PostgreSQL installation failed with error code %errorlevel%.
    exit /b %errorlevel%
) else (
    echo PostgreSQL installation completed successfully.
)

set errorlevel=0
:: Ensure the port is set correctly in postgresql.conf
set PG_CONF=%DATA_DIR%\postgresql.conf
if exist %PG_CONF% (
    echo Setting port in postgresql.conf to %DB_PORT%...
    powershell -Command "(Get-Content -Path '%PG_CONF%') -replace '^#?port = \d+', 'port = %DB_PORT%' | Set-Content -Path '%PG_CONF%'"
    echo Restarting PostgreSQL service...
    net stop postgresql-14
    net start postgresql-14
) else (
    echo postgresql.conf not found. Port configuration could not be updated.
)

set errorlevel=0

:: Set the password in the environment variable
set PGPASSWORD=%SUPERUSER_PASSWORD%

:: Create the database and grant all privileges to the superuser
echo Creating database %DB_NAME% and granting privileges to %SUPERUSER%...
"%INSTALL_DIR%\bin\psql.exe" -U %SUPERUSER% -p %DB_PORT% -c "CREATE DATABASE %DB_NAME%;"
if %errorlevel% neq 0 (
    echo Failed to create database. Exiting...
    exit /b %errorlevel%
)

set errorlevel=0
"%INSTALL_DIR%\bin\psql.exe" -U %SUPERUSER% -p %DB_PORT% -c "GRANT ALL PRIVILEGES ON DATABASE %DB_NAME% TO %SUPERUSER%;"
if %errorlevel% neq 0 (
    echo Failed to grant privileges. Exiting...
    exit /b %errorlevel%
)
:: Clean up the PGPASSWORD environment variable
set PGPASSWORD=


:: Install Java for all users silently
start /wait "" "%JDK_INSTALLER%" /s INSTALLDIR="%INSTALLDIR%"

echo Java installation completed. Proceeding with JAVA_HOME setup...
 

:: Set JAVA_HOME system-wide
setx JAVA_HOME "%INSTALLDIR%" /M

:: Update PATH system-wide
setx PATH "%INSTALLDIR%\bin;%PATH%" /M

echo JAVA_HOME and PATH have been updated globally.

set errorlevel=0
:: Additional commands to update PostgreSQL configuration, restart service, etc.
:: Check if Node.js is installed

:: Check if Node.js is installed
echo Checking if Node.js is installed...
echo Error Level after checking Node.js: %errorlevel%

:: Check if the installer exists
if not exist "%INSTALLER_PATH%" (
    echo ERROR: node-v22.msi not found in the script directory!
    exit /b 1
)

:: Run the Node.js installer silently
echo Installing Node.js...
start /wait msiexec /i "%INSTALLER_PATH%" /quiet /norestart

:: Refresh PATH so npm is recognized
set PATH=%ProgramFiles%\nodejs;%AppData%\npm;%PATH%

set errorlevel=0
:: Check if npm is available
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: npm is not recognized. Restart your PC or open a new command prompt.
    exit /b 1
)

:: Check if 'serve' is installed using "where serve"
echo Serve is not installed. Installing serve globally...
call npm install -g serve

    
:: Re-check if serve is installed using "where serve"
where serve >nul 2>nul
echo Error Level after installing serve: %errorlevel%
echo Serve is already installed.


echo Setup completed!


