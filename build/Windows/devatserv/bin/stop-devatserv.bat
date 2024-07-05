@echo off
setlocal

REM Directory to store all images
set SERVICE_DIR=%~dp0..\share\start-services

REM Move to images storage
cd /d "%SERVICE_DIR%"

REM Stop and delete all container, image, volume and orphans
docker compose down --rmi all --volumes --remove-orphans


