@echo off

echo Running Base Service
start "Base Service" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceBase\ServiceRegistry\ServiceRegistry.py""
echo Running Cleware Swtich Service
start "Cleware Switch Service" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceClewareSwitch\ServiceCleware.py""
echo Running Debug Board Service
start "Debug Board Service" /d "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard" cmd /k ""%DevAtServ%\python.exe" "%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\ServiceDebugboard.py" --use_remote_tools --remotetools_path="%DEVATSERV_HOME%\python39\Lib\site-packages\MicroserviceDebugboard\tools\remote_tools\windows\Gen5DBG_RemoteCtrl.exe""
