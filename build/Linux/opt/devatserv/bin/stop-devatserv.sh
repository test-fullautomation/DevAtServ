#!/bin/bash
cd /opt/devatserv/share/start-services

# Stop and delete all container, image, volume and orphans
docker-compose down --rmi all --volumes --remove-orphans
