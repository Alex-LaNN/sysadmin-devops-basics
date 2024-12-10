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
# - docker_setup.sh
# - environment_setup.sh
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

set -e  # Stop at first error
set -o pipefail  # Improved error handling in pipe

# Function to download all files necessary for the script to work
download_needed_files() {
  local CONFIGLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/config.sh"
  local FUNCTIONSLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/functions.sh"

  # Check and load 'config.sh'
  if [ ! -f "./config.sh" ]; then
    sudo wget -O config.sh "$CONFIGLINK"
  fi
  # Check and load 'functions.sh'
  if [ ! -f "./functions.sh" ]; then
    sudo wget -O functions.sh "$FUNCTIONSLINK"
  fi

  # Connecting files
  source ./functions.sh || error_exit "Failed to connect 'functions.sh'"
  source ./config.sh || error_exit "Failed to connect 'config.sh'"
  log "Configuration and functions files connected successfully."

  # Assuming 'REQUIRED_SCRIPTS' is an array defined in config.sh
  if [ ${#REQUIRED_SCRIPTS[@]} -eq 0 ]; then
    error_exit "There are no files in the 'REQUIRED_SCRIPTS' array required for the script to work. Check 'config.sh'."
  fi

   # Create the repository directory if it doesn't exist
  if [ ! -d "$REPOSITORY" ]; then
      sudo mkdir -p "$REPOSITORY" || error_exit "Failed to create directory $REPOSITORY."
  fi

  # Copy 'config.sh' and 'functions.sh' to the repository directory
  sudo cp ./config.sh "$REPOSITORY/" || error_exit "Failed to copy 'config.sh' to directory $REPOSITORY."
  sudo cp ./functions.sh "$REPOSITORY/" || error_exit "Failed to copy 'functions.sh' to directory $REPOSITORY." 

  cd "$REPOSITORY" || error_exit "Failed to change directory $REPOSITORY."

  # Download all needed scripts
  for SCRIPT_URL in "${REQUIRED_SCRIPTS[@]}"; do
    # Extract script name from URL
    SCRIPT_NAME=$(basename "$SCRIPT_URL")

    # Check if script already exists
    if [ -f "./$SCRIPT_NAME" ]; then
      log "Script '$SCRIPT_NAME' already exists. Skipping download."
      continue
    fi

    # Download the script
    log "Downloading script '$SCRIPT_NAME' from '$SCRIPT_URL'..."
    sudo wget -O "$SCRIPT_NAME" "$SCRIPT_URL" || error_exit "Failed to download '$SCRIPT_NAME'"
    log "Script '$SCRIPT_NAME' downloaded successfully."
  done

  log "All necessary scripts downloaded successfully."
}

# Step 1: Initial instance preparation
manage_packages() {
  log "=== Packages Management ==="
  log "Updating package list..."
  # Update system package list and upgrade installed packages
  sudo apt update && sudo apt upgrade -y || error_exit "Unable to update system."
  # Check and install missing packages
  for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -l | grep -qw "$pkg"; then
      log "Package '$pkg' not found. Installing..."
      sudo apt install -y "$pkg" || log "Error installing package '$pkg'. Continuing..."
    else
      log "Package '$pkg' is already installed."
    fi
  done
}

# Step 2: Clone the repository
clone_repository() {
  log "=== Repository Management ==="
  # Load the cloning script
  sudo wget "$SCRIPTOLINK" && sudo chmod +x clone_repository.sh 
  # Perform cloning
  sudo ./clone_repository.sh || error_exit "Failed to clone repository"
}

# Step 3: User Management
manage_users() {
  log "=== User Management ==="
  # Checking for the presence of a user creation script
  if [ -f "./create_new_user.sh" ]; then
    sudo ./create_new_user.sh || error_exit "Failed to execute create_new_user.sh"
  else
    log "User creation script not found."
  fi
}

# Step 4: Docker Management
setup_docker() {
  log "=== Docker Management ==="
  if [ -f "./docker_instalation.sh" ]; then
    sudo ./docker_instalation.sh || error_exit "Failed to execute docker_instalation.sh"
  else
    log "Docker installation script not found."
  fi
}

# Step 5: Environment Management
prepare_environment() {
  log "=== Environment Management ==="
  if [ -f "./environmental_preparation.sh" ]; then
    sudo ./environmental_preparation.sh || error_exit "Failed to execute environmental_preparation.sh"
  else
    log "Environment preparation script not found."
  fi
}

# Step 6: Start Docker Compose
start_docker_compose() {
  log "Starting Docker Compose..."
  sudo --preserve-env docker-compose --env-file .env.production -f docker-compose.prod.caddy.yml up -d --build || error_exit "Failed to start Docker Compose."
}

# Step 7: Check running containers
check_containers() {
  log "Checking running containers..."
  sudo docker ps || error_exit "Failed to check running containers."
}

# Main deployment function
main() {
  # Sequential launch of stages
  download_needed_files

  # Clearing the log file
  > "$LOGFILE"
  
  log "=== Starting deployment process ==="

  manage_packages
  clone_repository
  manage_users
  setup_docker
  prepare_environment
  start_docker_compose
  check_containers
  
  log "=== Deployment completed ==="
}

# Running the main function
main
