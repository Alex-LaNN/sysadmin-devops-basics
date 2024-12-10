#!/usr/bin/bash

# Script for adding a new user to the server with optional sudo access and setting up an SSH key
#
# This script does the following:
# 1. Asks the user to confirm adding a new user to the server.
# 2. Asks for the username and password of the new user, validates them.
# 3. Creates a new user, sets up SSH access, and adds it to the 'sudo' group if necessary.
# 4. Adds information about the new user to the config.sh configuration file in the 'USERS_LIST' array to keep the list of users on the server up to date.
#
# Requirements:
# - The script must be executed with superuser rights.
# - It is expected that there will be an authorized_keys file in HOME_DIR to set up SSH access.
# - The config.sh file must contain the 'USERS_LIST' array, where new users are added.
# - The log file must be specified to record all steps and errors during the script execution.
#
# Example of use:
# sudo ./create_new_user.sh
#
# Notes:
# - The script includes a check for an existing user and offers to change the name if the user already exists.
# - To add to the sudo group, the user will be asked to confirm this action.
# - The password must be at least 8 characters long.
# - In case of errors at any stage of user creation, partially created users are cleared (deleted).
#
# Expected files:
# - The authorized_keys file for configuring SSH access.
# - The config.sh file for storing the list of users.
#
# The script also handles errors and writes to the log file to track successful and unsuccessful operations.

# Source for accessing shared constants and functions
source ./config.sh
source ./functions.sh

  PWD=$(pwd)
  log "******************* 37 -create_new_user.sh-  $PWD"

# Request to add a new user
read -p "Do you want to add a new user to the server? Enter 'y' to confirm: " add_user

if [[ "$add_user" != "y" ]]; then
    log "User addition cancelled by user."
    exit 0
fi

# Function to update 'config.sh' with the new user's info
update_config_with_new_user() {
    local new_user="$1"
    local config_file="./config.sh"

    # Check if the user is already in the config (to avoid duplicates)
    if grep -q "$new_user" "$config_file"; then
        log "User '$new_user' is already listed in the config file."
        return 0
    fi

    # Append the new user to the config file
    echo "USERS_LIST+=(\"$new_user\")" >> "$config_file"
    log "Added '$new_user' to the USERS_LIST in $config_file."
}

# Checking the availability of required commands
check_required_commands() {
    for cmd in useradd chown chmod chpasswd; do
        if ! command -v "$cmd" &>/dev/null; then
            error_exit "Command '$cmd' is not available. Please install it."
        fi
    done
}

# Checking for user existence
check_user_exists() {
    if id "$1" &>/dev/null; then
        return 0  # The user exists
    else
        return 1  # User does not exist
    fi
}

# Cleaning in case of errors
cleanup_user() {
    if check_user_exists "$new_username"; then
        sudo userdel -r "$new_username" &>/dev/null
        log "User '$new_username' has been cleaned up after an error."
    fi
}

# Setting up a trap in case of error
trap cleanup_user ERR

# Checking if 'sudo' group exists
check_sudo_group() {
    if ! grep -q '^sudo:' /etc/group; then
        error_exit "Group 'sudo' does not exist on this system."
    fi
}

# Checking for the existence of the 'authorized_keys' file
check_authorized_keys_file() {
    if [[ ! -f "$HOMEDIR/.ssh/authorized_keys" ]]; then
        error_exit "File 'authorized_keys' not found in $HOMEDIR/.ssh."
    fi
}

# Checking required commands and resources
check_required_commands
check_sudo_group
check_authorized_keys_file

# Getting and checking the 'username'
while true; do
    read -p "Enter username for the new user: " new_username

    if [[ -z "$new_username" ]]; then
        error_exit "Username cannot be empty."
    fi

    if [[ ! "$new_username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error_exit "Invalid username. Only alphanumeric characters, hyphens, and underscores are allowed."
    fi

    if check_user_exists "$new_username"; then
        read -p "User '$new_username' already exists. Do you want to choose a different username? (y/n): " retry
        if [[ "$retry" != "y" ]]; then
            log "User addition cancelled."
            exit 0
        fi
    else
        break
    fi
done

# Getting a 'password'
while true; do
    read -sp "Enter password for the new user (characters won't be shown): " new_password
    echo

    if [[ ${#new_password} -lt 8 ]]; then
        log "Password must be at least 8 characters long. Please try again."
    else
        break
    fi
done

# Request to add to 'sudo' group
read -p "Add user to 'sudo' group? Enter 'y' to confirm: " add_to_sudo
add_to_sudo=$([[ "$add_to_sudo" == "y" ]] && echo "y" || echo "n")

# Check for user existence (second protection)
if check_user_exists "$new_username"; then
    error_exit "User '$new_username' already exists. Aborting."
fi

# Create a user with a home directory and a Bash shell
sudo useradd -m -s /bin/bash "$new_username" || error_exit "Failed to create user '$new_username'."

# Creating an SSH directory and copying keys
sudo mkdir -p /home/"$new_username"/.ssh || error_exit "Failed to create .ssh directory."
sudo install -m 600 "$HOMEDIR/.ssh/authorized_keys" "/home/$new_username/.ssh/authorized_keys" || error_exit "Failed to copy authorized_keys."

# Setting permissions on SSH directory
sudo chown -R "$new_username":"$new_username" /home/"$new_username"/.ssh || error_exit "Failed to set ownership on .ssh."
sudo chmod 700 /home/"$new_username"/.ssh || error_exit "Failed to set permissions on .ssh."

# Adding to the sudo group if required
if [[ "$add_to_sudo" == "y" ]]; then
    sudo usermod -aG sudo "$new_username" || error_exit "Failed to add user '$new_username' to the sudo group."
fi

# Setting a password
echo "$new_username:$new_password" | sudo chpasswd || error_exit "Failed to set password for user '$new_username'."

# Update the config file with the new user
update_config_with_new_user "$new_username"

log "New user '$new_username' created successfully."