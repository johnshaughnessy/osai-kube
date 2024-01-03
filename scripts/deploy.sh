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
    elif [ "$2" == "UNCHANGED" ]; then
        # Gray color for unchanged
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [OK] $1" || echo -e "[osai-kube] [\033[0;37m$2\033[0m] $1"
    elif [ "$2" == "CREATED" ]; then
        # Green color for created
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m] $1"
    elif [ "$2" == "CONFIGURED" ]; then
        # Green color for configured
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m] $1"
    else
        # No color for other messages
        echo "[osai-kube] [$2] $1"
    fi
}

apply_k8s_config() {
    output=$(kubectl apply -f $1 2>&1)
    result=$?

    filename=$(basename $1)
    filename_with_parent=$(echo $1 | sed "s|$CONFIG_DIR||g")

    if [ $result -ne 0 ]; then
        print_message "Failed to apply $(basename $1): $output" "ERROR"
        exit 1
    else
        if [[ $output == *"unchanged"* ]]; then
            # Do not print anything if unchanged
            print_message "Applied $filename_with_parent" "UNCHANGED"
        elif [[ $output == *"created"* ]]; then
            print_message "Applied $filename_with_parent" "CREATED"
        elif [[ $output == *"configured"* ]]; then
            print_message "Applied $filename_with_parent" "CONFIGURED"
        else
            print_message "Applied $filename_with_parent: $output" "OK"
        fi
    fi
}

OSAI_KUBE_NAMESPACE="osai-kube"
# Ensure osai-kube namespace exists
if kubectl get namespace $OSAI_KUBE_NAMESPACE > /dev/null 2>&1; then
    print_message "Namespace $OSAI_KUBE_NAMESPACE exists." "OK"
else
    kubectl create namespace "$namespace"
    if kubectl get namespace $OSAI_KUBE_NAMESPACE > /dev/null 2>&1; then
        print_message "Created namespace: $OSAI_KUBE_NAMESPACE." "OK"
    else
        print_message "Failed to create namespace $OSAI_KUBE_NAMESPACE." "ERROR"
        exit 1
    fi
fi

CONFIG_DIR="$SCRIPT_DIR/../kubernetes-configs/"

configs=$(find $CONFIG_DIR -type f -name "*.yaml")

for config in $configs; do
    apply_k8s_config $config
done

SUPERVISOR_IMAGE_DIGEST=$(gcloud container images list-tags "$ARTIFACT_REGISTRY/osai-kube/supervisor" --limit=1 --sort-by=~TIMESTAMP --format="json" | jq -r ".[0].digest")
SUPERVISOR_IMAGE="${ARTIFACT_REGISTRY}/osai-kube/supervisor@$SUPERVISOR_IMAGE_DIGEST"
print_message "Updating supervisor image to $SUPERVISOR_IMAGE." "INFO"
kubectl set image deployment/supervisor-deployment supervisor="${SUPERVISOR_IMAGE}"
