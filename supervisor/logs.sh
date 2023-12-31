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
if ! kubectl get namespace "$namespace" > /dev/null 2>&1; then
    echo "Namespace $namespace does not exist."
    exit 1
fi

# Set the namespace and correct label
NAMESPACE="osai-kube"
LABEL="app=supervisor"  # Replace with the actual label key-value
LABEL="app=doodle"  # Replace with the actual label key-value

# Find a pod with the given label
POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l $LABEL -o jsonpath="{.items[0].metadata.name}")

# Check if a pod name was found
if [ -z "$POD_NAME" ]; then
    echo "No pod found with label $LABEL in namespace $NAMESPACE."
    exit 1
fi

kubectl logs -f $POD_NAME