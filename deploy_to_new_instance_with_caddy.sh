#!/usr/bin/bash

# Before running the script, some conditions must be met for it to work:
# 1. This script and the .env file with the necessary variable values for the correct launch and operation of the application must be located in the root folder of the user with root rights.
# 2. 

# Define the list of users
users=("ubuntu" "alex")

# List of packages to check
packages=("curl" "git" "wget" "software-properties-common" "ufw")

# Store the current working directory in the variable CURRENTDIR
CURRENTDIR=$(pwd)

# Define the path to the log file, located in the current working directory
LOGFILE="$CURRENTDIR/start_deploy.log"

# Clear the log file at the start of the script
> "$LOGFILE"

log() {
echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOGFILE"
}

error_exit() {
log "ERROR: $1"
# You can add a command to send a notification, for example:
# echo "Deployment failed: $1" | mail -s "Deployment Error" your-email@example.com
exit 1
}

log "=== Starting deployment process ==="

log "Updating package list..."
sudo apt update && sudo apt upgrade -y | tee -a "$LOGFILE" || error_exit "Unable to update system."

log "Checking required utilities installation..."
# Checking required utilities installation
for pkg in "${packages[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    log "Package '$pkg' not found. Will be installed."
  else
    log "Package '$pkg' is already installed."
  fi
done

# Installing missing packages
if [[ "$(echo "${packages[@]}")" != "$(dpkg -l | grep -oP '^\w+' | grep -Fxq -f <(printf '%s\n' "${packages[@]}"))" ]]; then
  log "Installing the required utilities..."
  sudo apt install -y "${packages[@]}" | tee -a "$LOGFILE" || error_exit "Failed to install all required utilities."
fi

log "Checking Docker installation..."
if ! dpkg -l | grep -qw docker.io; then
    log "Installing Docker..."
    # Removing old Docker versions (if any)
    sudo apt-get remove docker docker-engine docker.io containerd runc

    # Setting up a Docker repository 
    sudo apt-get update sudo apt-get install ca-certificates curl gnupg lsb-release 

    # Adding the Official Docker GPG Key 
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 

    # Configuring a stable repository 
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \  
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Installing Docker Engine
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Adding the required users from the corresponding list to the 'docker' group
    for user in "${users[@]}"; do
      sudo usermod -aG docker $USER
    done

    sudo ufw default deny incoming 
    sudo ufw default allow outgoing 
    sudo ufw allow 22/tcp   # SSH 
    sudo ufw allow 80/tcp   # HTTP 
    sudo ufw allow 443/tcp  # HTTPS 
    sudo ufw enable

    # Docker Startup and Autostart
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl enable docker

    log "Docker installed and started successfully."
else
    log "Docker is already installed, skipping."
fi

log "Checking Docker Compose installation..."
if ! dpkg -l | grep -qw docker-compose; then
    log "Installing Docker Compose..."
    sudo apt install -y docker-compose | tee -a "$LOGFILE" || error_exit "Failed to install Docker Compose."
else
    log "Docker Compose is already installed, skipping."
fi

log "Cloning repository from GitHub..."
if [ ! -d "NestJS-backend" ]; then
    sudo mkdir NestJS-backend && cd NestJS-backend
    git clone https://github.com/Alex-LaNN/NestJS-backend.git | tee -a "$LOGFILE" || error_exit "Failed to clone repository."
else
    log "Repository 'NestJS-backend' already exists, skipping cloning."
    cd NestJS-backend || error_exit "Failed to change to project directory."
fi

# Move and rename .env file to project directory
log "Moving .env file to the project directory and renaming..."
if [ -f "/home/ubuntu/.env" ]; then
    sudo mv /home/ubuntu/.env .env.production | tee -a "$LOGFILE" || error_exit "Failed to move .env.production file to project directory."
else
    log "WARNING: .env not found in /home/ubuntu, skipping move. Check for .env.production file in project root."
fi

# Set permissions for .env.production
log "Setting permissions for .env.production..."
sudo chown ubuntu:ubuntu .env.production
sudo chmod 600 .env.production | tee -a "$LOGFILE" || error_exit "Failed to set permissions for .env.production."

log "Starting Docker Compose..."
sudo --preserve-env docker-compose --env-file .env.production -f docker-composeprod.caddy.yml up -d --build | tee -a "$LOGFILE" || error_exit "Failed to start Docker Compose."

log "Checking running containers..."
sudo docker ps | tee -a "$LOGFILE" || error_exit "Failed to check running containers."

log "=== Deployment completed ==="
