#!/usr/bin/bash

# Before running the script, some conditions must be met for it to work:
# 1. This script and the .env file with the necessary variable values for the correct launch and operation of the application must be located in the root folder of the user with root rights.
# 2. If necessary, make changes to the configuration of the corresponding Nginx files to ensure the correct operation of the application in the browser.

# Get the absolute path to the current directory
CURRENTDIR=$(pwd)

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

log "Checking Git installation..."
if ! dpkg -l | grep -qw git; then
    log "Installing Git..."
    sudo apt install -y git | tee -a "$LOGFILE" || error_exit "Failed to install Git."
else
    log "Git is already installed, skipping."
fi

log "Checking Docker installation..."
if ! dpkg -l | grep -qw docker.io; then
    log "Installing Docker..."
    sudo apt install -y docker.io | tee -a "$LOGFILE" || error_exit "Failed to install Docker."
    log "Starting Docker..."
    sudo systemctl start docker | tee -a "$LOGFILE" || error_exit "Failed to start Docker."
    sudo systemctl enable docker | tee -a "$LOGFILE" || error_exit "Failed to enable Docker on system startup."
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
sudo --preserve-env docker-compose --env-file .env.production -f docker-compose.yml up -d --build | tee -a "$LOGFILE" || error_exit "Failed to start Docker Compose."

log "Checking running containers..."
sudo docker ps | tee -a "$LOGFILE" || error_exit "Failed to check running containers."

log "=== Deployment completed ==="
