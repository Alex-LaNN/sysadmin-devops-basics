# 'config.sh' - Configuration Variables for Deployment Scripts
#
# This file defines shared configuration variables for deployment scripts, 
# including directory paths, log file location, repository details, and user lists.
#
# Usage:
# - This file should be sourced using `source ./config.sh` at the beginning of other scripts.
#
# Variables:
# - HOMEDIR: Stores the home working directory.
# - LOGFILE: Path to the log file for deployment progress and errors.
# - REPOSITORY: Name of the repository being deployed.
# - REPOLINK: URL link to the Git repository.
# - SCRIPTOLINK: URL link to the repository clone script.
# - USERS_LIST: List of users to manage during deployment.
#
# Notes:
# - The variables defined here are used throughout all deployment-related scripts.

# HOMEDIR: Store the current working directory as the home directory for the deployment.
HOMEDIR=$(pwd)

# LOGFILE: Define the path to the log file where progress and errors will be recorded.
LOGFILE="$HOMEDIR/start_deploy_with_caddy.log"

# REPOSITORY: Define the name of the repository to be cloned and deployed.
REPOSITORY="NestJS-backend"

# REPOLINK: Set the link to the Git repository for cloning.
REPOLINK="https://github.com/Alex-LaNN/NestJS-backend.git"

# SCRIPTOLINK: Set the URL link to the script for cloning the repository.
SCRIPTOLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/clone_repository.sh"

# USERS_LIST: Define the list of users to manage (used for creating and managing permissions).
USERS_LIST=("ubuntu")

