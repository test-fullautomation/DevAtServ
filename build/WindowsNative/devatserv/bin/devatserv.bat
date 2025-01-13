@echo off

if "%1" == "start" (
    echo Starting DevAtServ...
    start "Base Service" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceBase\ServiceRegistry\ServiceRegistry.py""
    start "Cleware Switch Service" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceClewareSwitch\ServiceCleware.py""
    start "Debug Board Service" /d "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\ServiceDebugboard.py" --use_remote_tools --remotetools_path="%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\tools\remote_tools\windows\Gen5DBG_RemoteCtrl.exe""
) else if "%1" == "stop" (
    echo Stopping DevAtServ...
    @REM TODO in next action
    @REM taskkill /FI "WINDOWTITLE eq Base Service" /T /F
    @REM taskkill /FI "WINDOWTITLE eq Cleware Switch Service" /T /F
    @REM taskkill /FI "WINDOWTITLE eq Debug Board Service" /T /F
) else (
    echo Usage: %~nx0 [start|stop]
)

