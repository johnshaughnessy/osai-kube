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

echo "Applying registry config map..."
kubectl apply -f registry-config.yaml --namespace=${namespace}

echo "Ensuring that the supervisor deployment/service exists..."
kubectl apply -f supervisor-deployment.yaml --namespace=${namespace}
kubectl apply -f supervisor-service.yaml --namespace=${namespace}

echo "Ensuring that the doodle deployment/service exists..."
kubectl apply -f doodle-deployment.yaml --namespace=${namespace}
kubectl apply -f doodle-service.yaml --namespace=${namespace}

echo "Applying roles and role bindings..."
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml

kubectl apply -f deployment-manager-role.yaml
kubectl apply -f deployment-manager-role-binding.yaml

kubectl apply -f clusterrole.yaml
kubectl apply -f clusterrolebinding.yaml

# Updating Kubernetes Deployment
echo "Updating Kubernetes Deployment..."
# Set variables
IMAGE_NAME="osai-kube/supervisor"
TAG="latest"
FULL_IMAGE_NAME="${artifact_registry}/${IMAGE_NAME}:${TAG}"

# Force a new rollout
kubectl set image deployment/${deployment_name} supervisor="${FULL_IMAGE_NAME}" --namespace=${namespace}
kubectl rollout restart deployment/${deployment_name} --namespace=${namespace}

echo "Deployment update complete."
