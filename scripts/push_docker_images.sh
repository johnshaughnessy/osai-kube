#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/set_environment_variables.sh"

print_message() {
    if [ "$2" == "ERROR" ]; then
        # Red color for error
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;31m$2\033[0m] $1"
    elif [ "$2" == "OK" ]; then
        # Green color for OK
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m]    $1"
    else
        # No color for other messages
        echo "[osai-kube] [$2]   $1"
    fi
}

full_image_name(){
    echo "${ARTIFACT_REGISTRY}/${1}:${2}"
}

gcloud auth activate-service-account --quiet --key-file=$SERVICE_ACCOUNT_FILE >/dev/null 2>&1
gcloud auth configure-docker --quiet $ARTIFACT_REGISTRY_PREFIX >/dev/null 2>&1

push_to_artifact_registry(){
    IMAGE_NAME=$1
    SHORT_IMAGE_NAME=$2
    print_message "Uploading $SHORT_IMAGE_NAME image to artifact registry." "INFO"
    #docker push --quiet $IMAGE_NAME > /dev/null 2>&1
    docker push $IMAGE_NAME
    if [ $? -ne 0 ]; then
        print_message "Failed to upload $SHORT_IMAGE_NAME image to artifact registry." "ERROR"
        exit 1
    else
        print_message "Uploaded $SHORT_IMAGE_NAME image to artifact registry." "OK"
    fi
}

SUPERVISOR_FULL_IMAGE_NAME=$(full_image_name "osai-kube/supervisor" "latest")
push_to_artifact_registry $SUPERVISOR_FULL_IMAGE_NAME "supervisor"

if [ "$ENABLE_DOODLE" == "1" ]; then
    DOODLE_FULL_IMAGE_NAME=$(full_image_name $DOODLE_IMAGE_NAME "latest")
    push_to_artifact_registry $DOODLE_FULL_IMAGE_NAME "doodle"
fi
