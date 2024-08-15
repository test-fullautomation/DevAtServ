#!/bin/bash

set -e

source ./util/format.sh
source ./util/common.sh

install_services () {

	config_file=$1
	echo -e "${MSG_INFO} Cloning all services to repos..."

	resolved_config_file=$(realpath "$config_file")

	if [ -f "$resolved_config_file" ]; then
		greenmsg "Found the configuration file to clone all services at: '$config_file'"
	else
		errormsg "Repo configuration '$config_file' is not existing"
	fi
	
	# Parse and clone all services
	parse_config $config_file
}

start_docker_compose() {
	echo -e "${MSG_INFO} Starting the DevArtServ Docker containers"

	if ! docker compose >/dev/null 2>&1; then
		echo "failed to find 'docker compose'"
		exit 1
	fi
    
	docker_compose_files=("docker-compose.yml")

	# Check for specific SUPPORT_SERVER value
	if [ "$SUPPORT_SERVER" == "gitlab" ]; then
    docker_compose_files+=("docker-compose.debugboard.yml")
	fi

  # Check if USB device exists
  if [ -c /dev/usb/hiddev0 ]; then
    docker_compose_files+=("docker-compose.usbcleware.yml")
  fi

	compose_options=""
	for file in "${docker_compose_files[@]}"; do
		compose_options="$compose_options -f $file"
	done

	if ! docker compose $compose_options up --remove-orphans -d; then
		echo "Could not start. Check for errors above."
		exit 1
	fi
}

main() {
	echo -e "${MSG_INFO} Starting DevArtServ inslallation..."

	install_services $CONFIG_SERVICE_FILE

	# Build and start the services
	start_docker_compose || {
		echo 'error starting Docker' 
		return 1
	}

	echo -e "${MSG_DONE} All services are running..."
	return 0 
}


main
Exit=$?
if [ $Exit != 0 ]; then
	echo "Can't not install DevArtServ successfully..."
fi
