#!/usr/bin/bash

# Script for Automated Deployment with Caddy
#
# Script for automated application deployment using Docker Compose integration with Caddy.
# Adapted for use in automated deployment of the NestJS-backend application from the 
# repository "https://github.com/Alex-LaNN/NestJS-backend.git"
#
# This script automates project deployment, including package management,
# repository cloning, user management, Docker installation and environment setup.
# Its operation requires the use of the following additional scripts:
# clone_repository.sh create_new_user.sh docker_instalation.sh environmental_preparation.sh
#
# Requirements:
# - Must be run with superuser privileges (`sudo`).
# - Supporting scripts (`clone_repository.sh`, `create_new_user.sh`, `docker_instalation.sh`,
#   and `environmental_preparation.sh`) should be present in the same directory.
#
# Logs:
# - Outputs progress and errors to a log file named `start_deploy_with_caddy.log` 
# in the current directory.
#
# Usage:
# sudo ./start_deploy_with_caddy.sh
#
# Notes:
# - Automatically checks and installs required packages.
# - Supports secure `.env` file handling and Docker management.
#
# Author: Alex-LaNN

# Store the home working directory in the variable HOMEDIR
HOMEDIR=$(pwd)
# Define the path to the log file
LOGFILE="$HOMEDIR/start_deploy_with_caddy.log"
# Setting a link to the script for clone repository
SCRIPTOLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/clone_repository.sh"

# Clear the log file at the start of the script
> "$LOGFILE"

log() {
echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOGFILE"
}

error_exit() {
log "ERROR: $1"
# You can add a command to send a notification, for example:
# echo "Deployment failed: $1" | mail -s "Deployment Error" your-email@example.com
exit 1
}

log "=== Starting deployment process ==="

# Step 1: Initial instance preparation
log "=== Packages Management ==="
# List of packages to check
packages=("curl" "git" "wget" "software-properties-common" "ufw")

log "Updating package list..."
sudo apt update && sudo apt upgrade -y | tee -a "$LOGFILE" || error_exit "Unable to update system."

for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    log "Package '$pkg' not found. Installing..."
    sudo apt install -y "$pkg" | tee -a "$LOGFILE" || log "Error installing package '$pkg'. Continuing..."
    log "Ok."
  else
    log "Package '$pkg' is already installed."
  fi
done

# Cloning a repository
log "=== Repository Management ==="
sudo wget "$SCRIPTOLINK" -O clone_repository.sh || error_exit "Failed to download clone_repository.sh"
sudo chmod +x clone_repository.sh || error_exit "Failed to set execute permissions for clone_repository.sh"
sudo ./clone_repository.sh "$HOMEDIR" || error_exit "Failed to execute clone_repository.sh"

# Create another user if needed
log "=== User Management ==="
sudo ./create_new_user.sh "$HOMEDIR" "$LOGFILE" || error_exit "Failed to execute create_new_user.sh"

# Installing Docker with a check for necessity
log "=== Docker Management ==="
sudo ./docker_instalation.sh "$LOGFILE" || error_exit "Failed to execute docker_instalation.sh"

# Move and rename .env file to project directory
log "=== Environment Management ==="
sudo ./environmental_preparation.sh "$HOMEDIR" "$LOGFILE" || error_exit "Failed to execute environmental_preparation.sh"

log "Starting Docker Compose..."
sudo --preserve-env docker-compose --env-file .env.production -f docker-compose.prod.caddy.yml up -d --build | tee -a "$LOGFILE" || error_exit "Failed to start Docker Compose."

log "Checking running containers..."
sudo docker ps | tee -a "$LOGFILE" || error_exit "Failed to check running containers."

log "=== Deployment completed ==="
