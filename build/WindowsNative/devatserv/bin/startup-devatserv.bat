@echo off


@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires admin privileges. Restarting with admin rights...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Running with admin rights...

REM Ask user if they want to set an environment variable
set /p setEnvVar="Do you want to set HOMEDRIVE variable to the default path (HOMEDRIVE="%RABBITMQ_HOME%")? (Y/N): "
if /i "%setEnvVar%"=="Y" (
	REM echo "%extractPath%\env"
    set HOMEDRIVE="%RABBITMQ_HOME%"
) else (
    set /p customEnvPath="Enter the path to set as HOMEDRIVE variable (if not, leave blank): "
    if not "%customEnvPath%"=="" (
        set HOMEDRIVE="%customEnvPath%"
    )
)


REM Run rabbitmq-service.bat with specified arguments
if exist "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" (
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" install
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" enable
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" start
) else (
    echo %RABBITMQ_HOME%\sbin\rabbitmq-service.bat not found in the specified path.
)

pause

