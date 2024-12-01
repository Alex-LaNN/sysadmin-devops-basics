#!/usr/bin/bash

#exec 1>> /var/log/health-check.log 2>&1  # сначала проверить права на запись в файл  !!!!!!!!!

# Specifying Settings
APP_URL="https://akolomiets.stud.shpp.me/health"
IMAGE_NAME="app:latest"
CONTAINER_PATTERN="swapi_app"

# Function for checking the health endpoint status
check_health() {
    local status=$(curl -s -o /dev/null -w "%{http_code}" $APP_URL)
    if [ $status -eq 200 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - The application works fine."
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - The application is not available. Status: $status"
        return 1
    fi
}

# Function to get container ID
get_container_id() {
    # Getting container ID by image name
    local container_id=$(docker ps --filter "ancestor=$IMAGE_NAME" --format "{{.ID}}")
    # Getting container ID by pattern name:
    # local container_id=$(docker ps --filter "name=swapi_app" --format "{{.ID}}")
    
    if [ -z "$container_id" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Container with image $IMAGE_NAME not found"
        #echo "Container with name part $CONTAINER_PATTERN not found"
        return 1
    fi
    echo $container_id
}

# Function to restart a container
restart_container() {
    local container_id=$(get_container_id)
    if [ ! -z "$container_id" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Restarting container $container_id"
        docker stop $container_id
        docker start $container_id
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Container $container_id has been restarted"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to find container to restart"
        return 1
    fi
}

# Checking the application's functionality
if ! check_health; then
    restart_container
fi
