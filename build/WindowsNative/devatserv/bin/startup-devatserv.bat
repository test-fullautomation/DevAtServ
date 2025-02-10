@echo off

echo [INFO] Start up Remote Tool...
start "" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\tools\remote_tools\windows\Gen5DBG_RemoteCtrl.exe"

@REM echo Running Base Service
@REM start "Base Service" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceBase\ServiceRegistry\ServiceRegistry.py""
@REM echo Running Cleware Swtich Service
@REM start "Cleware Switch Service" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceClewareSwitch\ServiceCleware.py""
@REM echo Running Debug Board Service
@REM start "Debug Board Service" /d "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\ServiceDebugboard.py" --use_remote_tools --remotetools_path="%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\tools\remote_tools\windows\Gen5DBG_RemoteCtrl.exe""
