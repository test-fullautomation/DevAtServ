#!/bin/bash

set -e

source ./util/format.sh
source ./util/common.sh

get_config_file() {
    local input_config_file=$1
    local default_config_file="$WORKSPACE/config/repositories.conf"

    if [[ -n "$input_config_file" ]]; then
        CONFIG_SERVICE_FILE="$input_config_file"
    else
        CONFIG_SERVICE_FILE="$default_config_file"
    fi

    echo -e "${MSG_INFO} Using config file: $CONFIG_SERVICE_FILE"
}

install_services () {

	echo -e "${MSG_INFO} Cloning all services to repos..."

	resolved_config_file=$(realpath "$CONFIG_SERVICE_FILE")

	if [ -f "$resolved_config_file" ]; then
		greenmsg "Found the configuration file to clone all services at: '$CONFIG_SERVICE_FILE'"
	else
		errormsg "Repo configuration '$CONFIG_SERVICE_FILE' is not existing"
	fi
	
	# Parse and clone all services
	parse_config $CONFIG_SERVICE_FILE
}

start_docker_compose() {
	echo -e "${MSG_INFO} Starting the DevArtServ Docker containers"

	parse_supported_server $CONFIG_SERVICE_FILE

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
        echo "Could not start. Check for errors above."
        exit 1
    fi
}

create_storage_directory() {
    local repos_dir='./storage'

    echo -e "${MSG_INFO} Creating storage for all DevAtServ images service..."

    if [[ -e $repos_dir ]]; then
        echo "Directory $repos_dir already exists."
    else
        mkdir -p "$repos_dir" || return
    fi
}

archive_all_services() {

    echo -e "${MSG_INFO} Archiving all DevAtServ services..."

	create_storage_directory || {
        echo 'error creating storage directory' 
        return 1
	}

    parse_services $CONFIG_SERVICE_FILE

    for service in "${list_services[@]}"
    do
        service_name=${service#${service_type}.}
        output_file="./storage/${service_name}.tar.gz"

        docker image save --output "$output_file" "$service_name"
        if [ "$?" -ne 0 ]; then
            exit 1
        fi
    done
    
    # Archiving
    zip $DAS_IMAGES_SERVICES ./storage/*
    if [ $? -eq 0 ]; then
        echo -e "${MSG_DONE} Got devatserv_images.zip successfully."
    else
        echo -e "${MSG_ERR} Failed to get DevAtServ archivement."
        exit 1
    fi
}

main() {
    echo -e "${MSG_INFO} Starting DevArtServ inslallation..."
    
    local config_file=$1
    get_config_file $config_file || {
        echo 'error getting config file'
        return 1
    }

    install_services || {
        echo 'error installing service' 
        return 1
    }

    # Build and start the services
    start_docker_compose || {
        echo 'error starting Docker' 
        return 1
    }

	archive_all_services || {
        echo 'error archiving services' 
        return 1
    }

    echo -e "${MSG_DONE} All services are running..."
    return 0 
}

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -f, --config-file   <config_file>   Input a specified config file"
    echo "  -i, --install       <config_file>   Install services using specified config file"
    echo "  -c, --clone                         Clone and update services"
    echo "  -s, --start                         Build and start Docker Compose services"
    echo "  -a, --archive                       Archive all services"
    echo "  -h, --help                          Show this help message"
}

# Parse command-line arguments
if [[ "$#" -eq 0 ]]; then
    # If no arguments
    main
else
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--config-file) # Input config file
                config_file="$2"
                if [[ -z "$config_file" ]]; then
                    echo "Error: Missing input config file"
                    show_help
                    exit 1
                fi
                get_config_file $config_file
                shift 2
                ;;
            -i|--install) # Install services
                config_file="$2"
                if [[ -z "$config_file" ]]; then
                    echo "Error: Missing config file for install option"
                    show_help
                    exit 1
                fi
                main $config_file
                shift 2
                ;;
            -c|--clone) # Clone services
                install_services || {
                    echo 'Error cloning service' 
                    exit 1
                }
                shift 
                ;;
            -s|--start) # Start Docker Compose services
                start_docker_compose || {
                    echo 'Error starting Docker' 
                    exit 1
                }
                shift
                ;;
            -a|--archive) # Archive all services
                archive_all_services || {
                    echo 'Error archiving services' 
                    exit 1
                }
                shift
                ;;
            -h|--help) # Show help
                show_help
                exit 0
                ;;
            *) # Unknown option
                echo "Error: Invalid option $1"
                show_help
                exit 1
                ;;
        esac
    done
fi