#!/bin/bash

set -e

source format.sh

pre_check_installation() {
  echo -e "${MSG_INFO} Starting pre-check-installation"
  local err=0

  if ! command -v docker &> /dev/null; then
    echo -e "${MSG_INFO} Installing 'docker'..."
    /opt/devatserv/share/util/install_docker_lx.sh
  fi
  
  if ! docker compose >/dev/null 2>&1; then
    echo -e "${MSG_INFO} Installing 'docker compose'..."
    /opt/devatserv/share/util/install_docker_lx.sh
  fi
  
  if [ $err -eq 0 ]; then 
    if ! command -v docker &> /dev/null || ! docker compose >/dev/null 2>&1; then
      echo -e "${MSG_ERR} Error occurred during Docker installation." 
      err=1
    else
      echo -e "${MSG_DONE} Pre-check-installation completed successfully"
    fi
  fi

  return $err
}

# Start up the entire DevAtServ
startup_devatserv() {
  source startup-devatserv.sh
}


# Start DevAtServ
start_devatserv() {
  echo -e "${MSG_INFO} Starting DevAtServ's docker containers"
  cd ..\\share\\start-services

	docker_compose_files=("docker-compose.yml")

	# Check if USB device exists
  if [ -c /dev/usb/hiddev0 ]; then
    docker_compose_files+=("docker-compose.usbcleware.yml")
  fi

	# Check if ttyUSB device exists
	if [ -f /opt/devatserv/share/start-services/docker-compose.ttyusb.yml ]; then
		docker_compose_files+=("docker-compose.ttyusb.yml")
	fi

	compose_options=""
	for file in "${docker_compose_files[@]}"; do
		compose_options="$compose_options -f $file"
	done

  echo -e "${MSG_INFO} docker compose$compose_options up "$@" --remove-orphans -d"
	if ! docker compose $compose_options up "$@" --remove-orphans -d; then
    echo -e "${MSG_ERR} Could not start. Check for errors above."
    return 1
	fi
}

status_devatserv() {
  echo -e "${MSG_INFO} Status all DevAtServ's services"
  cd ..\\share\\start-services
  
  # Get the list of containers and their statuses
  output=$(docker compose ps "$@" -a --format "table {{.Name}}\t{{.State}}")

  total_containers=$(echo "$output" | tail -n +2 | wc -l)
  running_containers=$(echo "$output" | grep -c "running" || true)
  stopped_containers=$(echo "$output" | grep -c "exited" || true)

  # Print the summary
  echo -e "${COL_BLUE}[+] Running $running_containers/$total_containers:${COL_RESET}"

  # Print status
  echo "$output" | tail -n +2 | while read -r line; do
    container_name=$(echo "$line" | awk '{print $1}')
    container_status=$(echo "$line" | awk '{print $2}')
    
    if [[ "$container_status" == "running" ]]; then
      printf "Container %-20s ${COL_GREEN}%s${COL_RESET}\n" "$container_name" "$container_status"
    elif [[ "$container_status" == "exited" ]]; then
      printf "Container %-20s ${COL_RED}%s${COL_RESET}\n" "$container_name" "$container_status"
    else
      printf "Container %-20s %s\n" "$container_name" "$container_status"
    fi
  done
}

stop_devatserv() {
  echo -e "${MSG_INFO} Stopping DevAtServ's docker containers"
  cd ..\\share\\start-services

  # Stop all containers or specific service
  docker compose stop "$@"
}

restart_devatserv() {
  echo -e "${MSG_INFO} Restarting DevAtServ's docker containers"
  cd ..\\share\\start-services

  # Restart all containers or specific service
  docker compose restart "$@"
}

rm_devatserv() {
  echo -e "${MSG_INFO} Removing DevAtServ's docker containers"
  cd ..\\share\\start-services

  # Stop all containers or specific service
  docker compose rm  "$@"
}

down_devatserv() {
  echo -e "${MSG_INFO} Downing DevAtServ's docker containers"
  cd ..\\share\\start-services

  # Stop all containers or specific service
  docker compose down  "$@"
}

# Load images of DevAtServ
load_devatserv() {
  echo -e "${MSG_INFO} Loading DevAtServ's docker images"
  # Directory to store all images
  STORAGE_DIR=/opt/devatserv/share/storage
  # Move to images storage
  cd "$STORAGE_DIR"
  # Load all Docker images from storage
  for IMAGE_FILE in "$STORAGE_DIR"/*.tar.gz; do
    echo "Loading Docker image from $IMAGE_FILE..."
    docker load -i "$IMAGE_FILE"
  done

  echo -e "${MSG_DONE} All images are loaded successfully"
}

############## DevAtServ GUI ##################
startup_devatservGUI() {

  if [ -f "/opt/DevAtServGUI/dasgui" ]; then
      echo -e "${MSG_INFO} Running the DevAtServ GUI application..."
      /opt/DevAtServGUI/dasgui > /dev/null 2>&1 &
  else
      echo -e "${MSG_ERR} DevAtServ GUI does not exist. Please run "devatserv startup" to install it"
      exit 1
  fi
}