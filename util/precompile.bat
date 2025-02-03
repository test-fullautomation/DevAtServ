@echo off
REM NB: Removing any previous association to be sure new one will work
subst R: /D 1> NUL 2>&1
subst R: "%~dp0\..\output_WindowsNative\DevAtServ\"

@REM if "%1"=="" (
@REM     powershell -File "%~dp0\PowerShell\create_project_config.ps1"
@REM ) else (
@REM     powershell -File "%~dp0\PowerShell\create_project_config.ps1" -configFile %1
@REM )