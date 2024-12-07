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

set -e  # Остановка при первой ошибке
set -o pipefail  # Улучшенная обработка ошибок в pipe

download_config_files() {
  local CONFIGLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/config.sh"
  local FUNCTIONSLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/functions.sh"

  # Проверка и загрузка config.sh
  if [ ! -f "./config.sh" ]; then
    log "Uploading file 'config.sh' ..."
    sudo wget -O config.sh "$CONFIGLINK" || error_exit "Failed to load 'config.sh'"
  fi

  # Проверка и загрузка functions.sh
  if [ ! -f "./functions.sh" ]; then
    log "Uploading file 'functions.sh' ..."
    sudo wget -O functions.sh "$FUNCTIONSLINK" || error_exit "Failed to load 'functions.sh'"
  fi

  # Подключение файлов
  source ./config.sh || error_exit "Failed to connect 'config.sh'"
  source ./functions.sh || error_exit "Failed to connect 'functions.sh'"

  log "Configuration files connected successfully."
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

  # Go to the project directory
  cd "$PROJECTDIR" || error_exit "Failed to change directory to $PROJECTDIR"
}

# Step 3: User Management
log "=== User Management ==="
# Execute the 'create_new_user.sh' script to create a new user if needed
sudo ./create_new_user.sh || error_exit "Failed to execute create_new_user.sh"

# Step 3: User Management
manage_users() {
  log "=== User Management ==="
  # Checking for the presence of a user creation script
  if [ -f "./create_new_user.sh" ]; then
    # Running the user creation script with a flag that prevents recursion
    # export SKIP_RECURSIVE_DEPLOY=1
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
  download_config_files

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
