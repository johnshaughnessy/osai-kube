#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/set_environment_variables.sh"

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

full_image_name(){
    echo "${ARTIFACT_REGISTRY}/${1}:${2}"
}

SUPERVISOR_IMAGE_NAME=$(full_image_name "supervisor" "latest")

gcloud auth configure-docker --quiet --verbosity="error" > /dev/null 2>&1
print_message "Uploading supervisor image to artifact registry." "INFO"
docker push --quiet $SUPERVISOR_IMAGE_NAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_message "Failed to upload supervisor image to artifact registry." "ERROR"
    exit 1
else
    print_message "Uploaded supervisor image to artifact registry." "OK"
fi
