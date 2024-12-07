# 'functions.sh' - Shared Functions for Deployment Scripts
#
# This file contains utility functions that are shared across deployment scripts. 
# Functions include logging for progress tracking and error handling.
#
# Usage:
# - This file should be sourced using `source ./functions.sh` at the beginning of other scripts.
#
# Functions:
# - log: Logs messages with timestamps.
# - error_exit: Logs an error message and exits the script.
#
# Notes:
# - Requires the `$LOGFILE` variable to be defined in the main script.

# log: Function for logging messages to console and log file with a timestamp.
# Usage: log "Message to log"
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOGFILE"
}

# error_exit: Function for logging errors, sending optional notifications, and exiting.
# Usage: error_exit "Error message"
error_exit() {
  log "ERROR: $1"
  # Optional: Add commands to send notifications (e.g., email alerts) on error.
  # Example:
  # echo "Deployment failed: $1" | mail -s "Deployment Error" your-email@example.com
  exit 1
}