#!/usr/bin/bash

# Script for Automated Deployment with Caddy
#
# This script automates the deployment of the NestJS-backend application using Docker Compose 
# integrated with Caddy, specifically designed for use with the project repository
# "https://github.com/Alex-LaNN/NestJS-backend.git".
#
# The script automates the following tasks:
# 1. Package management: Ensures required system packages are installed.
# 2. Repository management: Clones the repository.
# 3. User management: Creates a new user as necessary.
# 4. Docker installation and environment setup: Checks for Docker installation and configures Docker Compose.
# 5. Runs the deployment process using Docker Compose with the specified Caddy configuration.
#
# Required supporting scripts:
# - clone_repository.sh
# - create_new_user.sh
# - docker_instalation.sh
# - environmental_preparation.sh
#
# Requirements:
# - Run with superuser privileges (`sudo`).
# - Supporting scripts must be in the same directory.
#
# Logs:
# - Progress and errors are logged to `start_deploy_with_caddy.log`.
#
# Usage:
# sudo ./start_deploy_with_caddy.sh
#
# Notes:
# - Automatically installs missing required packages.
# - Ensures secure handling of `.env` files.
# - Manages Docker and Docker Compose containers.
#
# Author: Alex-LaNN

# Source for accessing shared constants and functions
source ./config.sh
source ./functions.sh

# Clear the log file at the start of the script
> "$LOGFILE"
log "=== Starting deployment process ==="

# Step 1: Initial instance preparation
log "=== Packages Management ==="
# List of packages to check
packages=("curl" "git" "wget" "software-properties-common" "ufw")

log "Updating package list..."
# Update system package list and upgrade installed packages
sudo apt update && sudo apt upgrade -y | tee -a "$LOGFILE" || error_exit "Unable to update system."

# Check and install missing packages
for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    log "Package '$pkg' not found. Installing..."
    # Install package if not found
    sudo apt install -y "$pkg" | tee -a "$LOGFILE" || log "Error installing package '$pkg'. Continuing..."
    log "Ok."
  else
    log "Package '$pkg' is already installed."
  fi
done

# Step 2: Cloning the repository
log "=== Repository Management ==="
# Download and execute the 'clone_repository.sh' script to clone the repository
sudo wget "$SCRIPTOLINK" && sudo chmod +x clone_repository.sh && sudo ./clone_repository.sh "$HOMEDIR" || error_exit "Failed to execute clone_repository.sh"

# Step 3: User Management
log "=== User Management ==="
# Execute the 'create_new_user.sh' script to create a new user if needed
sudo ./create_new_user.sh "$HOMEDIR" "$LOGFILE" || error_exit "Failed to execute create_new_user.sh"

# Step 4: Docker Management
log "=== Docker Management ==="
# Execute the 'docker_instalation.sh' script to install Docker if necessary
sudo ./docker_instalation.sh "$LOGFILE" || error_exit "Failed to execute docker_instalation.sh"

# Step 5: Environment Management
log "=== Environment Management ==="
# Execute the 'environmental_preparation.sh' script to handle the .env file and permissions
sudo ./environmental_preparation.sh "$HOMEDIR" "$LOGFILE" || error_exit "Failed to execute environmental_preparation.sh"

# Step 6: Start Docker Compose
log "Starting Docker Compose..."
# Use Docker Compose to build and run the application using the specified .env.production file and Caddy configuration
sudo --preserve-env docker-compose --env-file .env.production -f docker-compose.prod.caddy.yml up -d --build | tee -a "$LOGFILE" || error_exit "Failed to start Docker Compose."

# Step 7: Check running containers
log "Checking running containers..."
# Check and log the list of running Docker containers
sudo docker ps | tee -a "$LOGFILE" || error_exit "Failed to check running containers."

log "=== Deployment completed ==="
