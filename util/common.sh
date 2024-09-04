#!/bin/bash

WORKSPACE="$(pwd)"
CONFIG_SERVICE_FILE="$WORKSPACE/config/repositories.conf"

# DevAtServ services Info
DAS_IMAGES_SERVICES=devatserv_images.zip

for i in "$@"
do
   case $i in
          --config-file=*)
			 CONFIG_SERVICE_FILE="${i#*=}"
          ;;
          *)
              echo -e $COL_RED"Argument not allowed:"$COL_RESET $i
              echo -e $COL_RED"build terminated."$COL_RESET
              exit 1
          ;;
      esac
done

SUPPORT_SERVER="None"


# return github url bases on provided authentication or not
get_url () {
	repo_type=$1
	repo_name=$3
	if [[ $2 == http://* || $2 == https://* ]]; then
		PROJECT_URL=`echo  "$2" | sed 's~http[s]*://~~g'`

		var_usr=$(echo ${repo_type^^}_BOT_USERNAME)
		var_pw=$(echo ${repo_type^^}_BOT_PASSWORD)

		bot_usr=${!var_usr}
		bot_pw=${!var_pw}

		repo_url="https://${PROJECT_URL}/${repo_name}.git"
		if [ -n "${bot_usr}" ] && [ -n "${bot_pw}" ]; then
			repo_url="https://${bot_usr}:${bot_pw}@${PROJECT_URL}/${repo_name}.git"
		fi
	else
		repo_url="$2/${repo_name}.git"
	fi

	echo $repo_url
}


get_server_url()
{
	conf_file=$1
	echo $(git config -f $conf_file --get supported-server.$2)
	return
}

# Parse repo information for cloning/updating
# Arguments:
#	$conf_file : repo configuration file
#	$repo_type : repo type
parse_repo () {
	conf_file=$1
	repo_type=$2

	greenmsg "Processing section $repo_type"
	list_repos=($(git config -f $conf_file --list --name-only | grep $repo_type.))
	for repo in "${list_repos[@]}"
	do
		repo_name=${repo#${repo_type}.}
		server_url=$(get_server_url "${conf_file}" "${repo_type}")
		if [[ "$server_url" != "" ]]; then
			repo_url=$(get_url ${repo_type} ${server_url} ${repo_name})
		else
			errormsg "not supported repo type '$repo_type'"
		fi
		echo -e "$COL_BLUE$BG_WHITE---- $repo$COL_RESET$COL_BLUE$BG_WHITE -----------------------------------------$COL_RESET"
		
		# switch repo to given released tag $TAG_NAME
		if [[ "$TRIGGER_BY" =~ $TAG_REGEX || "$TRIGGER_BY" == "tag" ]] && [[ "$TAG_NAME" =~ $TAG_REGEX ]]; then
			clone_update_repo "$SCRIPT_DIR/../$repo_name" "$repo_url" "$TAG_NAME"
		else
			# Allow to specify commit/branch of repos to be built 
			commit_branch=$(git config -f $conf_file --get $repo)
			clone_update_repo "$SCRIPT_DIR/../$repo_name" "$repo_url" "$commit_branch"
		fi

	done
	if [ "$?" -ne 0 ]; then
		exit 1
	fi
}

# Parse the configuration files to detect what server supported.
# Arguments:
#	$config_file : location to config file
parse_supported_server () {
    SUPPORT_SERVER=($(git config -f $1 --list --name-only | sed "s/.[^.]*$//" | uniq))
	echo "Server supported: $SUPPORT_SERVER"
}

# Parse the configuration files to detect all repositories in DevAtServ.
# Arguments:
#	$config_file : location to config file
parse_config () {
	#echo "git config -f $1 --list --name-only | sed "s/.[^.]*$//" | uniq"
	parse_supported_server $1
	conf_section=$SUPPORT_SERVER
    
	for section in "${conf_section[@]}"
	do 
		section_server=$(get_server_url "$1" "$section")
		if [ "$section_server" != "" ]; then
			parse_repo $1 $section
		elif [ "$section" != "supported-server" ]; then
			sec_name=$(git config -f "$1" --get ${section}.name)
			if [ "$sec_name" == "" ]; then
				sec_name=${section}
			fi
			
			echo
			greenmsg "processing section $sec_name"
			echo -e "$COL_BLUE$BG_WHITE---- $sec_name$COL_RESET$COL_BLUE$BG_WHITE -----------------------------------------$COL_RESET"
			
			sec_path=$(git config -f $1 --get ${section}.path)
			if [ "$sec_path" == "" ]; then
				sec_path="$WORKSPACE/../${sec_name}"
			fi
			sec_url=$(eval echo $(git config -f $1 --get ${section}.url))
			if [ "$sec_url" == "" ]; then
				sec_url=$(get_url "github" ${sec_name})
			fi
			clone_update_repo "$sec_path" "$sec_url"
			echo
			echo
		fi
	done
}

# Parse the configuration files to detect all services in DevAtServ.
# Arguments:
#	$config_file : location to config file
parse_services () {
	conf_file=$1
	service_type=services
	list_services=($(git config -f $conf_file --list --name-only | grep $service_type.))
}
# Clone or update repository
# Arguments:
#	$repo_path : location to clone repo into
#	$repo_url  : repo url
#	$commit_branch_tag  : target commit, branch or tag to point to
clone_update_repo () {
	repo_path=$1
	repo_url=$2
	commit_branch_tag=$3

	# 1. Check is repo folder is existing or not
	# 2. Ensure the repo url is correct
	# 3. Fetch all from git server
	# 4. Discard all user changes includes untracked files
	# 5. Ensure the default branch change (from git server)
	# 6. Checkout to target branch/commit/tag
	# 7. Ensure branch/commit/tag is up-to-date with remote

	if [ -d "$repo_path" ]; then
		echo "Cleaning and updating repo $repo_path"

		current_url=$(git -C "$repo_path" remote get-url origin)
		if [ "$current_url" != "$repo_url" ]; then
			echo "Repo URL has changed, update remote origin to ${repo_url}"
			git -C "$repo_path" remote set-url origin "$repo_url"
		fi

		git -C "$repo_path" fetch --all
		echo "Clean all local changes/commits"
		git -C "$repo_path" reset --hard HEAD
		git -C "$repo_path" clean -f -d -x

		if [ -z "$commit_branch_tag" ]; then
			default_branch=$(git -C "$repo_path" remote show origin | grep "HEAD branch" | cut -d " " -f 5)
			echo "Default branch: $default_branch"
			git -C "$repo_path" checkout $default_branch
			git -C "$repo_path" reset --hard origin/$default_branch
			logresult "$?" "switched to '$default_branch'" "checkout to '$default_branch' from '$repo_url'"
		fi

		# try to remove existing directory and clone repo again
		if [ "$?" -ne 0 ]; then
			echo "Cloning $repo_url again"
			rm -rf "$repo_path"
			git clone "$repo_url" "$repo_path"
		fi
	else
		echo "Cloning $repo_url"
		git clone "$repo_url" "$repo_path"
	fi
	if [ "$?" -ne 0 ]; then
		exit 1
	fi

	if [ -n "$commit_branch_tag" ]; then
		echo "Checking out to '$commit_branch_tag'"
		git -C "$repo_path" checkout $commit_branch_tag
		if [ "$?" -ne 0 ]; then
			errormsg	"Given tag/branch '$commit_branch_tag' is not existing" 
		fi
		git -C "$repo_path" pull origin $commit_branch_tag
		logresult "$?" "switched to '$commit_branch_tag'" "checkout to '$commit_branch_tag' from '$repo_url'"
	fi
}