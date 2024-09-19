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

load_devatserv() {
  echo -e "${MSG_INFO} Loading DevAtServ's docker images"
  /opt/devatserv/bin/load-devatserv.sh
  echo -e "${MSG_DONE} All images are loaded successfully"
}

cd /opt/devatserv/share/start-services

start_devatserv() {
  echo -e "${MSG_INFO} Starting DevAtServ's docker containers"

	docker_compose_files=("docker-compose.yml")

	# Check if USB device exists
	if [ -c /dev/usb/hiddev0 ]; then
  		docker_compose_files+=("docker-compose.usbcleware.yml")
	fi
.
	# Check if ttyUSB device exists
	if [ -c /dev/ttyUSB0 ]; then
		docker_compose_files+=("docker-compose.ttyusb.yml")
	fi
  
	compose_options=""
	for file in "${docker_compose_files[@]}"; do
		compose_options="$compose_options -f $file"
	done

  echo -e "${MSG_INFO} docker compose $compose_options up --remove-orphans -d"
	if ! docker compose $compose_options up --remove-orphans -d; then
    echo -e "${MSG_ERR} Could not start. Check for errors above."
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

exit_after_countdown() {

  exit_after_time=10
  elapsed_time=0
  interval=1

  # Hide cursor
  tput civis

  while [ $elapsed_time -lt $exit_after_time ]; do
      # Wait for an interval
      read -t $interval -n 1 input
      if [ $? -eq 0 ]; then
          echo -e "\nKey pressed. Exiting."
          # Show the cursor
          tput cnorm
          exit 0
      fi

      elapsed_time=$((elapsed_time + interval))
      remaining_time=$((exit_after_time - elapsed_time))
      
      # Update the remain time
      printf "\rPress any key to exit early in %ds" $remaining_time
  done

  tput cnorm
  exit 0
}

handle_error() {
  echo -e "${MSG_ERR} $1"
  read -p "Press Enter to continue..."
  exit -1
}

main() {
  echo "Starting DevAtServ installation..."

  pre_check_installation || handle_error 'Error pre-check installation'

  install_gui_devatserv || handle_error 'Error installing DevAtServ GUI'

  load_devatserv || handle_error 'Error loading Docker images'

  start_devatserv || handle_error 'Error starting Docker containers'
  
  exit_after_countdown || handle_error 'Error exiting'

  return 0
}

############################
# main execution
############################
main
res=$?
if [ $res != 0 ]; then 
  echo "DevAtServ occurs error, please check and install it later."
fi