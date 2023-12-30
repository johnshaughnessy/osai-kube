#!/bin/bash

# Load configuration
source <(grep = config.ini | sed 's/ *= */=/g')

# Set variables
IMAGE_NAME="osai-kube/supervisor"
TAG="latest"
FULL_IMAGE_NAME="${artifact_registry}/${IMAGE_NAME}:${TAG}"

# Updating Kubernetes Deployment
echo "Updating Kubernetes Deployment..."
kubectl set image deployment/${deployment_name} supervisor="${FULL_IMAGE_NAME}" --namespace=${namespace}

echo "Deployment update complete."
