#format.sh
COL_GREEN='\033[0;32m'
COL_ORANGE='\033[0;33m'
COL_YELLOW='\033[1;33m'
COL_BLUE='\033[0;34m'
COL_RED='\033[1;31m'
COL_RESET='\033[0m' # No Color

MSG_DONE="${COL_GREEN}[DONE]${COL_RESET}"
MSG_INFO="${COL_YELLOW}[INFO]${COL_RESET}"
MSG_ERR="${COL_RED}[ERR]${COL_RESET}"

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

