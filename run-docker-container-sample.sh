#!/bin/bash

# Sample Docker Container Run Script
# Copy this to your host and modify as needed

# Variables
CONTAINER_NAME="claude_developer"
IMAGE_NAME="ubuntu:latest"
USER_IN_CONTAINER="developer"  # Change to match the user created by setup script
MOUNT_PATH_ON_HOST="${HOME}"  # Host home directory
MOUNT_PATH_IN_CONTAINER="/home/${USER_IN_CONTAINER}/host"  # Mounts to ~/host in container

# Ports to expose (space-separated list of port mappings)
# Format: "host_port:container_port" or just "port" for same on both sides
# Example: PORTS="8080:80 3000:3000 5432"
PORTS="8080 3000"  # Modify as needed

# Check if the container exists
CONTAINER_ID=$(docker ps -a -q -f name=$CONTAINER_NAME)

# If the container does not exist, create and run it
if [ -z "$CONTAINER_ID" ]; then
    echo "Container does not exist. Creating and starting..."

    # Build port mappings
    PORT_ARGS=""
    for port in $PORTS; do
        # If port doesn't contain ':', map it to itself (e.g., 8080 -> 8080:8080)
        if [[ "$port" != *":"* ]]; then
            port="$port:$port"
        fi
        PORT_ARGS="$PORT_ARGS -p $port"
    done

    docker run -d \
      --name $CONTAINER_NAME \
      -v $MOUNT_PATH_ON_HOST:$MOUNT_PATH_IN_CONTAINER \
      $PORT_ARGS \
      $IMAGE_NAME sleep infinity

    echo "Container created. Connecting as root to run setup..."
    echo "Run the setup script: bash $MOUNT_PATH_IN_CONTAINER/source/docker/setup-docker-container.sh"
    echo ""

    # Connect as root for first-time setup
    docker exec -it $CONTAINER_NAME /bin/bash
    exit 0
else
    # Check if the container is running
    RUNNING_CONTAINER_ID=$(docker ps -q -f name=$CONTAINER_NAME)
    if [ -z "$RUNNING_CONTAINER_ID" ]; then
        echo "Container exists but is stopped. Starting..."
        docker start $CONTAINER_NAME
    else
        echo "Container is already running."
    fi
fi

# Connect to the container as developer user
echo "Connecting to container as $USER_IN_CONTAINER..."
docker exec -it --user $USER_IN_CONTAINER -w /home/$USER_IN_CONTAINER $CONTAINER_NAME /bin/bash
