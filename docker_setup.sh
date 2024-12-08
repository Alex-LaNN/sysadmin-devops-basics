#!/usr/bin/bash

# Script to install Docker and Docker Compose on an Ubuntu system and configure Docker for user access
#
# This script performs the following actions:
# 1. Checks if Docker is already installed. If not, it installs Docker and configures it.
# 2. Adds users from the USERS_LIST to the Docker group for Docker access.
# 3. Configures UFW (Uncomplicated Firewall) to allow necessary ports (SSH, HTTP, HTTPS).
# 4. Starts Docker, ensures it starts on boot, and enables the necessary Docker services.
# 5. Checks if Docker Compose is installed. If not, it installs Docker Compose.
#
# Requirements:
# - The USERS_LIST array should be defined in config.sh and contain a list of users who need Docker access.
# - The script must be executed by a user with sufficient privileges to install packages and modify system settings.
#
# Example usage:
# sudo ./install_docker.sh
#
# Notes:
# - The script installs Docker and Docker Compose only if they are not already installed.
# - After installation, Docker is configured to allow access for the users in the USERS_LIST.
# - UFW firewall settings are configured to allow SSH, HTTP, and HTTPS traffic.
#
# Expected files:
# - config.sh with the USERS_LIST variable for defining users who need Docker access.
# - functions.sh with functions for logging and error handling.

# Source for accessing shared constants and functions
source "$PROJECTDIR"/config.sh
source "$PROJECTDIR"/functions.sh

log "Checking Docker installation..."
if ! dpkg -l | grep -qw docker.io; then
    log "Installing Docker..."
    # Removing old Docker versions (if any)
    sudo apt-get remove docker docker-engine docker.io containerd runc

    # Setting up a Docker repository 
    sudo apt-get update sudo apt-get install ca-certificates curl gnupg lsb-release 

    # Adding the Official Docker GPG Key 
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 

    # Configuring a stable Docker repository 
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \  
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Installing Docker Engine
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Adding the required 'USERS_LIST' to the 'docker' group for user access
    for user in "${USERS_LIST[@]}"; do
      sudo usermod -aG docker $user
    done

    # Configuring UFW firewall settings
    sudo ufw default deny incoming 
    sudo ufw default allow outgoing 
    sudo ufw allow 22/tcp   # SSH 
    sudo ufw allow 80/tcp   # HTTP 
    sudo ufw allow 443/tcp  # HTTPS 
    sudo ufw enable

   # Docker Startup and Autostart configuration
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl enable docker

    log "Docker installed and started successfully."
else
    log "Docker is already installed, skipping."
fi

# Checking if Docker Compose is already installed
log "Checking Docker Compose installation..."
if ! dpkg -l | grep -qw docker-compose; then
    log "Installing Docker Compose..."
    sudo apt install -y docker-compose | tee -a "$LOGFILE" || error_exit "Failed to install Docker Compose."
else
    log "Docker Compose is already installed, skipping."
fi