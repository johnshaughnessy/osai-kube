#!/bin/bash

# Load configuration
source <(grep = config.ini | sed 's/ *= */=/g')

# Set variables
IMAGE_NAME="osai-kube/supervisor"
TAG="latest"
FULL_IMAGE_NAME="${artifact_registry}/${IMAGE_NAME}:${TAG}"

# Building the Docker image
echo "Building Docker image: ${IMAGE_NAME}:${TAG}"
docker build -f Dockerfile.supervisor -t "${FULL_IMAGE_NAME}" .

# Authenticating with Google Cloud (ensure gcloud is configured)
echo "Authenticating with Google Cloud."
gcloud auth configure-docker --quiet

# Pushing the image to the Artifact Registry
echo "Pushing the image to the Artifact Registry: ${FULL_IMAGE_NAME}"
docker push "${FULL_IMAGE_NAME}"

echo "Upload complete."
