#!/usr/bin/bash

# Script for archiving all files older than 3 minutes in a user-specified directory.
# Archives are created with the .tar.gz extension, after which the original files are deleted.
# Archiving logs are written to a separate log file, which is stored in the $HOME/var/log/log_archive_reports directory.
# The script requests the path to the target directory when launched and checks for its existence.
# If the log directory does not exist, it is created automatically.

# Setting the log variable
LOG_HOME="/home/alex/var/log"

# Request path to target directory
read -p "Enter the path to the target directory to perform archiving: " TARGET_DIR

# Transforming a path using 'eval' to handle '~'
TARGET_DIR=$(eval echo "$TARGET_DIR")

# Checking if the specified directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory $TARGET_DIR not found."
  exit 1
fi

# Directory to store archiving logs
LOG_DIR="$LOG_HOME/log_archive_reports"

# If the log directory does not exist, create it
if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
fi

# File for recording reports
LOG_FILE="$LOG_DIR/archive_log.txt"

# Directory to store archives
ARCHIVE_DIR="/home/alex/archives"

# If the archive directory does not exist, create it
if [ ! -d "$ARCHIVE_DIR" ]; then
  mkdir -p "$ARCHIVE_DIR"
fi

# Archive files older than 3 minutes and delete original files
find "$TARGET_DIR" -type f -mmin +3 -exec bash -c '
  ARCHIVE_DIR="$1"
  LOG_FILE="$2"
  shift 2

   for file; do
    # Debug: Print the current file path
    echo "Processing file: $file"

    # Extract only the filename (without path) to avoid path issues in archive name
    base_name=$(basename "$file")

    # Determine the archive name and path
    archive_name="${base_name%.*}.tar.gz"
    echo "Archive name: $archive_name"
    archive_path="$ARCHIVE_DIR/$archive_name"
    
    # Create archive and delete the original file
    if tar -czf "$archive_path" "$file" 2>> "$LOG_FILE"; then
      rm "$file"
      echo "$(date +"%Y-%m-%dT%H:%M:%SZ") - The file $file was archived to $archive_path and deleted." >> "$LOG_FILE"
    else
      echo "$(date +"%Y-%m-%dT%H:%M:%SZ") - Error archiving file $file." >> "$LOG_FILE"
   fi
  done
' bash "$ARCHIVE_DIR" "$LOG_FILE" {} +