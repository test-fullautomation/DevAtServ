#!/bin/bash
cd /opt/devatserv/share/start-services

# Stop and delete all container, image, volume and orphans
docker compose down --rmi all --volumes --remove-orphans

# Schedule to uninstall DevAtServ'GUI app
systemctl start remove_gui_app.service
