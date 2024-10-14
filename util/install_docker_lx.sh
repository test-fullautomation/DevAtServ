#!/bin/bash

pre_remove() {
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    sudo apt-get update
}

pre_install() {
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://packages.osd.bosch.com/docker \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
}

# Install docker 
install_docker() {
    pre_remove
    pre_install
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Install docker compose
install_docker_compose() {
    sudo apt-get install -y docker-compose-plugin
}

# Docker already installed or not
if ! command -v docker &> /dev/null; then
    install_docker

    if ! docker compose >/dev/null 2>&1; then
        install_docker_compose
    fi
fi

if ! docker compose >/dev/null 2>&1; then
    pre_install
    install_docker_compose
fi


echo "Docker installation script completed successfully."

exit 0
