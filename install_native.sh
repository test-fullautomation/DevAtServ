#!/bin/bash

set -e

source ./util/format.sh
source ./util/common.sh


#setlocal enabledelayedexpansion
mypath=$(realpath $(dirname $0))
sourceDir=$mypath/../download
destDir=$(realpath $mypath/build/WindowsNative/devatserv)
tempDir=$(realpath $mypath/../..)



function download_package(){
	proxy_args=""
	if [ "$use_cntlm" == "Yes" ]; then
		proxy_args="--proxy-ntlm -x 127.0.0.1:3128"
	fi
	package_name=$1
	package_url=$2
	package_out=$3

	retry_counter=0
	max_retries=5
	success=false

	echo curl $proxy_args "$package_url" -o "$package_out"
	while [[ "$retry_counter" -lt "$max_retries" && "$success" == "false" ]];do
		curl $proxy_args -L -k "$package_url" -o "$package_out"

		if [ $? -eq 0 ]; then
			success=true
			goodmsg "Successfully downloaded $package_name"
		else
			((retry_counter++))
			echo "Failed to download $package_url (attempt: $retry_counter)"
			sleep 1
			if [ "$use_cntlm" == "Yes" ]; then
				restart_cntlm
			fi
		fi
	done

	if [ "$success" == "false" ]; then
		errormsg "FATAL: Could not download $package_url after $max_retries attempts"
	fi
}

get_config_file() {
    local input_config_file=$1
    local default_config_file="$WORKSPACE/config/repositories/repositories.conf"

    if [[ -n "$input_config_file" ]]; then
        CONFIG_SERVICE_FILE="$input_config_file"
    else
        CONFIG_SERVICE_FILE="$default_config_file"
    fi

    echo -e "${MSG_INFO} Using config file: $CONFIG_SERVICE_FILE"
}

clone_microservices () {

	echo -e "${MSG_INFO} Cloning all services to repos..."

	resolved_config_file=$(realpath "$CONFIG_SERVICE_FILE")

	if [ -f "$resolved_config_file" ]; then
		greenmsg "Found the configuration file to clone all services at: '$CONFIG_SERVICE_FILE'"
	else
		errormsg "Repo configuration '$CONFIG_SERVICE_FILE' is not existing"
	fi
	
	# Parse and clone all services
	parse_config $CONFIG_SERVICE_FILE

    echo -e "${MSG_DONE} All services are cloned successfully."
}

install_genpackage_pandoc() {

	echo -e "${MSG_INFO} Pandoc packaging ..."
    # Pandoc package resource
    pandoc_download_url=https://github.com/jgm/pandoc/releases/download/2.18/pandoc-2.18-windows-x86_64.zip
	pandoc_archived_file=pandoc-2.18-windows-x86_64.zip
	pandoc_package_name="pandoc"
	pandoc_installer_srcpath=${sourceDir}/${pandoc_package_name}
	pandoc_installer_despath=${tempDir}/${pandoc_package_name}

    # Download python package
	download_package "Python" "$pandoc_download_url" "$pandoc_archived_file"

	/usr/bin/yes A | unzip "$pandoc_archived_file" -d "$pandoc_installer_despath"
	logresult "$?" "unzipped Pandoc" "unzip Pandoc"

	# Add pandoc to PATH env
	export PATH=$PATH:$pandoc_installer_despath/pandoc-2.18
	
    echo -e "${MSG_DONE} Installed Pandoc successfully"
}

install_texlive () {
	CDIR=$(pwd)
	mkdir -p download
	cd download
	# Try this if the mirror.foobar.to can't be download
	if [ ! -f "install-tl-unx.tar.gz" ]; then
		curl -L https://mirror.foobar.to/CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz -o ./install-tl-unx.tar.gz
	fi

	zcat install-tl-unx.tar.gz | tar xf -
	cd install-tl-20*
	sudo perl ./install-tl --no-interaction
	cd $CDIR
}

