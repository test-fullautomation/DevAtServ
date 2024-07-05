@echo off
setlocal enabledelayedexpansion



:LOAD_DEVATSERV
echo Loading DevAtServ's docker images
REM Call the script to load DevAtServ images
call "%~dp0load-devatserv.bat"


:START_DEVATSERV
cd ..\share\start-services\
echo Starting DevAtServ's docker containers

docker-compose up --remove-orphans -d
if %errorlevel% neq 0 (
    echo Could not start. Check for errors above.
    goto :HANDLE_ERROR
)

call :SHOW_SUCCESS_MESSAGE
goto :END

:SHOW_SUCCESS_MESSAGE
echo Device Automation Services App successfully deployed!
echo You can access the website at http://localhost:15672 to access RabbitMQ Management
echo ---------------------------------------------------
goto :EOF

:HANDLE_ERROR
echo Error: %1
pause
exit /b -1

:MAIN
echo Starting DevAtServ installation...

call :LOAD_DEVATSERV
if %errorlevel% neq 0 (
    call :HANDLE_ERROR 'Error loading Docker images'
)

call :START_DEVATSERV
if %errorlevel% neq 0 (
    call :HANDLE_ERROR 'Error starting Docker containers'
)

pause
exit /b 0

:END
endlocal
exit /b 0
