#!/usr/bin/bash

# Script for Adding a New User to the Server with Optional Sudo Access and SSH Key Setup
#
# This script performs the following actions:
# 1. Prompts the user to confirm whether a new user should be added to the server.
# 2. Validates provided arguments (HOMEDIR and LOGFILE) and ensures all required commands are available.
# 3. Requests and validates the new user's username and password.
# 4. Creates a new user, sets up SSH access, and optionally adds them to the 'sudo' group.
#
# Requirements:
# - Must be run with superuser privileges.
# - Expects `deploy_to_new_instance_with_caddy.sh` to provide the `log` and `error_exit` functions.
# - The authorized_keys file must exist in the provided home directory path.
#
# Usage:
# ./<script_name> <HOMEDIR> <LOGFILE>
# Replace `<HOMEDIR>` with the home directory containing the authorized_keys file.
# Replace `<LOGFILE>` with the path to the log file where the output should be stored.
#
# Example:
# ./add_user.sh /home/existing_user /var/log/user_setup.log
#
# Notes:
# - The script includes extensive validation to prevent incorrect inputs.
# - A cleanup function removes partially created users in case of errors.
# - Passwords must be at least 8 characters long.

# Source the main script to access functions like log and error_exit
source ./deploy_to_new_instance_with_caddy.sh

# Request to add a new user
read -p "Do you want to add a new user to the server? Enter 'y' to confirm: " add_user

if [[ "$add_user" != "y" ]]; then
    log "User addition cancelled by user."
    exit 0
fi

# Checking the arguments passing
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Both HOMEDIR and LOGFILE must be provided."
    echo "Usage: $0 <HOMEDIR> <LOGFILE>" # clarifying the order of argument passing
    exit 1
fi

# Getting values ​​from passed arguments
HOMEDIR=$1
LOGFILE=$2

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

log "New user '$new_username' created successfully."