@echo off

if "%1" == "start" (
    echo Starting DevAtServ...
    start "Base Service" cmd /k "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceBase\ServiceRegistry.py"
    start "Cleware Switch Service" cmd /k "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceClewareSwitch\ServiceCleware.py"
    start "Debug Board Service" cmd /k python "%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\ServiceDebugboard.py"
) else if "%1" == "stop" (
    echo Stopping DevAtServ...
    @REM TODO in next action
    @REM taskkill /FI "WINDOWTITLE eq Base Service" /T /F
    @REM taskkill /FI "WINDOWTITLE eq Cleware Switch Service" /T /F
    @REM taskkill /FI "WINDOWTITLE eq Debug Board Service" /T /F
) else (
    echo Usage: %~nx0 [start|stop]
)
