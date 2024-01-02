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

# Initialize flags
NO_SUPERVISOR=0

# Parse command line arguments
for arg in "$@"
do
    if [ "$arg" == "--no-supervisor" ]; then
        NO_SUPERVISOR=1
    fi
done

full_image_name(){
    echo "${ARTIFACT_REGISTRY}/${1}:${2}"
}

# Build the supervisor image (if not skipped)
if [ $NO_SUPERVISOR -eq 0 ]; then
    SUPERVISOR_IMAGE_NAME=$(full_image_name "osai-kube/supervisor" "latest")
    SUPERVISOR_DOCKER_FILE="Dockerfile.supervisor"
    SUPERVISOR_DOCKER_CONTEXT="$SCRIPT_DIR/../supervisor"

    pushd $SUPERVISOR_DOCKER_CONTEXT > /dev/null
    print_message "Building the supervisor image." "INFO"
    docker build -f $SUPERVISOR_DOCKER_FILE -t $SUPERVISOR_IMAGE_NAME .
    popd > /dev/null
    if [ $? -ne 0 ]; then
        print_message "Failed to build the supervisor image." "ERROR"
        exit 1
    else
        print_message "Successfully built the supervisor image." "OK"
    fi
else
    print_message "Skipping supervisor image build." "INFO"
fi
