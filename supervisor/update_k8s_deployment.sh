#!/bin/bash

# Load configuration
source <(grep = config.ini | sed 's/ *= */=/g')

# Verify the current Kubernetes context
current_context=$(kubectl config current-context)
if [ "$current_context" != "$context_name" ]; then
    echo "Error: Current context ($current_context) does not match the expected context ($context_name)."
    exit 1
fi


# Check if the namespace exists
if kubectl get namespace "$namespace" > /dev/null 2>&1; then
    echo "Namespace $namespace already exists."
else
    echo "Creating namespace $namespace..."
    kubectl create namespace "$namespace"
fi
echo "Ensuring that the registry-config ConfigMap exists..."
kubectl apply -f registry-config.yaml --namespace=${namespace}
echo "Ensuring that the supervisor-deployment Deployment exists..."
kubectl apply -f supervisor-deployment.yaml --namespace=${namespace}

# Updating Kubernetes Deployment
echo "Updating Kubernetes Deployment..."
# Set variables
IMAGE_NAME="osai-kube/supervisor"
TAG="latest"
FULL_IMAGE_NAME="${artifact_registry}/${IMAGE_NAME}:${TAG}"
kubectl set image deployment/${deployment_name} supervisor="${FULL_IMAGE_NAME}" --namespace=${namespace}

echo "Deployment update complete."
