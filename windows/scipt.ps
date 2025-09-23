# Variables
$CONTAINER_NAME = "claude_developer"
$IMAGE_NAME = "ubuntu:latest"
$MOUNT_PATH_ON_HOST = "$HOME/source"
$MOUNT_PATH_IN_CONTAINER = "/home/developer/host"
$USERNAME = "root"

# Check if the container exists
$CONTAINER_ID = docker ps -a -q -f name=$CONTAINER_NAME

# If the container does not exist, create and run it
if (-not $CONTAINER_ID) {
    Write-Host "Container does not exist. Creating and starting..." -ForegroundColor Yellow
    docker run -d `
      --name $CONTAINER_NAME `
      --user $USERNAME `
      -v "${MOUNT_PATH_ON_HOST}:${MOUNT_PATH_IN_CONTAINER}" `
      $IMAGE_NAME sleep infinity
}
else {
    # Check if the container is running
    $RUNNING_CONTAINER_ID = docker ps -q -f name=$CONTAINER_NAME
    if (-not $RUNNING_CONTAINER_ID) {
        Write-Host "Container exists but is stopped. Starting..." -ForegroundColor Yellow
        docker start $CONTAINER_NAME
    }
    else {
        Write-Host "Container is already running." -ForegroundColor Green
    }
}

# Connect to the container
Write-Host "Connecting to container..." -ForegroundColor Cyan
docker exec -it --user $USERNAME -w /home/developer $CONTAINER_NAME /bin/bash
