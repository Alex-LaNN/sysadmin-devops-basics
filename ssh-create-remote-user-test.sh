#!/usr/bin/bash

# Script for creating a remote user on the server with SSH access settings and adding to the selected group (users or admin).
# The script takes 4 arguments:

# 1. The name of the current user with sudo rights (for example, root or user)
# 2. The IP address of the server
# 3. The name of the new user to create
# 4. The public SSH key for the new user
#
# The script checks the existence of the user and group, creates the .ssh directory, adds the public key and sets the necessary access rights.
# If the group does not exist, it will be created.
# If the public key already exists, re-adding will be skipped.

# Check for required arguments
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <current_user> <server_ip> <new_user> <public_key>"
  exit 1
fi

# Variables obtained from arguments
CURRENT_USER=$1      # current user running the script (e.g. user or root)
SERVER_IP=$2         # server IP address (e.g. 44.208.164.98)
NEW_USER=$3          # name of new user being added to server (e.g. user1)
PUBLIC_KEY=$4        # public SSH key for new user

# Path to private key
KEY_PATH="/home/alex/aws_server/ubuntu_server.pem"

# Password request
echo -n "Enter password for sudo: "
read -s PASSWORD
echo

# Request a group for a new user
while true; do
  echo -n "Enter 'u' to add to the users group or 'a' to add to the admin group: "
  read GROUP_CHOICE

  if [ "$GROUP_CHOICE" = "u" ]; then
    USER_GROUP="users"
    break
  elif [ "$GROUP_CHOICE" = "a" ]; then
    USER_GROUP="admin"
    break
  else
    echo "Invalid input. The default group 'users' will be selected."
    USER_GROUP="users"
  fi
done

# Checking access rights to a private key
if [ ! -f "$KEY_PATH" ]; then
  echo "Error: Private key file not found: $KEY_PATH"
  exit 1
fi

if [ "$(stat -c %a "$KEY_PATH")" != "400" ]; then
  echo "Error: Incorrect key file permissions. Set permissions to 400."
  exit 1
fi

# Connecting to the server and executing commands
ssh -i "$KEY_PATH" -t "$CURRENT_USER@$SERVER_IP" << EOF
echo "$PASSWORD" | sudo -S -v

# Checking user existence
if id "$NEW_USER" &>/dev/null; then
  echo "User $NEW_USER already exists. Please choose a different name."
  exit 1
else
  # Checking for group presence
  if ! getent group "$USER_GROUP" > /dev/null 2>&1; then
    # Create a group
    echo "$PASSWORD" | sudo -S groupadd "$USER_GROUP"
    echo "Group '$USER_GROUP' created..."
  else
    echo "Group '$USER_GROUP' already exists..."
  fi

  # Create a new user and add it to a group '$USER_GROUP'
  echo "$PASSWORD" | sudo -S adduser --disabled-password --gecos "" --ingroup "$USER_GROUP" "$NEW_USER"
  echo "User $NEW_USER created and added to group '$USER_GROUP'..."
fi

# Checking directory existence '.ssh'
if [ ! -d "/home/$NEW_USER/.ssh" ]; then
  # Create '.ssh' directory and set permissions
  echo "$PASSWORD" | sudo -S mkdir -p /home/$NEW_USER/.ssh
  echo "$PASSWORD" | sudo -S chmod 700 /home/$NEW_USER/.ssh
  echo "Directory /home/$NEW_USER/.ssh created..."
else
  echo "Directory /home/$NEW_USER/.ssh already exists..."
fi

# Checking for the presence of a public key
if ! grep -Fq "$PUBLIC_KEY" /home/$NEW_USER/.ssh/authorized_keys 2>/dev/null; then
  # Adding a public key
  echo "$PUBLIC_KEY" | sudo tee -a /home/$NEW_USER/.ssh/authorized_keys > /dev/null
  echo "$PASSWORD" | sudo -S chmod 600 /home/$NEW_USER/.ssh/authorized_keys
  echo "Public key added for user $NEW_USER..."
else
  echo "Public key for user $NEW_USER already exists..."
fi

# Setting correct permissions for the '.ssh' directory and the 'authorized_keys' file
echo "$PASSWORD" | sudo -S chown -R "$NEW_USER:$USER_GROUP" /home/$NEW_USER/.ssh

# Checking user creation
MAX_RETRIES=6       # Maximum number of attempts
RETRY_INTERVAL=90   # Interval between attempts

for ((i=1; i<=MAX_RETRIES; i++)); do
  if id "$NEW_USER" &>/dev/null; then
    echo "User $NEW_USER has been successfully created."
    break
  else
    echo "User $NEW_USER has not been created yet. Waiting..."
    sleep $RETRY_INTERVAL
  fi
done

# If after all attempts the user has not been created, an error is returned
if ! id "$NEW_USER" &>/dev/null; then
  echo "Error: Failed to create user $NEW_USER."
  exit 1
fi

EOF

echo "The process of creating a new user $NEW_USER is complete."