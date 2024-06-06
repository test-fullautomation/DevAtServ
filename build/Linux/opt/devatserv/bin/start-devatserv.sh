#!/bin/bash

set -e

source /opt/share/util/format.sh

pre_check_installation() {
  echo -e "${MSG_INFO} Starting pre-check-installation"

  if ! command -v docker &> /dev/null; then
    echo -e "${MSG_ERR} Failed to find 'docker'"
    echo "Please ensure 'docker' is installed on your machine before proceeding with the installation of this application."
    echo "Or you can run script: /opt/share/util/install_docker_lx.sh to install it"
    return 1
  fi
  
  if ! docker compose >/dev/null 2>&1; then
    echo -e "${MSG_ERR} Failed to find 'docker-compose'"
    echo "Please ensure 'docker compose' is installed on your machine before proceeding with the installation of this application."
    echo "Or you can run script: /opt/share/util/install_docker_lx.sh to install it"
    return 1
  fi
  
  echo -e "${MSG_DONE} Pre-check-installation completed successfully"
}

load_devatserv() {
  echo "Loading DevAtServ's docker images"
  /opt/devatserv/bin/load-devatserv.sh
}

cd /opt/devatserv/share/start-services

start_devatserv() {
  echo "Starting DevAtServ's docker containers"

  if ! docker compose >/dev/null 2>&1; then
    echo "failed to find 'docker compose'"
    echo "Please ensure Docker is installed on your machine before proceeding with the installation of this application."
    echo "Or you can run script: /opt/devatserv/share/util/install_docker_lx.sh to install it"
    return 1
  fi

  if ! docker compose up --remove-orphans -d; then
    echo "Could not start. Check for errors above."
    return 1
  fi

  show_success_message
}

show_success_message() {
  cat <<EOF
Device Automation Services App successfully deployed!
You can access the website at http://localhost:15672 to access RabbitMQ Management
---------------------------------------------------
EOF
}


main() {
  echo "Starting DevAtServ installation..."

  pre_check_installation || {
    echo 'error pre-check installation'
    return -1
  }

  load_devatserv || {
    echo 'error loading Docker images'
    return -1
  }

  start_devatserv || {
    echo 'error starting Docker containers'
    return -1
  }

  read -p "Press Enter to continue..."
}

############################
# main execution
############################
main
res=$?
if [ $res != 0 ]; then 
  echo "DevAtServ occurs error, please check and install it later."
fi