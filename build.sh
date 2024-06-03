#!/bin/bash

COL_GREEN='\033[0;32m'
COL_ORANGE='\033[0;33m'
COL_BLUE='\033[0;34m'
COL_RED='\033[1;31m'
COL_RESET='\033[0m' # No Color

MSG_INFO="${COL_GREEN}[INFO]${COL_RESET}"
MSG_DONE="${COL_ORANGE}[DONE]${COL_RESET}"
MSG_ERR="${COL_RED}[ERR]${COL_RESET} "

echo 
echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
echo -e "${COL_GREEN}#          Compiling DevAtServ setup...                                            #${COL_RESET}"
echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

DAS_VERSION="0.1.0.0"
DAS_PACK_NAME=DevAtServ_${DAS_VERSION}
DAS_PACK_SRC_DIR="./build/Linux"
DAS_PACK_DEST_DIR="./output_lx/${DAS_PACK_NAME}"
DAS_DEBIAN_NAME="${DAS_PACK_NAME}-0_amd64.deb"
UNAME=$(uname)

# Display info for compiling
echo "DAS Version: $DAS_VERSION"
echo "Package Name: $DAS_PACK_NAME"
echo "Source Directory: $DAS_PACK_SRC_DIR"
echo "Destination Directory: $DAS_PACK_DEST_DIR"
echo "Debian Package Name: $DAS_DEBIAN_NAME"

function errormsg(){
   echo -e "${COL_RED}>>>> ERROR: $1!${COL_RESET}"
   echo
   exit 1
}


function goodmsg(){
   echo -e "${COL_GREEN}>>>> $1.${COL_RESET}"
   echo
}

function logresult(){
	if [ "$1" -eq 0 ]; then
	    goodmsg "Successfully $2"
	else
		errormsg "FATAL: Could not $3"
	fi
}

function build_debian() {

    cd $CURDIR
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
	echo -e "${COL_GREEN}#          Executing dpkg to create installer...                                   #${COL_RESET}"
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

	if [ -d "$DAS_PACK_DEST_DIR" ]; then
        echo "Directory $DAS_PACK_DEST_DIR exists. Removing..."
        rm -rf "$DAS_PACK_DEST_DIR"
    else
        echo "Directory $DAS_PACK_DEST_DIR does not exist. Creating..."
        mkdir -p "$DAS_PACK_DEST_DIR"
    fi

    cp -r "$DAS_PACK_SRC_DIR"/* "$DAS_PACK_DEST_DIR"
    chmod 755 "$DAS_PACK_DEST_DIR"/DEBIAN/*
    
    dpkg-deb --root-owner-group --build ./output_lx/${PACK_NAME} ./output_lx/${DAS_DEBIAN_NAME}
	logresult "$?" "built deb package" "build deb package"

	dpkg -I ./output_lx/${DAS_DEBIAN_NAME}
	goodmsg "done."
}

main() {

    if [ "$UNAME" == "Linux" ] ; then
        build_debian
    elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
        build_windows
    else
        errormsg "Operation system '$UNAME' is not supported."
    fi

}

############################
# main execution
############################
main