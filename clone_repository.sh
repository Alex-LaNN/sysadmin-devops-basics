#!/usr/bin/bash

# Script to clone a repository from GitHub and set executable permissions for project files
#
# This script performs the following actions:
# 1. Loads configuration variables and functions from external config.sh and functions.sh files.
# 2. Checks if the repository directory exists. If not, it creates the directory and clones the repository from the provided link.
# 3. After cloning the repository, the script sets all .sh files in the project root folder to be executable, except for config.sh and functions.sh.
# 4. If actions are successful, the script logs the information to a log file. In case of errors, it exits and logs an error message.
#
# Requirements:
# - The REPOSITORY and REPOLINK variables should be defined in the config.sh file for proper script operation.
# - The script must be executed by a user with permission to create directories and write to the log file.
# - Git must be installed to clone the repository.
#
# Example usage:
# sudo ./clone_repositoty.sh
#
# Notes:
# - All .sh files in the root of the repository will be made executable, except for config.sh and functions.sh.
#
# Expected files:
# - config.sh with necessary variables (e.g., REPOSITORY and REPOLINK).
# - functions.sh with functions for logging and error handling.
#
# The script logs successful operations and error messages to a log file.

# Source for accessing shared constants and functions
source ./config.sh
source ./functions.sh

log "Cloning repository from GitHub..."

PWD=$(pwd)
log "******************* 35 -clone_repository.sh-  $PWD"

# Clone the repository into the current directory
git clone "$REPOLINK" | tee -a "$LOGFILE" || error_exit "Failed to clone repository."

# Checking the success of cloning
if [ ! -d "$REPOSITORY" && ! -d ".git" ]; then
    error_exit "Cloning failed: .git directory missing from repository."
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

log "Making .sh files in the project root executable..."
# Search for files with the .sh extension in the project root folder 
for script in ./*.sh; do
    script_name=$(basename "$script")
    if [ -f "$script" ] && [ "$script_name" != "config.sh" ] && [ "$script_name" != "functions.sh" ]; then 
        # Set executable permissions for each found script
        chmod +x "$script" || error_exit "Failed to make $script executable."
        log "Set executable permissions for $script"
    fi
done

log "All necessary scripts downloaded successfully."