check_and_install_texlive () {

	if [ ! -z "$GENDOC_LATEXPATH" ]; then
		return 0
	fi
	echo "install texlive"
	# get last word of pdflatex version text


	# If pdflatex exist
	ver=`pdflatex -v | head -n 1 | awk 'NF>1{print $NF}'`
	if [ ! -z "$ver" ]; then
		release_year=${ver:0:4}
		if [ $release_year -lt 2019 ]; then
			if [ -f "/usr/local/texlive/$(date +%Y)/bin/x86_64-linux/pdflatex" ]; then
				export GENDOC_LATEXPATH=/usr/local/texlive/$(date +%Y)/bin/x86_64-linux
				return 0
			fi
		else
			export PDFLATEXPATH=`which pdflatex`
			export GENDOC_LATEXPATH=`dirname $PDFLATEXPATH`
			return 0
		fi
	fi
	install_texlive
	export GENDOC_LATEXPATH="/usr/local/texlive/$(date +%Y)/bin/x86_64-linux"
}


install_packaging_python_windows() {
    
    echo -e "${MSG_INFO} Installing python package..."

    # Python package resource
    python_download_url=https://github.com/indygreg/python-build-standalone/releases/download/20221220/cpython-3.9.16+20221220-x86_64-pc-windows-msvc-shared-install_only.tar.gz
    python_archived_file=$sourceDir/cpython-3.9.16+20221220-x86_64-pc-windows-msvc-shared-install_only.tar.gz

    # Download python package
	download_package "Python" "$python_download_url" "$python_archived_file"

	tar -xzf "$python_archived_file" -C "$sourceDir"
	rm -rf "$destDir/python39"
	mv "$sourceDir/python" "$destDir/python39"

	# !! ATTENTION !!
	# embedded python has problems with to recognize a PIP installation.
	# below ._pth touches make PIP working
	# Note: Use ._pth can cause other poblems: https://stackoverflow.com/questions/47851452/add-package-path-to-python-pth-file-using-environment-variables
	#       There are no way to add script path to ._pth now
	CURDIR=$(pwd)
	PYDIR=$(cd $destDir/python39; pwd -W)
	cd $CURDIR

	proxy_args=""
	if [ "$use_cntlm" == "Yes" ]; then
		proxy_args="--proxy 127.0.0.1:3128"
	fi

	# call pip to initialize pip
	$destDir/python39/python.exe -m pip install --upgrade pip
	$destDir/python39/python.exe -m pip install --upgrade setuptools
	$destDir/python39/python.exe -m pip install wheel
	
	# !! ATTENTION !!
	# Here we need to avoid that libraries are installed to C:\Users\<userid>\AppData\Roaming\Python\Python39.
	# This would create a conflict with an already existing python version. RobotFramework's python should be
	# fully transparent for the existing system.
	# 
	$destDir/python39/python.exe -m pip install -r "$mypath/build/WindowsNative/devatserv/share/python_requirements.txt" $proxy_args
	# Workaround for pyfranca
	$destDir/python39/python.exe -m pip install pyfranca

	logresult "$?" "installed required packges for Python" "install required packges for Python"

	###################################################################################################################################
	echo -e "${MSG_INFO} Integrate all microservices to python package..."
	repo_type=$SUPPORT_SERVER
	list_repos=($(git config -f $CONFIG_SERVICE_FILE --list --name-only | grep $SUPPORT_SERVER.))

	for repo in "${list_repos[@]}"
	do
		reponame=${repo#${repo_type}.}
		echo -e "$COL_BLUE$BG_WHITE---- $repo$COL_RESET$COL_BLUE$BG_WHITE -----------------------------------------$COL_RESET"
		cd "../$reponame" 
		
			if [ -f "./setup.py" ]; then
			PACKNAME=""
			if grep -w setuptools ./setup.py | grep -w import; then
				PACKNAME=$($destDir/python39/python.exe ./setup.py --name | tail -n 1)
				if [[ -n "$PACKNAME" ]]; then
					/usr/bin/yes | $destDir/python39/python.exe -m pip uninstall ${PACKNAME}
					logresult "$?" "uninstalled ${PACKNAME}" "uninstall ${PACKNAME}"
				fi
			fi
			
			$destDir/python39/python.exe ./setup.py clean --all install
			logresult "$?" "installed ${reponame}" "install ${reponame}"
		fi
	done

	logresult "$?" "all microservices are intergrated into Python" "require to intergrate microservices for Python"

    echo -e "${MSG_DONE} Installed python package successfully."
}

install_packaging_erlang() {
    
    echo -e "${MSG_INFO} Erlang packaging ..."
    # Erlang package resource
    erlang_download_url=https://github.com/erlang/otp/releases/download/OTP-27.2/otp_win64_27.2.zip
	erlang_archived_file=otp_win64_27.2.zip
	erlang_package_name="ErlangOTP"
	erlang_installer_srcpath=${sourceDir}/${erlang_package_name}
	erlang_installer_despath=${destDir}/${erlang_package_name}

    # Download erlang package
    download_package "Erlang package" "$erlang_download_url" "$erlang_archived_file"

	unzip $erlang_archived_file -d $erlang_installer_srcpath
	rm -rf "$erlang_installer_despath"
	mv $erlang_installer_srcpath $erlang_installer_despath

	# Extract erlang package for building
	# echo -e "${MSG_INFO} Installing Erlang by batch script..."
	# ./util/install-app.bat $erlang_package_name $erlang_installer_srcpath $erlang_installer_despath
    echo -e "${MSG_DONE} Installed Erlang successfully"
}

install_packaging_rabbitmq_server() {
    
    echo -e "${MSG_INFO} Installing RabbitMQ package..."
    # RabbitMQ Server resource
    rabbitmq_download_url=https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.0.5/rabbitmq-server-windows-4.0.5.zip
	rabbitmq_archived_file=rabbitmq-server-windows-4.0.5.zip
	rabbitmq_package_name="RabbitMQ"
	rabbitmq_installer_srcpath=${sourceDir}/${rabbitmq_package_name}
	rabbitmq_installer_despath=${destDir}/${rabbitmq_package_name}

    # Download Rabbitmq package
	download_package "RabbitMQ package" "$rabbitmq_download_url" "$rabbitmq_archived_file"
   
   	unzip $rabbitmq_archived_file -d $rabbitmq_installer_srcpath
	rm -rf "$rabbitmq_installer_despath"
	mv $rabbitmq_installer_srcpath $rabbitmq_installer_despath

	# Extract Rabbitmq package for building
	# echo -e "${MSG_INFO} Installing RabbitMQ Server by batch script..."
	# ./util/install-app.bat $rabbitmq_package_name $rabbitmq_installer_srcpath $rabbitmq_installer_despath
    echo -e "${MSG_DONE} Installed RabbitMQ Server successfully."
}

main() {
    echo -e "${MSG_INFO} Starting DevArtServ inslallation..."
    
    local config_file=$1
    get_config_file $config_file || {
        echo 'error getting config file'
        return 1
    }

    clone_microservices || {
        echo 'error installing service' 
        return 1
    }

	install_genpackage_pandoc || {
		echo 'error installing pandoc package' 	
        return 1
	}

	check_and_install_texlive || {
		echo 'error installing texlive package' 
        return 1
	}

    install_packaging_python_windows || {
        echo 'error installing python package' 
        return 1
    }

    install_packaging_erlang || {
        echo 'error installing erlang' 
        return 1
    }

    install_packaging_rabbitmq_server || {
        echo 'error installing rabbitmq' 
        return 1
    }

    echo -e "${MSG_DONE} DevAtServ inslallation completely"
    return 0 
}

if [ ! -d "$sourceDir" ]; then
	mkdir "$sourceDir"
fi

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -f, --config-file   <config_file>   Input a specified config file"
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
                main $config_file
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