#!/bin/bash

set -e

source ./util/format.sh
source ./util/common.sh



######################## Environments ########################
###### Platforms
UNAME=$(uname)
if [ "$UNAME" == "Linux" ] ; then
    PLATFORM="Linux"
elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
    PLATFORM="Windows"
else
    errormsg "Operation system '$UNAME' is not supported."
fi

###### Project env
CONFIG_SERVICE_FILE="$WORKSPACE/config/repositories/repositories.conf"
CONFIG_DEBIAN_FILE="$WORKSPACE/build/Linux/DEBIAN/control"

if [ -f $CONFIG_DEBIAN_FILE ]; then
    VERSION=`sed '2q;d' $CONFIG_DEBIAN_FILE | cut -c 10-`
else
    echo -e "${MSG_ERR} DEBIAN control file not found."
    exit 1
fi

###### Pipeline
DASVersion=""
TypeOfBuild=""
if [[ "$TRIGGER_BY" == "tag" ]] && [[ "$TAG_NAME" =~ $TAG_REGEX ]]; then
    TypeOfBuild="Triggered by a TAG"
    DASVersion=`echo $TAG_NAME | sed -E -e "s/(rel|dev)\///g" | sed -E -e "s/das\///g"`
elif [ -n "$REF_NAME" ]; then
    if [ "$REF_NAME" == "$DEFAULT_REF" ]; then
        TypeOfBuild="Triggered by a merged pull request branch"
        DASVersion=`echo merged_$REF_NAME | sed -e "s/\//-/g"`
    elif [ -n "$REPOSITORY"  ] && [ -n "$PULL_REQUEST_BRANCH" ]; then 
        TypeOfBuild="Triggered by other repository"
        DASVersion=`echo triggered_by_$REPOSITORY | sed -e "s/\//-/g"`
    else
        TypeOfBuild="Triggered by any branch manually"
        DASVersion=`echo dev_$REF_NAME | sed -e "s/\//-/g"`
    fi
else
    TypeOfBuild="Triggered on local"
    DASVersion=$VERSION
fi

######################## DevAtServ tool info ########################
###### DevAtServ info
DAS_VERSION=$DASVersion
DAS_NAME=DevAtServ
DAS_PACK_NAME=${DAS_NAME}_${DAS_VERSION}
DAS_PACK_SRC_DIR="./build/${PLATFORM}"
DAS_PACK_DEST_DIR="./output_${PLATFORM}/${DAS_NAME}"
DAS_DEBIAN_NAME="${DAS_PACK_NAME}-0_amd64.deb"
DAS_WINDOW_NAME="${DAS_PACK_NAME}-setup.exe"

###### DevAtServ's GUI info



#################### functionality ########################
function update_version_debian() {
    echo -e "${MSG_INFO} Updating a new version..."

    new_version=$1
    if [[ "$new_version" =~ $VERSION_REGEX ]] && [ "$new_version" != "$VERSION" ]; then
        echo -e "${MSG_INFO} A new version: '$new_version'. Updating to $CONFIG_DEBIAN_FILE "
        sed -i "s/\(Version: \)[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}/\1$new_version/" $CONFIG_DEBIAN_FILE
    fi
}

function prepare_docker_compose_for_deployment() {

    echo -e "${MSG_INFO} Prepare docker compose file for deployment..."

    parse_supported_server $CONFIG_SERVICE_FILE
    # Check for specific SUPPORT_SERVER value
    if [ "$SUPPORT_SERVER" == "gitlab" ]; then
        cp -rf ./build/Linux/opt/devatserv/share/start-services/docker-compose.gitlab.yml \
                ./build/Linux/opt/devatserv/share/start-services/docker-compose.yml

        cp -rf ./build/Windows/devatserv/share/start-services/docker-compose.gitlab.yml \
                ./build/Windows/devatserv/share/start-services/docker-compose.yml

        echo "Replace docker-compose.gitlab.yml with docker-compose.yml for Docker Compose deployment."

    elif [ "$SUPPORT_SERVER" == "github" ]; then
        echo "Docker compose deployment: docker-compose.yml"
    else
        errormsg "Docker compose file not found"
    fi

    # prepare compose file configuration for USB Cleware
    cp -rf docker-compose.usbcleware.yml \
        ./build/Linux/opt/devatserv/share/start-services/

    # prepare compose file configuration for ttyUSB Debug Board
    cp -rf docker-compose.ttyusb.yml \
        ./build/Linux/opt/devatserv/share/start-services/
}

