#!/bin/bash

# Directory to store all images
STORAGE_DIR=/opt/devatserv/share/storage

# Move to images storage
cd "$STORAGE_DIR"

# Load all Docker images from storage
for IMAGE_FILE in "$STORAGE_DIR"/*.tar.gz; do
  echo "Loading Docker image from $IMAGE_FILE..."
  docker load -i "$IMAGE_FILE"
done
