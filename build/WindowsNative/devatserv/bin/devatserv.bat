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
    if "%2"=="" (
        echo Starting all DevAtServ services...
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" start BaseService
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" start ClewareSwitchService
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" start DebugBoardService
        echo All services started.
    ) else (
        echo Starting service: %2...
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" start %2
        echo Service %2 started.
    )
) else if "%1" == "stop" (
    if "%2"=="" (
        echo Stopping all DevAtServ services...
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" stop BaseService
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" stop ClewareSwitchService
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" stop DebugBoardService
        echo All services stopped.
    ) else (
        echo Stopping service: %2...
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" stop %2
        echo Service %2 stopped.
    )    
) else if "%1" == "restart" (
    if "%2"=="" (
        echo Restarting all DevAtServ services...
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" restart BaseService
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" restart ClewareSwitchService
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" restart DebugBoardService
        echo All services restarted.
    ) else (
        echo Restarting service: %2...
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" restart %2
        echo Service %2 restarted.
    )
) else if "%1" == "status" (
    if "%2"=="" (
        echo Status service BaseService: 
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" status BaseService
        echo Status service ClewareSwitchService: 
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" status ClewareSwitchService
        echo Status service DebugBoardService: 
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" status DebugBoardService
    ) else (
        echo Status service: %2...
        "%DEVATSERV_HOME%\share\nssm\nssm.exe" status %2
    )
) else (
    echo Usage: %~nx0 [start|stop|restart|status]
    echo Please specify a valid command.
    exit /b 1
)

REM End script
exit /b 0