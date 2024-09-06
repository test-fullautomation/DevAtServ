#format.sh
COL_GREEN='\033[0;32m'
COL_ORANGE='\033[0;33m'
COL_YELLOW='\033[1;33m'
COL_BLUE='\033[0;34m'
COL_RED='\033[1;31m'
COL_RESET='\033[0m' # No Color

MSG_DONE="${COL_GREEN}[DONE]${COL_RESET}"
MSG_INFO="${COL_YELLOW}[INFO]${COL_RESET}"
MSG_WARN="${COL_YELLOW}[WARN]${COL_RESET}"
MSG_ERR="${COL_RED}[ERR]${COL_RESET}"

TAG_REGEX="^(rel|dev)(\/das)?\/[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$"
VERSION_REGEX="^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$"

function errormsg(){
   echo -e "${COL_RED}>>>> ERROR: $1!${COL_RESET}"
   echo
   exit 1
}

function goodmsg(){
   echo -e "${COL_GREEN}>>>> $1.${COL_RESET}"
   echo
}

function greenmsg(){
   echo -e "${COL_GREEN}> $1.${COL_RESET}"   
}

function logresult(){
	if [ "$1" -eq 0 ]; then
	    goodmsg "Successfully $2"
	else
		errormsg "FATAL: Could not $3"
	fi
}

# Get version information from control file of linux package
# read 2. line, from there return after 10th character
# relative path from build script (caller)
function update_version_debian() {

   new_version=$1
   control_pathfile="./build/Linux/DEBIAN/control"
   if [ -f $control_pathfile ]; then
      VERSION=`sed '2q;d' $control_pathfile | cut -c 10-`
   fi

	if [[ "$new_version" =~ $VERSION_REGEX ]] && [ "$new_version" != "$VERSION" ]; then
		echo "Update version info in control file to '$new_version'"
		sed -i "s/\(Version: \)[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}/\1$new_version/" $control_pathfile
	fi
}