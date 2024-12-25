@echo off


REM Run rabbitmq-service.bat with specified arguments
if exist "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" (
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" install
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" enable
    call "%RABBITMQ_HOME%\sbin\rabbitmq-service.bat" start
) else (
    echo %RABBITMQ_HOME%\sbin\rabbitmq-service.bat not found in the specified path.
)