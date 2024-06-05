#!/bin/bash
set -e

# Kiểm tra xem Docker đã được cài đặt hay chưa
check_docker_installed() {
    if command -v docker &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Hàm cài đặt Docker mới
install_docker() {
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://packages.osd.bosch.com/docker \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo apt-get install -y docker-compose-plugin
}

# Kiểm tra xem Docker đã được cài đặt hay chưa
if check_docker_installed; then
    echo "Docker is already installed."
    read -p "Do you want to install the latest version of Docker? (y/n): " choice
    if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
        echo "Removing old Docker and installing the latest version..."
        install_docker
    else
        echo "Installing the latest Docker CE alongside the old Docker..."
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo apt-get install -y docker-compose-plugin
    fi
else
    echo "Docker is not installed. Installing Docker..."
    install_docker
fi

echo "Docker installation script completed successfully."

exit 0
