#!/bin/bash

source ./util/format.sh

echo 
echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
echo -e "${COL_GREEN}#          Compiling DevAtServ setup...                                            #${COL_RESET}"
echo -e "${COL_GREEN}#                                                                                  #${COL_RESET}"
echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

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
DAS_DEBIAN_NAME="${DAS_PACK_NAME}-0_amd64.deb"

# Display info for compiling
echo "DAS Version: $DAS_VERSION"
echo "Package Name: $DAS_PACK_NAME"
echo "Source Directory: $DAS_PACK_SRC_DIR"
echo "Destination Directory: $DAS_PACK_DEST_DIR"
echo "Debian Package Name: $DAS_DEBIAN_NAME"


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

function build_windows() {

	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"
	echo -e "${COL_GREEN}#          Executing InnoSetup to create installer...                              #${COL_RESET}"
	echo -e "${COL_GREEN}####################################################################################${COL_RESET}"

    echo "Directory $DAS_PACK_DEST_DIR does not exist. Creating..."
    mkdir -p "$DAS_PACK_DEST_DIR"

    # Copy source & util
    cp -r "$DAS_PACK_SRC_DIR"/* "$DAS_PACK_DEST_DIR"
    cp -r util "$DAS_PACK_DEST_DIR"/devatserv/share/

	# ./scripts/precompile.bat $ProjectConfigFile
	./tools/InnoSetup5.5.1/ISCC "${arguments}" ./${DAS_PACK_DEST_DIR}/devatserv/DevAtServSetup.iss
	logresult "$?" "built DevAtServ installer" "build DevAtServ installer"
	# ./scripts/postcompile.bat
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