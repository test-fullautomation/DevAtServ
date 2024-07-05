@echo off
setlocal

REM Directory to store all images
set STORAGE_DIR=%~dp0..\share\storage

REM Move to images storage
cd /d "%STORAGE_DIR%"

REM Load all Docker images from storage
for %%f in (*.tar.gz) do (
    echo Loading Docker image from %%f...
    docker load -i "%%f"
)

endlocal
