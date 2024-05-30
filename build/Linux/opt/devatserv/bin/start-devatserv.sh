#!/bin/bash

cd /opt/devatserv/share/start-services


start_devatserv() {
  echo "Starting DevAtServ's docker containers"

  if ! docker compose up --remove-orphans -d; then
    echo "Could not start. Check for errors above."
    exit 1
  fi

  show_friendly_message
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
# Starting ...
############################
start_devatserv