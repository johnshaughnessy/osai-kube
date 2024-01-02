#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/set_environment_variables.sh"

# Function to display messages
print_message() {
    if [ "$2" == "ERROR" ]; then
        # Red color for error
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;31m$2\033[0m] $1"
    elif [ "$2" == "OK" ]; then
        # Green color for OK
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m] $1"
    else
        # No color for other messages
        echo "[osai-kube] [$2] $1"
    fi
}

# Set $LABEL based on the first command line argument
if [ -z "$1" ]; then
    print_message "Target required: (supervisor | gpu-diagnostic-pod | doodle | chat)" "ERROR"
    exit 1

elif [ "$1" == "gpu-diagnostic-pod" ]; then
    POD_NAME="gpu-diagnostic-pod"
else
    LABEL="app=$1"
    POD_NAME=$(kubectl get pods -l $LABEL -o jsonpath="{.items[0].metadata.name}" 2> /dev/null)
fi

if [ -z "$POD_NAME" ]; then
    echo "No pod found for $1."
    exit 1
fi

kubectl logs -f $POD_NAME
