#!/bin/bash

set -e 

load_devatserv() {
  echo "Loading DevAtServ's docker images"
  /opt/devatserv/bin/load-devatserv.sh
}

cd /opt/devatserv/share/start-services

start_devatserv() {
  echo "Starting DevAtServ's docker containers"

  if ! docker compose up --remove-orphans -d; then
    echo "Could not start. Check for errors above."
    return 1
  fi

  show_success_message
}

show_success_message() {
  local ip_address
  ip_address=$(hostname -I | awk '{print $1}')
  cat <<EOF
Device Automation Services App successfully deployed!
You can access the website at http://$ip_address:15672 to access RabbitMQ Management
---------------------------------------------------
EOF
}

############################
# main
############################
main() {
  echo "Starting DevAtServ installation..."

  load_devatserv || {
    echo 'error loading Docker images '
    exit 1
  }

  start_devatserv || {
    echo 'error starting Docker containers'
    exit 1
  }

  read -p "Press Enter to continue..."
}

