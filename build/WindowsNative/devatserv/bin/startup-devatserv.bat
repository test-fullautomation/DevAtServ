@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires admin privileges. Restarting with admin rights...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [INFO] Running with admin rights...
echo [INFO] Start up RabbitMQ Server...
REM Run rabbitmq-service.bat with specified arguments
if exist "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" (
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" install
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" enable
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" start
) else (
    echo %RABBITMQ_HOME%\sbin\rabbitmq-service.bat not found in the specified path.
)

echo [INFO] Start up all services...
echo Running Base Service
start "Base Service" cmd /k "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceBase\ServiceRegistry.py"
echo Running Cleware Swtich Service
start "Cleware Switch Service" cmd /k "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceClewareSwitch\ServiceCleware.py"
echo Running Debug Board Service
start "Debug Board Service" cmd /k python "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\ServiceDebugboard.py"

pause