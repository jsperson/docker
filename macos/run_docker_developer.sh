#!/bin/bash

  # Variables
  CONTAINER_NAME="claude_developer"
  IMAGE_NAME="ubuntu:latest"
  MOUNT_PATH_ON_HOST="$HOME/source"
  MOUNT_PATH_IN_CONTAINER="/home/developer/host"
  USERNAME=root

  # Check if the container exists
  CONTAINER_ID=$(docker ps -a -q -f name=$CONTAINER_NAME)

  # If the container does not exist, create and run it
  if [ -z "$CONTAINER_ID" ]; then
      echo "Container does not exist. Creating and starting..."
      docker run -d \
        --name $CONTAINER_NAME \
        --user $USERNAME \
        -v $MOUNT_PATH_ON_HOST:$MOUNT_PATH_IN_CONTAINER \
        $IMAGE_NAME sleep infinity
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

  # Connect to the container
  echo "Connecting to container..."
  docker exec -it --user $USERNAME -w /home/developer $CONTAINER_NAME /bin/bash
