#!/usr/bin/bash

# Script for cloning a GitHub repository and preparing project scripts
#
# This script performs the following actions:
# 1. Verifies that a log file path is provided as an argument.
# 2. Clones a specified GitHub repository if it does not already exist locally.
# 3. Sets executable permissions for all `.sh` files located in the project root.
#
# Requirements:
# - Must be run with superuser privileges.
# - Expects an existing logging mechanism via `log` and `error_exit` functions,
#   which are sourced from another script (`deploy_to_new_instance_with_caddy.sh`).
#
# Usage:
# ./<script_name> <LOGFILE>
# Replace `<LOGFILE>` with the path to the log file where the output should be stored.
#
# Example:
# ./clone_and_prepare_repo.sh /var/log/repo_setup.log
#
# Notes:
# - The repository name and link are hardcoded as variables (`NestJS-backend` and its GitHub URL).
# - If the repository already exists, the cloning step is skipped.
# - Executable permissions are applied only to `.sh` files in the project root directory.
# - Ensure this script is executed with adequate permissions and that the sourced script is present.

# Source the main script to access functions like log and error_exit
source ./deploy_to_new_instance_with_caddy.sh

# Checking the argument passing
if [ -z "$1" ]; then
    echo "Error: File 'LOGFILE' not provided."
    exit 1
fi

# Getting LOGFILE value from argument
LOGFILE=$1
# Setting the repository name
REPOSITORY="NestJS-backend"
# Setting a link to the repository
REPOLINK="https://github.com/Alex-LaNN/NestJS-backend.git"

log "Cloning repository from GitHub..."
if [ ! -d "$REPOSITORY" ]; then
    sudo mkdir "$REPOSITORY" && cd "$REPOSITORY"
    git clone "$REPOLINK" | tee -a "$LOGFILE" || error_exit "Failed to clone repository."

    log "Making .sh files in the project root executable..."
    # Search for files with the .sh extension in the project root folder 
    for script in ./*.sh; do
        if [ -f "$script" ]; then # ensures that the object found is a file (and not a directory or other type of object)
            # Set executable permissions for script
            chmod +x "$script" || error_exit "Failed to make $script executable."
            log "Set executable permissions for $script"
        fi
    done
else
    log "Repository "$REPOSITORY" already exists, skipping cloning."
    cd "$REPOSITORY" || error_exit "Failed to change to project directory."
fi