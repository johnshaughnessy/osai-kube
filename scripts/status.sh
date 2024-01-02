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
SKIP_CONFIG_CHECK=0

# Parse command line arguments
for arg in "$@"
do
    if [ "$arg" == "--no-color" ]; then
        NO_COLOR=1
    elif [ "$arg" == "--skip-config-check" ]; then
        SKIP_CONFIG_CHECK=1
    fi
done

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
else
    print_message "Skipping configuration check." "INFO"
fi

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
