#!/bin/bash

source ./util/format.sh



UNAME=$(uname)
if [ "$UNAME" == "Linux" ] ; then
	PLATFORM="Linux"
elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
	PLATFORM="Windows"
else
	errormsg "Operation system '$UNAME' is not supported."
fi

DAS_VERSION="0.1.0.0"
DAS_PACK_NAME=DevAtServ_${DAS_VERSION}
DAS_PACK_SRC_DIR="./build/${PLATFORM}"
DAS_PACK_DEST_DIR="./output_${PLATFORM}/${DAS_PACK_NAME}"
DAS_IMAGES_SERVICES=devatserv-services.zip
DAS_DEBIAN_NAME="${DAS_PACK_NAME}-0_amd64.deb"
DAS_WINDOW_NAME="${DAS_PACK_NAME}-setup.exe"


function pre_build_debian() {
    echo 
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}#          Compiling DevAtServ setup on Unbuntu...                                 #${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

    # Display info for compiling
    echo "DAS Version: $DAS_VERSION"
    echo "Package Name: $DAS_PACK_NAME"
    echo "Source Directory: $DAS_PACK_SRC_DIR"
    echo "Destination Directory: $DAS_PACK_DEST_DIR"
    echo "Debian Package Name: $DAS_DEBIAN_NAME"
    
    # Prepare all images services for debian tools
    mkdir -p ./build/Linux/opt/devatserv/share/storage
    unzip $DAS_IMAGES_SERVICES -d ./build/Linux/opt/devatserv/share/storage

    # Prepare DevAtServ's GUI for debian tools
    mkdir -p ./build/Linux/opt/devatserv/share/GUI
    mv *.deb ./build/Linux/opt/devatserv/share/GUI

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
    echo 
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}#          Compiling DevAtServ setup on Windows...                                 #${COL_RESET}"
    echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
    echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

    # Display info for compiling
    echo "DAS Version: $DAS_VERSION"
    echo "Package Name: $DAS_PACK_NAME"
    echo "Source Directory: $DAS_PACK_SRC_DIR"
    echo "Destination Directory: $DAS_PACK_DEST_DIR"
    echo "Windows Package Name: $DAS_WINDOW_NAME"

    # Prepare all images services for debian tools
    mkdir -p ./build/Windows/devatserv/share/storage
    unzip $DAS_IMAGES_SERVICES -d ./build/Windows/devatserv/share/storage

    # Prepare DevAtServ's GUI for Inno Setup tools
    mkdir -p ./build/Windows/devatserv/applications/GUI
    mv *.exe ./build/Windows/devatserv/applications/GUI

    # Grant permission all asset
    chmod 777 ./build/Windows/devatserv/share/storage/*
    chmod 777 ./build/Windows/share/applications/GUI/*
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

############################
# main execution
############################
main