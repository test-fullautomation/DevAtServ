@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires admin privileges. Restarting with admin rights...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Running with admin rights...
echo Set up pre-configuration...
REM Run rabbitmq-service.bat with specified arguments
if exist "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" (
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" install
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" enable
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" start
) else (
    echo %RABBITMQ_HOME%\sbin\rabbitmq-service.bat not found in the specified path.
)

echo Start up all services...
start "Base Service" cmd /k "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceBase\ServiceRegistry.py"
start "Cleware Switch Service" cmd /k "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceClewareSwitch\ServiceCleware.py"
start "Debug Board Service" cmd /k python "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\ServiceDebugboard.py"

pause