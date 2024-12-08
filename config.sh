# 'config.sh' - Configuration Variables for Deployment Scripts
#
# This file defines shared configuration variables for deployment scripts,
# including directory paths, log file location, repository details, user lists,
# and external script links needed for deployment processes.
#
# Usage:
# - This file should be sourced using `source ./config.sh` at the beginning of other scripts.
#
# Variables:
# - HOMEDIR: Stores the home working directory.
# - LOGFILE: Path to the log file for deployment progress and errors.
# - REPOSITORY: Name of the repository being deployed.
# - PROJECTDIR: Path to the project directory created after cloning the repository.
# - REPOLINK: URL link to the Git repository.
# - SCRIPTOLINK: URL link to the repository clone script.
# - PACKAGES: List of essential packages to check and install.
# - USERS_LIST: List of users to manage during deployment.
# - Links to additional scripts: URLs for scripts like user creation, Docker installation, and environment preparation.
# - NEEDEDFILES: Array of all required script links for the deployment process.
#
# Notes:
# - The variables defined here are used throughout all deployment-related scripts.
# - Ensure external scripts (NEEDEDFILES) are accessible during the deployment.

# HOMEDIR: Store the current working directory as the home directory for the deployment.
HOMEDIR=$(pwd)

# LOGFILE: Define the path to the log file where progress and errors will be recorded.
LOGFILE="$HOMEDIR/start_deploy_with_caddy.log"

# REPOSITORY: Define the name of the repository to be cloned and deployed.
REPOSITORY="NestJS-backend"

# Path to the project directory
PROJECTDIR="$HOMEDIR/$REPOSITORY"

# REPOLINK: Set the link to the Git repository for cloning.
REPOLINK="https://github.com/Alex-LaNN/NestJS-backend.git"

# SCRIPTOLINK: Set the URL link to the script for cloning the repository.
SCRIPTOLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/clone_repository.sh"

# PACKAGES: List of packages to check
PACKAGES=("curl" "git" "wget" "software-properties-common" "ufw")

# USERS_LIST: Define the list of users to manage (used for creating and managing permissions).
USERS_LIST=("ubuntu")

# Links to additional files
CLONELINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/clone_repository.sh"
CREATEUSERLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/create_new_user.sh"
DOCKERLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/docker_setup.sh"
ENVIRONMENTLINK="https://raw.githubusercontent.com/Alex-LaNN/sysadmin-devops-basics/master/environment_setup.sh"

# Array of all needed files
NEEDEDFILES=(
  "$CLONELINK"
  "$CREATEUSERLINK"
  "$DOCKERLINK"
  "$ENVIRONMENTLINK"
)