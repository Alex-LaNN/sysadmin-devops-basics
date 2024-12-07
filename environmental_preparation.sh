#!/usr/bin/bash

# Script for Handling .env File Configuration
#
# This script performs the following actions:
# 1. Validates that both `HOMEDIR` and `LOGFILE` arguments are provided.
# 2. Moves a `.env` file from the specified `HOMEDIR` to the project directory, renaming it to `.env.production`.
# 3. Sets secure ownership and permissions for the `.env.production` file.
#
# Requirements:
# - Must be run with superuser privileges for file operations (e.g., `sudo`).
# - The source file `.env` must exist in the specified `HOMEDIR`.
# - The `deploy_to_new_instance_with_caddy.sh` script must define the `log` and `error_exit` functions.
#
# Usage:
# ./<script_name> <HOMEDIR> <LOGFILE>
# Replace `<HOMEDIR>` with the path to the directory containing the `.env` file.
# Replace `<LOGFILE>` with the path to the log file for storing output and errors.
#
# Example:
# ./handle_env_file.sh /home/ubuntu /var/log/env_config.log
#
# Notes:
# - Ensures secure permissions for the `.env.production` file to protect sensitive data.
# - Logs all operations to the specified log file.

# Source the main script to access functions like log and error_exit
source ./deploy_to_new_instance_with_caddy.sh

# Checking the arguments passing
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Both HOMEDIR and LOGFILE must be provided."
    echo "Usage: $0 <HOMEDIR> <LOGFILE>" # Уточнение очерёдности передачи аргументов
    exit 1
fi

# Getting values ​​from passed arguments
HOMEDIR=$1
LOGFILE=$2

# Move and rename .env file to project directory
log "Moving .env file to the project directory and renaming..."
if [ -f "$HOMEDIR/.env" ]; then
    sudo mv $HOMEDIR/.env .env.production | tee -a "$LOGFILE" || error_exit "Failed to move .env.production file to project directory."
    FILE_MOVED=1
else
    log "WARNING: .env not found in "$HOMEDIR", skipping move. Check for .env.production file in project root."
    FILE_MOVED=0
fi

# Set permissions for .env.production
if [ "$FILE_MOVED" -eq 1 ]; then
    log "Setting permissions for .env.production..."
    sudo chown ubuntu:ubuntu .env.production | tee -a "$LOGFILE" || error_exit "Failed to set owner for .env.production."
    sudo chmod 600 .env.production | tee -a "$LOGFILE" || error_exit "Failed to set permissions for .env.production."
else
    log "Skipping permission settings for .env.production since the file was not moved."
fi