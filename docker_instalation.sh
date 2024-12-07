#!/usr/bin/bash

# Script for Installing and Configuring Docker and Docker Compose
#
# This script performs the following actions:
# 1. Checks if Docker is installed and installs it if missing, including:
#    - Removing any older versions of Docker.
#    - Adding the official Docker repository and GPG key.
#    - Installing Docker Engine and Docker Compose Plugin.
#    - Configuring Docker to start on system boot.
#    - Adding specified users to the `docker` group for non-root access.
# 2. Configures basic firewall rules (UFW) for SSH, HTTP, and HTTPS.
# 3. Checks if Docker Compose is installed and installs it if missing.
#
# Requirements:
# - Must be run with superuser privileges.
# - Expects `deploy_to_new_instance_with_caddy.sh` to provide the `log` and `error_exit` functions.
# - A valid log file must be passed as the first argument to the script.
#
# Usage:
# ./<script_name> <LOGFILE>
# Replace `<LOGFILE>` with the path to the log file where the output should be stored.
#
# Example:
# ./install_docker.sh /var/log/docker_install.log
#
# Notes:
# - Adds predefined users (default: "ubuntu") to the `docker` group.
# - Configures UFW firewall rules for basic server security.
# - Docker Compose installation is handled separately from Docker Engine.

# Source the main script to access functions like log and error_exit
source ./deploy_to_new_instance_with_caddy.sh

# Checking the argument passing
if [ -z "$1" ]; then
    echo "Error: File 'LOGFILE' not provided."
    exit 1
fi

# Getting LOGFILE value from argument
LOGFILE=$1

# Define the list of users
users=("ubuntu")

log "Checking Docker installation..."
if ! dpkg -l | grep -qw docker.io; then
    log "Installing Docker..."
    # Removing old Docker versions (if any)
    sudo apt-get remove docker docker-engine docker.io containerd runc

    # Setting up a Docker repository 
    sudo apt-get update sudo apt-get install ca-certificates curl gnupg lsb-release 

    # Adding the Official Docker GPG Key 
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 

    # Configuring a stable repository 
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \  
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Installing Docker Engine
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Adding the required users from the corresponding list to the 'docker' group
    for user in "${users[@]}"; do
      sudo usermod -aG docker $USER
    done

    sudo ufw default deny incoming 
    sudo ufw default allow outgoing 
    sudo ufw allow 22/tcp   # SSH 
    sudo ufw allow 80/tcp   # HTTP 
    sudo ufw allow 443/tcp  # HTTPS 
    sudo ufw enable

    # Docker Startup and Autostart
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl enable docker

    log "Docker installed and started successfully."
else
    log "Docker is already installed, skipping."
fi

log "Checking Docker Compose installation..."
if ! dpkg -l | grep -qw docker-compose; then
    log "Installing Docker Compose..."
    sudo apt install -y docker-compose | tee -a "$LOGFILE" || error_exit "Failed to install Docker Compose."
else
    log "Docker Compose is already installed, skipping."
fi