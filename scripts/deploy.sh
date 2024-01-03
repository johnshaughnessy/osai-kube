#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/set_environment_variables.sh"

CONFIG_DIR="$SCRIPT_DIR/../kubernetes-configs"

print_message() {
    if [ "$2" == "ERROR" ]; then
        # Red color for error
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2]      $1" || echo -e "[osai-kube] [\033[0;31m$2\033[0m]      $1"
    elif [ "$2" == "OK" ]; then
        # Green color for OK
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m]         $1"
    elif [ "$2" == "UNCHANGED" ]; then
        # Gray color for unchanged
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [OK]  $1" || echo -e "[osai-kube] [\033[0;37m$2\033[0m]  $1"
    elif [ "$2" == "CREATED" ]; then
        # Green color for created
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2]    $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m]    $1"
    elif [ "$2" == "UPDATED" ]; then
        # Green color for updated
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2]    $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m]    $1"
    elif [ "$2" == "CONFIGURED" ]; then
        # Green color for configured
        [ "$NO_COLOR" == "1" ] && echo "[osai-kube] [$2] $1" || echo -e "[osai-kube] [\033[0;32m$2\033[0m] $1"
    else
        # No color for other messages
        echo "[osai-kube] [$2] $1"
    fi
}

k8s_apply_config() {
    output=$(kubectl apply -f $1 2>&1)
    result=$?

    filename=$(basename $1)
    filename_with_parent=$(echo $1 | sed "s|$CONFIG_DIR/||g")

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

update_deployment_image() {
    local deployment_file="$1"
    local filename_with_parent=$(echo $deployment_file | sed "s|$CONFIG_DIR/||g")
    local image_name="$2"

    local image_digest=$(gcloud container images list-tags "$ARTIFACT_REGISTRY/$image_name" --limit=1 --sort-by=~TIMESTAMP --format="json" | jq -r ".[0].digest")
    local full_image="\$(ARTIFACT_REGISTRY)/${image_name}@${image_digest}"

    # Make a backup of the original file for comparison
    cp "$deployment_file" "${deployment_file}.bak"

    # Update the deployment YAML file
    sed -i "s|image: .*|image: $full_image|" "$deployment_file"

    # Check if the file was changed
    if cmp -s "${deployment_file}.bak" "$deployment_file"; then
        print_message "No change to $image_name in $filename_with_parent." "UNCHANGED"
    else
        print_message "Updated $image_name in $filename_with_parent to $image_digest." "UPDATED"
    fi

    # Remove the backup file
    rm "${deployment_file}.bak"
}


SUPERVISOR_DEPLOYMENT_FILE="$CONFIG_DIR/deployments/supervisor-deployment.yaml"
SUPERVISOR_IMAGE_NAME="osai-kube/supervisor"
update_deployment_image "$SUPERVISOR_DEPLOYMENT_FILE" "$SUPERVISOR_IMAGE_NAME"

DOODLE_DEPLOYMENT_FILE="$CONFIG_DIR/deployments/doodle-deployment.yaml"
DOODLE_IMAGE_NAME="browserlab/doodle"
update_deployment_image "$DOODLE_DEPLOYMENT_FILE" "$DOODLE_IMAGE_NAME"

# Apply namespace configs first
namespace_configs=$(find $CONFIG_DIR/namespaces -type f -name "*.yaml")
for config in $namespace_configs; do
    k8s_apply_config $config
done

configs=$(find $CONFIG_DIR -type f -name "*.yaml" ! -path "$CONFIG_DIR/namespaces/*")
for config in $configs; do
    k8s_apply_config $config
done

