#!/usr/bin/bash

# Script for changing file and folder permissions in two different directories.
# Files in the first directory get permissions 660.
# Folders in the second directory get permissions 770.
# The script performs these actions at an interval (in sec.) that is set by the user, 
# and continues to run until forced termination.

# Requesting directory path to change file permissions to 660
read -p "Enter the path to the directory to change files permissions to 660: " FILES_DIR
FILES_DIR=$(eval echo "$FILES_DIR")

# Checking if a directory for files exists
if [ ! -d "$FILES_DIR" ]; then
  echo "Error: Directory $FILES_DIR not found."
  exit 1
fi

# Requesting directory path to change folder permissions to 770
read -p "Enter the directory path to change folders permissions to 770: " FOLDERS_DIR
FOLDERS_DIR=$(eval echo "$FOLDERS_DIR")

# Checking for the existence of a directory for folders
if [ ! -d "$FOLDERS_DIR" ]; then
  echo "Error: Directory $FOLDERS_DIR not found."
  exit 1
fi

# Request task execution interval (in seconds)
read -p "Enter the task execution interval in seconds: " INTERVAL

# Checking that the entered interval value is a number
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
  echo "Error: Interval must be a numeric value."
  exit 1
fi

# Handling SIGINT signal to exit loop gracefully
trap "echo '  Completing work...'; exit" SIGINT

# Infinite loop with task execution every $INTERVAL seconds
while true; do
  echo "Changing file permissions in $FILES_DIR to 660..."
  find "$FILES_DIR" -type f -exec chmod 660 {} \; || echo "Error changing permissions for files in $FILES_DIR"

  echo "Changing folder permissions in $FOLDERS_DIR to 770..."
  find "$FOLDERS_DIR" -type d -exec chmod 770 {} \; || echo "Error changing permissions for folders in $FOLDERS_DIR"

  sleep "$INTERVAL"
done
