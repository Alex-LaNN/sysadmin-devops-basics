#!/usr/bin/bash

# Script to move and rename .env file to the project directory and set its permissions
#
# This script performs the following actions:
# 1. Checks if the .env file exists in the 'HOMEDIR' directory. If it does, the script moves and renames it to .env.production.
# 2. If the file is moved, the script sets the appropriate ownership and permissions for the .env.production file.
# 3. If the file is not found, a warning is logged, and the script skips the renaming and permission steps.
#
# Requirements:
# - The 'HOMEDIR' directory must contain the .env file, which will be moved and renamed to .env.production in the project directory.
# - The script must be executed with appropriate permissions to move and modify files in the project directory.
#
# Expected files:
# - .env file in the 'HOMEDIR' directory.
# - .env.production file will be created in the project directory.

# Source for accessing shared constants and functions
source "$PROJECTDIR"/config.sh
source "$PROJECTDIR"/functions.sh


# Move and rename .env file to the project directory
log "Moving .env file to the project directory and renaming..."
if [ -f "$HOMEDIR/.env" ]; then
    # Move and rename the .env file to .env.production
    sudo mv $HOMEDIR/.env .env.production | tee -a "$LOGFILE" || error_exit "Failed to move .env.production file to project directory."
    FILE_MOVED=1
else
    log "WARNING: .env not found in "$HOMEDIR", skipping move. Check for .env.production file in project root."
    FILE_MOVED=0
fi

# Set permissions for .env.production if the file was moved
if [ "$FILE_MOVED" -eq 1 ]; then
    log "Setting permissions for .env.production..."
    # Set ownership of the .env.production file to the 'ubuntu' user and group
    sudo chown ubuntu:ubuntu .env.production | tee -a "$LOGFILE" || error_exit "Failed to set owner for .env.production."
    # Set permissions so only the owner can read/write the file
    sudo chmod 600 .env.production | tee -a "$LOGFILE" || error_exit "Failed to set permissions for .env.production."
else
    log "Skipping permission settings for .env.production since the file was not moved."
fi