function pre_build_debian() {
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}#          Compiling DevAtServ setup on Unbuntu...                                 #${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

    # Display info for compiling
    echo -e "${MSG_INFO} DevAtServ tool info..."
    echo "DAS Version: $DAS_VERSION"
    echo "Package Name: $DAS_PACK_NAME"
    echo "Source Directory: $DAS_PACK_SRC_DIR"
    echo "Destination Directory: $DAS_PACK_DEST_DIR"
    echo "Debian Package Name: $DAS_DEBIAN_NAME"
    
    # Update a new version to control file
    update_version_debian $DAS_VERSION

    # Prepare Docker compose for deployment
    prepare_docker_compose_for_deployment

    # Prepare all images services for debian tools
    echo -e "${MSG_INFO} Extracting all DevAtServ services..."
    # Extract storage/*.tar.gz to share folder
    unzip $DAS_IMAGES_SERVICES -d ./build/Linux/opt/devatserv/share/
    if [ $? -eq 0 ]; then
        echo -e "${MSG_DONE} All services extracted successfully."
    else
        echo -e "${MSG_ERR} Failed to extract DevAtServ's services."
        exit 1
    fi

    # Prepare DevAtServ's GUI for debian tools
    echo -e "${MSG_INFO} Extracting DevAtServ's GUI'..."
    mkdir -p ./build/Linux/opt/devatserv/share/GUI
    mv *.deb ./build/Linux/opt/devatserv/share/GUI
    if [ $? -eq 0 ]; then
        echo -e "${MSG_DONE} Get DevAtServ's GUI completed successfully."
    else
        echo -e "${MSG_ERR} Failed to get DevAtServ's GUI."
        exit 1
    fi


    # Grant permission all asset
    chmod 777 ./build/Linux/opt/devatserv/share/storage/*
    chmod 777 ./build/Linux/opt/devatserv/share/GUI/*

}

function build_debian() {
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
	echo -e "${COL_GREEN}#          Executing dpkg to create installer...                                   #${COL_RESET}"
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"


    echo "Directory $DAS_PACK_DEST_DIR does not exist. Creating..."
    mkdir -p "$DAS_PACK_DEST_DIR"

    # Copy source & util
    cp -r "$DAS_PACK_SRC_DIR"/* "$DAS_PACK_DEST_DIR"
    cp -r util "$DAS_PACK_DEST_DIR"/opt/devatserv/share/

    chmod 755 "$DAS_PACK_DEST_DIR"/DEBIAN/*
    chmod 755 "$DAS_PACK_DEST_DIR"/opt/devatserv/share/storage/*
    
    dpkg-deb --root-owner-group --build ${DAS_PACK_DEST_DIR} ./output_Linux/${DAS_DEBIAN_NAME}
	logresult "$?" "built deb package" "build deb package"

	dpkg -I ./output_Linux/${DAS_DEBIAN_NAME}
	goodmsg "done."
}


function pre_build_windows() {
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}#          Compiling DevAtServ setup on Windows...                                 #${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
    # URL của Docker Desktop installer cho Windows
    DOCKER_DESKTOP_URL="https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    INSTALLER_NAME="DockerDesktopInstaller.exe"

    # Display info for compiling
    echo -e "${MSG_INFO} DevAtServ tool info..."
    echo "DAS Version: $DAS_VERSION"
    echo "Package Name: $DAS_PACK_NAME"
    echo "Source Directory: $DAS_PACK_SRC_DIR"
    echo "Destination Directory: $DAS_PACK_DEST_DIR"
    echo "Windows Package Name: $DAS_WINDOW_NAME"

   # Update a new version to control file
    update_version_debian $DAS_VERSION

    # Prepare Docker compose for deployment
    prepare_docker_compose_for_deployment
    
    # Prepare all images services for debian tools
    echo -e "${MSG_INFO} Extracting all DevAtServ services..."
    # Extract storage/*.tar.gz to share folder
    unzip $DAS_IMAGES_SERVICES -d ./build/Windows/devatserv/share/

    if [ $? -eq 0 ]; then
        echo -e "${MSG_DONE} All services extracted successfully."
    else
        echo -e "${MSG_ERR} Failed to extract DevAtServ's services."
        exit 1
    fi

    ######### Prepare DevAtServ's GUI for Inno Setup tools #########
    echo -e "${MSG_INFO} Extracting DevAtServ's GUI'..."
    mkdir -p ./build/Windows/devatserv/share/GUI
    mv *.exe ./build/Windows/devatserv/share/GUI/DevAtServGUISetup1.0.0.exe
    if [ $? -eq 0 ]; then
        echo -e "${MSG_DONE} Get DevAtServ's GUI completed successfully."
    else
        echo -e "${MSG_ERR} Failed to get DevAtServ's GUI."
        exit 1
    fi

    # Prepare Docker Desktop for user
    local DOCKER_DESKTOP_URL="https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    local INSTALLER_NAME="DockerDesktopInstaller.exe"
    local DOWNLOAD_DIR="./build/Windows/devatserv/share/docker"

    mkdir -p "$DOWNLOAD_DIR"

    # Download Docker Desktop installer
    echo -e "${MSG_INFO} Downloading Docker Desktop installer..."
    
    curl -L -o "$INSTALLER_NAME" "$DOCKER_DESKTOP_URL"
    # Check error
    if [ -f "$INSTALLER_NAME" ];then
        mv $INSTALLER_NAME $DOWNLOAD_DIR
        echo -e "${MSG_DONE} Docker Desktop installer downloaded successfully to $DOWNLOAD_DIR/$INSTALLER_NAME"
    else
        echo -e "${MSG_ERR} Failed to download Docker Desktop installer."
        exit 1
    fi

    # Grant permission all asset
    chmod 777 ./build/Windows/devatserv/share/storage/*
    chmod 777 ./build/Windows/devatserv/share/GUI/*
    chmod 777 ./build/Windows/devatserv/share/docker/*
}

function build_windows() {
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
	echo -e "${COL_GREEN}#          Executing InnoSetup to create installer...                              #${COL_RESET}"
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

    echo "Directory $DAS_PACK_DEST_DIR does not exist. Creating..."
    mkdir -p "$DAS_PACK_DEST_DIR"

    # Copy source & util
    cp -r "$DAS_PACK_SRC_DIR"/* "$DAS_PACK_DEST_DIR"
    cp -r util "$DAS_PACK_DEST_DIR"/devatserv/share/

	./tools/InnoSetup5.5.1/ISCC "${arguments}" ./${DAS_PACK_DEST_DIR}/devatserv/DevAtServSetup.iss
	logresult "$?" "built DevAtServ installer" "build DevAtServ installer"
}

main() {

    echo -e "${MSG_INFO} Type of build: $TypeOfBuild"
    if [ "$UNAME" == "Linux" ] ; then
        pre_build_debian
        build_debian
    elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
        pre_build_windows
        build_windows
    else
        errormsg "Operation system '$UNAME' is not supported."
    fi

}

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -f, --config-file   <config_file>   Input a specified config file"
    echo "  -h, --help                          Show this help message"
}

############################
# main execution
############################
# Parse command-line arguments
if [[ "$#" -eq 0 ]]; then
    # If no arguments
    main
else
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--config-file) # Input config file
                CONFIG_SERVICE_FILE="$2"
                if [[ -z "$CONFIG_SERVICE_FILE" ]]; then
                    echo "Error: Missing input config file"
                    show_help
                    exit 1
                fi
                main
                shift 2
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