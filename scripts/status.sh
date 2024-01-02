#!/bin/bash
#
# This script confirms that the values in config.ini are valid and your have the access you need.
#
# It also checks the status of the live Kubernetes cluster.
#

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/set_environment_variables.sh"

gcloud auth revoke --all --quiet > /dev/null 2>&1

# Verify that we are logged out of gcloud
ACTIVE_ACCOUNT=$(gcloud auth list --verbosity="error" --filter=status:ACTIVE --format="value(account)" )
if [ -n "$ACTIVE_ACCOUNT" ]; then
    echo "[osai-kube] [ERROR] Failed to log out of gcloud."
    exit 1
fi

# Verify the $SERVICE_ACCOUNT_FILE exists
if [ ! -f "$SERVICE_ACCOUNT_FILE" ]; then
    echo "[osai-kube] [ERROR] Service account key file ($SERVICE_ACCOUNT_FILE) does not exist."
    exit 1
else
    echo "[osai-kube] [INFO] Service account key file: $SERVICE_ACCOUNT_FILE"
fi

# Try a GKE operation that requires Kubernetes Engine Admin role
gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_FILE > /dev/null 2>&1

ACTIVE_ACCOUNT=$(gcloud auth list --verbosity="error" --filter=status:ACTIVE --format="value(account)")
if [ ! -n "$ACTIVE_ACCOUNT" ]; then
    echo "[osai-kube] [ERROR] Service account activation failed."
    exit 1
fi

# Verify that we can list clusters
CLUSTERS=$(gcloud container clusters list --verbosity="error" --quiet 2>/dev/null)
# Check whether we have at least 1 cluster
if [ $(echo "$CLUSTERS" | wc -l) -gt 1 ]; then
    echo "[osai-kube] [INFO] The service account can list clusters."
else
    echo "[osai-kube] [ERROR] The service account does not have sufficient permissions."
    exit 1
fi

# Verify that the GCP_PROJECT exists
#echo "[osai-kube] [INFO] Verifying that the GCP project ($GCP_PROJECT) exists..."
gcloud projects describe "$GCP_PROJECT" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[osai-kube] [ERROR] GCP project $GCP_PROJECT does not exist."
    exit 1
else
    echo "[osai-kube] [INFO] GCP project: $GCP_PROJECT"
fi

# Verify the current Kubernetes context
# echo "[osai-kube] [INFO] Verifying the current Kubernetes context..."
current_context=$(kubectl config current-context)
if [ "$current_context" != "$K8S_CONTEXT_NAME" ]; then
    echo "[osai-kube] [ERROR] Current context ($current_context) does not match the expected context ($K8S_CONTEXT_NAME)."
    exit 1
else
    echo "[osai-kube] [INFO] Kubernetes context: $current_context"
fi

# Verify that we can access the artifact registry via gcloud ($ARTIFACT_REGISTRY)
gcloud auth print-access-token > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[osai-kube] [ERROR] Could not access artifact registry. Please run 'gcloud auth login' and try again."
    exit 1
else
    echo "[osai-kube] [INFO] Artifact registry: $ARTIFACT_REGISTRY"
fi
