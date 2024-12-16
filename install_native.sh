#!/bin/bash

set -e

source ./util/format.sh
source ./util/common.sh


#setlocal enabledelayedexpansion
mypath=$(realpath $(dirname $0))
sourceDir=$mypath/../download
destDir=$(realpath $mypath/../..)

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

install_microservices () {

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


install_packaging_python_windows() {
    
    echo -e "${MSG_INFO} Installing python package..."

    # Python package resource
    download_python_url=https://github.com/indygreg/python-build-standalone/releases/download/20221220/cpython-3.9.16+20221220-x86_64-pc-windows-msvc-shared-install_only.tar.gz
    archived_python_file=$sourceDir/cpython-3.9.16+20221220-x86_64-pc-windows-msvc-shared-install_only.tar.gz

    # Download python package
	download_package "Python" "$download_python_url" "$archived_python_file"


	tar -xzf "$archived_python_file" -C "$sourceDir"
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
	$destDir/python39/python.exe -m pip install -r "$mypath/WindowsNative/devatserv/share/python_requirements.txt" $proxy_args
	# Workaround for pyfranca
	$destDir/python39/python.exe -m pip install pyfranca

	logresult "$?" "installed required packges for Python" "install required packges for Python"

    echo -e "${MSG_DONE} Installed python package successfully."
}

install_packaging_erlang() {
    
    echo -e "${MSG_INFO} Erlang packaging ..."
    # Erlang package resource
    erlang_download_url=https://github.com/erlang/otp/releases/download/OTP-27.2/otp_win64_27.2.exe
	erlang_exe=otp_win64_27.2.exe
	erlang_package_name="Erlang OTP"
	erlang_installer_srcpath=${sourceDir}/${erlang_exe}
	erlang_installer_despath=${destDir}/${erlang_package_name}

    # Download erlang package
    download_package "Erlang package" "$erlang_download_url" "$erlang_installer_srcpath"

	# Clean up Erlang workspace
	if [ -f "$erlang_installer_despath" ]; then 
		rm -rf $erlang_installer_despath
	fi

	# Extract erlang package for building
	echo -e "${MSG_INFO} Installing Erlang by batch script..."
	./util/install-app.bat $erlang_installer_srcpath $erlang_installer_despath
    echo -e "${MSG_DONE} Installed Erlang successfully"
}

install_packaging_rabbitmq_server() {
    
    echo -e "${MSG_INFO} Installing RabbitMQ package..."
    # RabbitMQ Server resource
    rabitmq_download_url=https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.0.4/rabbitmq-server-4.0.4.exe
	rabitmq_exe=rabbitmq-server-4.0.4.exe
	rabitmq_package_name="${rabbitmq_exe%.exe}"
	rabitmq_installer_srcpath=${sourceDir}/${rabitmq_exe}
	rabitmq_installer_despath=${destDir}/${rabitmq_package_name}

    rm -rf "$destDir/rabbitmq"

    # Download Rabbitmq package
	download_package "RabbitMQ package" "$rabitmq_download_url" "$rabitmq_installer_srcpath"
   
	# Clean up Rabbitmq workspace
	if [ -f "$rabitmq_installer_despath" ]; then 
		rm -rf $rabitmq_installer_despath
	fi

	# Extract Rabbitmq package for building
	echo -e "${MSG_INFO} Installing RabbitMQ Server by batch script..."
	./util/install-app.bat $rabitmq_installer_srcpath $rabitmq_installer_despath
    echo -e "${MSG_DONE} Installed RabbitMQ Server successfully."
}

main() {
    echo -e "${MSG_INFO} Starting DevArtServ inslallation..."
    
    local config_file=$1
    get_config_file $config_file || {
        echo 'error getting config file'
        return 1
    }

    install_microservices || {
        echo 'error installing service' 
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
else
	rm -R -- "$sourceDir"/*
fi

main

