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
DAS_PACK_SRC_DIR="./build/${PLATFORM}Native"
DAS_PACK_DEST_DIR="./output_${PLATFORM}Native/${DAS_NAME}"
DAS_DEBIAN_NAME="${DAS_PACK_NAME}-0_amd64.deb"
DAS_WINDOW_NAME="${DAS_PACK_NAME}-setup.exe"


function pre_build_windows() {
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}#          Compiling DevAtServ setup on Windows...                                 #${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
 
    # Display info for compiling
    echo -e "${MSG_INFO} DevAtServ tool info..."
    echo "DAS Version: $DAS_VERSION"
    echo "Package Name: $DAS_PACK_NAME"
    echo "Source Directory: $DAS_PACK_SRC_DIR"
    echo "Destination Directory: $DAS_PACK_DEST_DIR"
    echo "Windows Package Name: $DAS_WINDOW_NAME"


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
}

function build_windows() {
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
	echo -e "${COL_GREEN}#          Executing InnoSetup to create installer...                              #${COL_RESET}"
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

    echo "Directory $DAS_PACK_DEST_DIR does not exist. Creating..."
    mkdir -p "$DAS_PACK_DEST_DIR"

    # Copy source & util
    cp -r "$DAS_PACK_SRC_DIR"/* "$DAS_PACK_DEST_DIR"

    ./util/precompile.bat $ProjectConfigFile
	./tools/InnoSetup5.5.1/ISCC "${arguments}" ./${DAS_PACK_DEST_DIR}/devatserv/DevAtServSetup.iss
	logresult "$?" "built DevAtServ installer" "build DevAtServ installer"
    ./util/postcompile.bat
}

main() {

    pre_build_windows
    build_windows
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