@echo off

REM Run the base service
start "Base Service" cmd /k "%DevAtServ%\python.exe" "%HOMEDRIVE%\python39\Lib\site-packages\MicroserviceBase\ServiceRegistry.py"

REM Run the cleware switch service
start "Cleware Switch Service" cmd /k "%DevAtServ%\python.exe" "%HOMEDRIVE%\python39\Lib\site-packages\MicroserviceClewareSwitch\ServiceCleware.py"

