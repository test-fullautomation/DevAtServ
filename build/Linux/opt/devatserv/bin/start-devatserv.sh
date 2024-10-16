#!/bin/bash

set -e

source /opt/devatserv/share/util/format.sh

DAS_GUI_NAME="dasgui"
DAS_GUI_DIR="/opt/devatserv/share/GUI/DevAtServGUI_1.0.0_amd64.deb"

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

install_gui_devatserv() {
  echo -e "${MSG_INFO} Starting DevAtServ's GUI"

  package_status=$(dpkg-query -W -f='${db:Status-Status}\n' $DAS_GUI_NAME 2>/dev/null)
  cur_version=$(dpkg-query -W -f='${Version}' $DAS_GUI_NAME 2>/dev/null || echo "$DAS_GUI_NAME not installed" )
  new_version=$(dpkg-deb -I "$DAS_GUI_DIR" | grep '^ Version:' | awk '{print $2}')

  if [ "$cur_version" = "$new_version" ] && [ "$package_status" = "installed" ]; then
    echo -e "${MSG_DONE} DevAtServ's GUI is already installed with version $cur_version."
  else

    read -p "There are new version $new_version, Do you want to install it? (y/n)" choice
    if [ "$choice" = "Y" ]  || [ "$choice" == "y" ]; then

      echo -e "${MSG_INFO} Installing version $new_version..."

      if sudo dpkg -i $DAS_GUI_DIR; then
        echo -e "${MSG_DONE} DevAtServ's GUI has been installed successfully"
      else
        echo -e "${MSG_ERR} Installation of DevAtServ's GUI failed."
        return 1
      fi
    else
      echo -e "${MSG_INFO} Skip to install the newest DevAtServ's GUI version."
    fi
  fi
}

# Function to remove a module if loaded
remove_module() {
    local module=$1
    if lsmod | grep "$module" &> /dev/null; then
        if sudo rmmod "$module"; then
            echo "$module removed successfully."
        else
            echo -e "${MSG_ERR} Failed to remove $module."
        fi
    fi
}

pre_configuration_services() {
    echo -e "${MSG_INFO} Starting pre-configuration for debug board containers ..." 

    if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ "$XDG_SESSION_TYPE" = "x11" ]; then
        # Grant access to Docker containers
        xhost +local:docker
        if [ $? -eq 0 ]; then
          echo "Docker containers now have access to Display server."
        else
          echo -e "${MSG_ERR} Failed to configure access for Docker containers."
        fi
    else
      echo -e "${MSG_WARN} Display server is not running. Start display server before running debug board service."
    fi

    # Remove module for transfer data debug board
    remove_module "ftdi_sio"
    remove_module "usbserial"
}
# Start up the entire DevAtServ
startup_devatserv() {
  source /opt/devatserv/bin/startup-devatserv.sh
}


# Start DevAtServ
start_devatserv() {
  echo -e "${MSG_INFO} Starting DevAtServ's docker containers"
  cd /opt/devatserv/share/start-services

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
  cd /opt/devatserv/share/start-services
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
  cd /opt/devatserv/share/start-services

  # Stop all containers or specific service
  docker compose stop "$@"
}

restart_devatserv() {
  echo -e "${MSG_INFO} Restarting DevAtServ's docker containers"
  cd /opt/devatserv/share/start-services

  # Restart all containers or specific service
  docker compose restart "$@"
}

rm_devatserv() {
  echo -e "${MSG_INFO} Removing DevAtServ's docker containers"
  cd /opt/devatserv/share/start-services

  # Stop all containers or specific service
  docker compose rm  "$@"
}

down_devatserv() {
  echo -e "${MSG_INFO} Downing DevAtServ's docker containers"
  cd /opt/devatserv/share/start-services

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