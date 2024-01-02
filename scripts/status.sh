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
NO_COLOR=0
SKIP_CONFIG_CHECK=1
SKIP_KUBERNETES_CHECK=1
SKIP_ARTIFACT_REGISTRY_CHECK=1

# Parse command line arguments
for arg in "$@"
do
    if [ "$arg" == "--no-color" ]; then
        NO_COLOR=1
    elif [ "$arg" == "--config" ]; then
        SKIP_CONFIG_CHECK=0
    elif [ "$arg" == "--kube" ]; then
        SKIP_KUBERNETES_CHECK=0
    elif [ "$arg" == "--docker" ]; then
        SKIP_ARTIFACT_REGISTRY_CHECK=0
    elif [ "$arg" == "--all" ]; then
        SKIP_CONFIG_CHECK=0
        SKIP_KUBERNETES_CHECK=0
        SKIP_ARTIFACT_REGISTRY_CHECK=0
    else
        print_message "Unknown argument: $arg. Accepted arguments:
    --no-color : Do not print color.
    --config   : Enable configuration check.
    --kube     : Enable Kubernetes check.
    --docker   : Enable artifact registry check.
    --all      : Enable all checks.
" "ERROR"
        exit 1
    fi
done

# If no arguments are provided, print usage and exit.
if [ $# -eq 0 ]; then
    print_message "No arguments provided.
Usage:

    status.sh [options]

Options:
    --no-color : Do not print color.
    --config   : Enable configuration check.
    --kube     : Enable Kubernetes check.
    --docker   : Enable artifact registry check.
    --all      : Enable all checks.
" "ERROR"
    exit 1
fi


if [ $SKIP_CONFIG_CHECK -eq 0 ]; then

    print_message "Checking configuration." "INFO"

    gcloud auth revoke --all --quiet > /dev/null 2>&1

    # Verify that we are logged out of gcloud
    ACTIVE_ACCOUNT=$(gcloud auth list --verbosity="error" --filter=status:ACTIVE --format="value(account)" )
    if [ -n "$ACTIVE_ACCOUNT" ]; then
        print_message "Failed to log out of gcloud." "ERROR"
        exit 1
    fi

    # Verify the $SERVICE_ACCOUNT_FILE exists
    if [ ! -f "$SERVICE_ACCOUNT_FILE" ]; then
        print_message "Service account key file ($SERVICE_ACCOUNT_FILE) does not exist." "ERROR"
        exit 1
    else
        print_message "Service account key file: $SERVICE_ACCOUNT_FILE" "OK"
    fi

    # Try a GKE operation that requires Kubernetes Engine Admin role
    gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_FILE > /dev/null 2>&1

    ACTIVE_ACCOUNT=$(gcloud auth list --verbosity="error" --filter=status:ACTIVE --format="value(account)")
    if [ ! -n "$ACTIVE_ACCOUNT" ]; then
        print_message "Service account activation failed." "ERROR"
        exit 1
    fi

    # Verify that we can list clusters
    CLUSTERS=$(gcloud container clusters list --verbosity="error" --quiet 2>/dev/null)
    # Check whether we have at least 1 cluster
    if [ $(echo "$CLUSTERS" | wc -l) -gt 1 ]; then
        print_message "The service account can list clusters." "OK"
    else
        print_message "The service account does not have sufficient permissions." "ERROR"
        exit 1
    fi

    # Verify that the GCP_PROJECT exists
    gcloud projects describe "$GCP_PROJECT" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_message "GCP project $GCP_PROJECT does not exist." "ERROR"
        exit 1
    else
        print_message "GCP project: $GCP_PROJECT" "OK"
    fi

    # Verify the current Kubernetes context
    current_context=$(kubectl config current-context)
    if [ "$current_context" != "$K8S_CONTEXT_NAME" ]; then
        print_message "Current context ($current_context) does not match the expected context ($K8S_CONTEXT_NAME)." "ERROR"
        exit 1
    else
        print_message "Kubernetes context: $current_context" "OK"
    fi

    # Verify that we can access the artifact registry via gcloud
    gcloud auth print-access-token > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_message "Could not access artifact registry. Please run 'gcloud auth login' and try again." "ERROR"
        exit 1
    else
        print_message "Artifact registry: $ARTIFACT_REGISTRY" "OK"
    fi
fi

if [ $SKIP_KUBERNETES_CHECK -eq 0 ]; then

    print_message "Checking status of live cluster." "INFO"

    print_message "Listing node pools" "INFO"
    echo

    gcloud container node-pools list --cluster="$K8S_CLUSTER_NAME"

    echo
    print_message "Listing nodes" "INFO"
    echo

    kubectl get nodes

    echo
    print_message "Listing pods in osai-kube" "INFO"
    echo

    kubectl get pods --namespace osai-kube

    echo
    print_message "Listing pods in kube-system" "INFO"
    echo

    kubectl get pods --namespace kube-system --context "$K8S_CONTEXT_NAME"

    echo
    print_message "Listing deployments in osai-kube" "INFO"
    echo

    kubectl get deployments --namespace osai-kube

    echo
    print_message "Listing services in osai-kube" "INFO"
    echo

    kubectl get services --namespace osai-kube

    echo
    print_message "Listing config maps in osai-kube" "INFO"
    echo

    kubectl get configmaps --namespace osai-kube

    echo

fi

process_images() {
    IMAGES=$(gcloud container images list --repository="$1" --format="value(NAME)")
    for IMAGE in $IMAGES; do
        # Get the JSON data for each image
        JSON_DATA=$(gcloud container images list-tags "$IMAGE" --limit=1 --sort-by=~TIMESTAMP --format="json(tags, digest, timestamp)")

        # Parse JSON and format the output
        if [ ! -z "$JSON_DATA" ]; then
            SHORT_IMAGE_NAME=$(echo "$IMAGE" | sed "s|$ARTIFACT_REGISTRY/||g")
            TAGS=$(echo $JSON_DATA | jq -r '.[0].tags | join(", ")')
            FULL_DIGEST=$(echo $JSON_DATA | jq -r '.[0].digest')
            # Truncate the digest to the first 12 characters
            DIGEST=${FULL_DIGEST:7:12}
            TIMESTAMP=$(echo $JSON_DATA | jq -r '.[0].timestamp.datetime')

            # Combine the formatted information
            FORMATTED_INFO="$SHORT_IMAGE_NAME|$TAGS|$DIGEST|$TIMESTAMP"
            image_info_list+=("$FORMATTED_INFO")
        fi
    done
}

if [ $SKIP_ARTIFACT_REGISTRY_CHECK -eq 0 ]; then
    print_message "Checking artifact registry." "INFO"

    # Activate the service account
    gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_FILE > /dev/null 2>&1

    # Configure Docker to use gcloud as a credential helper
    gcloud auth configure-docker --quiet --verbosity="error" > /dev/null 2>&1

    # Initialize an array to store the image information
    declare -a image_info_list
    image_info_list=("IMAGE|TAG|DIGEST|TIMESTAMP")

    # Fetch all top-level repositories
    TOP_LEVEL_REPOS=$(gcloud container images list --repository="$ARTIFACT_REGISTRY" --format="value(NAME)")

    for REPO in $TOP_LEVEL_REPOS; do
        if [[ "$REPO" =~ "johnshaughnessy" ]]; then
            SUB_REPOS=$(gcloud container images list --repository="$REPO" --format="value(NAME)")
            for SUB_REPO in $SUB_REPOS; do
                process_images "$SUB_REPO"
            done
        else
            process_images "$REPO"
        fi
    done

    # Output the data using column
    printf "%s\n" "${image_info_list[@]}" | column -t -s '|'
fi
