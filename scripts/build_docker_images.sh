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
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m]    $1"
    else
        # No color for other messages
        echo "[osai-kube] [$2]  $1"
    fi
}

# Initialize flags
NO_SUPERVISOR=0
NO_DOODLE=0

# Parse command line arguments
for arg in "$@"
do
    if [ "$arg" == "--no-supervisor" ]; then
        NO_SUPERVISOR=1
    elif [ "$arg" == "--no-doodle" ]; then
        NO_DOODLE=1
    fi
done

full_image_name(){
    echo "${ARTIFACT_REGISTRY}/${1}:${2}"
}


build_image() {
    local image_name="$1"
    local docker_file="$2"
    local docker_context="$3"
    local image_tag="$4"

    pushd $docker_context > /dev/null
    print_message "Building the $image_name image." "INFO"
    docker build -f $docker_file -t $image_tag .
    popd > /dev/null
    if [ $? -ne 0 ]; then
        print_message "Failed to build the $image_name image." "ERROR"
        exit 1
    else
        print_message "Successfully built the $image_name image." "OK"
    fi
}


# Build the supervisor image (if not skipped)
if [ $NO_SUPERVISOR -eq 0 ]; then
    SUPERVISOR_DOCKERFILE=Dockerfile.supervisor
    SUPERVISOR_DIRECTORY="$SCRIPT_DIR/../supervisor"
    SUPERVISOR_IMAGE_NAME=$(full_image_name "osai-kube/supervisor" "latest")
    build_image "supervisor" $SUPERVISOR_DOCKERFILE "$SUPERVISOR_DIRECTORY" $SUPERVISOR_IMAGE_NAME
fi

# Build the doodle image (if not skipped)
if [ $NO_DOODLE -eq 0 ] && [ $ENABLE_DOODLE -eq 1 ]; then
    build_image "doodle" $DOODLE_DOCKERFILE "$DOODLE_DIRECTORY" "$(full_image_name $DOODLE_IMAGE_NAME "latest")"
fi
