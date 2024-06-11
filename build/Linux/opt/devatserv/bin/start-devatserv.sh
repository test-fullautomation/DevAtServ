#!/bin/bash

set -e

source /opt/devatserv/share/util/format.sh

DAS_GUI_NAME="electron"
DAS_GUI_DIR="/opt/share/applications/electron_1.0.0_amd64.deb"

pre_check_installation() {
  echo -e "${MSG_INFO} Starting pre-check-installation"

  if ! command -v docker &> /dev/null; then
    echo -e "${MSG_ERR} Failed to find 'docker'"
    echo -e "${MSG_INFO} Please ensure 'docker' is installed on your machine before proceeding with the installation of this application."
    echo -e "${MSG_INFO} Or you can run script: /opt/devatserv/share/util/install_docker_lx.sh to install it"
    return 1
  fi
  
  if ! docker compose >/dev/null 2>&1; then
    echo -e "${MSG_ERR} Failed to find 'docker compose'"
    echo -e "${MSG_INFO} Please ensure 'docker compose' is installed on your machine before proceeding with the installation of this application."
    echo -e "${MSG_INFO} Or you can run script: /opt/devatserv/share/util/install_docker_lx.sh to install it"
    return 1
  fi

  echo -e "${MSG_DONE} Pre-check-installation completed successfully"
}

install_gui_devatserv() {
  echo -e "${MSG_INFO} Starting DevAtServ's GUI"

  CUR_VERSION=$(dpkg-query -W -f='${Version}' $DAS_GUI_NAME )
  NEW_VERSION=$(dpkg-deb -I "$DAS_GUI_DIR" | grep '^ Version:' | awk '{print $2}')

  if [ "$CUR_VERSION" = "$NEW_VERSION" ]; then
    echo "${MSG_INFO} DevAtServ's GUI is already installed with version $CUR_VERSION."
  else

    read -p "There are new version $NEW_VERSION, Do you want to install it? (y/n)" choice
    if [ "$choice" = "Y" ]  || [ "$choice" == "y" ]; then

      echo "${MSG_INFO} Installing version $NEW_VERSION..."

      if sudo dpkg -i $DAS_GUI_DIR; then
        echo -e "${MSG_DONE} DevAtServ's GUI has been installed successfully"
      else
        echo -e "${MSG_ERR} Installation of DevAtServ's GUI failed."
        return 1
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

  if ! docker compose up --remove-orphans -d; then
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


main() {
  echo "Starting DevAtServ installation..."

  pre_check_installation || {
    echo 'error pre-check installation'
    return -1
  }

  install_gui_devatserv || {
    echo 'error installing DevAtServ GUI'
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
  read -p "Press Enter to exit..."
fi