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
source ./config.sh
source ./functions.sh

log "Checking Docker installation..."

# Checking if Docker is installed
if ! dpkg -l | grep -qw docker-ce; then
    log "Installing Docker..."

    # Removing old Docker versions (if any)
    sudo apt-get remove -y docker docker.io containerd runc || log "No old Docker versions to remove."

    # Installing the required dependencies
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Adding the Official Docker GPG Key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Adding a Docker Repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Installing Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Check and create 'docker' group
    if ! getent group docker >/dev/null; then
        sudo groupadd docker
        log "Docker group created."
    else
        log "Docker group already exists."
    fi

    # Adding users to the 'docker' group
    for user in "${USERS_LIST[@]}"; do
        sudo usermod -aG docker "$user" && log "Added $user to docker group."
        if [ "$USER" == "$user" ]; then
            log "Switching current session to docker group."
            newgrp docker
        fi
    done

    # Enabling and running Docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl enable docker

    log "Docker installed and started successfully."
else
    log "Docker is already installed, skipping."
fi

# Verifying Docker Compose Installation
log "Checking Docker Compose installation..."
if ! docker-compose --version &>/dev/null; then
    log "Installing Docker Compose..."
    sudo apt-get install -y docker-compose || error_exit "Failed to install Docker Compose."
    log "Docker Compose installed successfully."
else
    log "Docker Compose is already installed, skipping."
fi