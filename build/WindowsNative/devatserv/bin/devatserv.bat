@echo off

REM Check if the DEVATSERV_HOME environment variable is set
if "%DEVATSERV_HOME%" == "" (
    echo ERROR: DEVATSERV_HOME environment variable is not set.
    echo Please set DEVATSERV_HOME to the root directory of DevAtServ.
    exit /b 1
)

REM Check if NSSM exists
if not exist "%DEVATSERV_HOME%\share\nssm\nssm.exe" (
    echo ERROR: NSSM not found at %DEVATSERV_HOME%\share\nssm\nssm.exe.
    echo Please ensure NSSM is installed correctly.
    exit /b 1
)

REM Handle command
if "%1" == "start" (
    echo Starting DevAtServ services...
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" start BaseService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" start ClewareSwitchService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" start DebugBoardService
    echo All services started.
) else if "%1" == "stop" (
    echo Stopping DevAtServ services...
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" stop BaseService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" stop ClewareSwitchService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" stop DebugBoardService
    echo All services stopped.
) else if "%1" == "restart" (
    echo Restarting DevAtServ services...
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" restart BaseService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" restart ClewareSwitchService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" restart DebugBoardService
    echo All services restarted.
) else if "%1" == "status" (
    echo Restarting DevAtServ services...
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" status BaseService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" status ClewareSwitchService
    "%DEVATSERV_HOME%\share\nssm\nssm.exe" status DebugBoardService
    echo All services restarted.
) else (
    echo Usage: %~nx0 [start|stop|restart|status]
    echo Please specify a valid command.
    exit /b 1
)

REM End script
exit /b 0