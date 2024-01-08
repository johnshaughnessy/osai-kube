#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/set_environment_variables.sh"

MANIFEST_DIR="$SCRIPT_DIR/../kubernetes-manifests"

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
        echo "[osai-kube] [$2]       $1"
    fi
}

k8s_apply_config() {
    local config_file="$1"

    # Apply the processed configuration file
    output=$(kubectl apply -f "$config_file" 2>&1)
    result=$?

    filename=$(basename $1)
    filename_with_parent=$(echo $1 | sed "s|$MANIFEST_DIR/||g")

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
    local container_name="$2"
    local image_name="$3"

    local image_digest=$(gcloud container images list-tags "$ARTIFACT_REGISTRY/$image_name" --limit=1 --sort-by=~TIMESTAMP --format="json" | jq -r ".[0].digest")

    local full_image="$ARTIFACT_REGISTRY/${image_name}@${image_digest}"

    local filename=$(basename $1)
    local filename_with_parent=$(echo $1 | sed "s|$MANIFEST_DIR/||g")

    # Make a backup of the original file for comparison
    cp "$deployment_file" "${deployment_file}.bak"

    # Update the deployment YAML file
    sed -i "/name: $container_name/,/image:/s|image: .*|image: $full_image|" "$deployment_file"

    # Check if the file was changed
    if cmp -s "${deployment_file}.bak" "$deployment_file"; then
        print_message "No change to $image_name in $filename_with_parent." "UNCHANGED"
    else
        print_message "Updated $image_name in $filename_with_parent to $image_digest." "UPDATED"
    fi

    # Remove the backup file
    rm "${deployment_file}.bak"
}

SUPERVISOR_DEPLOYMENT_FILE="$MANIFEST_DIR/deployments/supervisor-deployment.yaml"
SUPERVISOR_IMAGE_NAME="osai-kube/supervisor"
SUPERVISOR_CONTAINER_NAME="supervisor"
update_deployment_image "$SUPERVISOR_DEPLOYMENT_FILE" "$SUPERVISOR_CONTAINER_NAME" "$SUPERVISOR_IMAGE_NAME"

DOODLE_DEPLOYMENT_FILE="$MANIFEST_DIR/deployments/doodle-deployment.yaml"
DOODLE_IMAGE_NAME="browserlab/doodle"
DOODLE_CONTAINER_NAME="doodle"
update_deployment_image "$DOODLE_DEPLOYMENT_FILE" "$DOODLE_CONTAINER_NAME" "$DOODLE_IMAGE_NAME"

# Apply namespace configs first
print_message "Applying namespace configurations..." "INFO"
namespace_configs=$(find $MANIFEST_DIR/namespaces -type f -name "*.yaml")
for config in $namespace_configs; do
    k8s_apply_config $config
done

# Apply CRDs next
print_message "Applying CRDs..." "INFO"
crd_configs=$(find $MANIFEST_DIR/crds -type f -name "*.yaml")
for config in $crd_configs; do
    k8s_apply_config $config
done

# Apply ConfigMaps
print_message "Applying ConfigMaps..." "INFO"
config_map_configs=$(find $MANIFEST_DIR/config-maps -type f -name "*.yaml")
for config in $config_map_configs; do
    k8s_apply_config $config
done

# Apply Secrets
print_message "Applying Secrets..." "INFO"
$SCRIPT_DIR/write-gatekeeper-doodle-secret.sh
secret_configs=$(find $MANIFEST_DIR/secrets -type f -name "*.yaml" ! -name "gatekeeper-doodle-config.yaml")

for config in $secret_configs; do
    k8s_apply_config $config
done

# Apply RBAC roles and role bindings
print_message "Applying RBAC configurations..." "INFO"
rbac_configs=$(find $MANIFEST_DIR/roles -type f -name "*.yaml")
for config in $rbac_configs; do
    k8s_apply_config $config
done

# Apply Service Accounts
print_message "Applying Service Accounts..." "INFO"
service_account_configs=$(find $MANIFEST_DIR/service-accounts -type f -name "*.yaml")
for config in $service_account_configs; do
    k8s_apply_config $config
done

# Apply Storage: PVCs
print_message "Applying Persistent Volume Claims..." "INFO"
pvc_configs=$(find $MANIFEST_DIR/pvcs -type f -name "*.yaml")
for config in $pvc_configs; do
    k8s_apply_config $config
done

# Apply Middleware configurations
print_message "Applying Middleware configurations..." "INFO"
middleware_configs=$(find $MANIFEST_DIR/middleware -type f -name "*.yaml")
for config in $middleware_configs; do
    k8s_apply_config $config
done

# Apply Services
print_message "Applying Service configurations..." "INFO"
service_configs=$(find $MANIFEST_DIR/services -type f -name "*.yaml")
for config in $service_configs; do
    k8s_apply_config $config
done

# Apply StatefulSets
print_message "Applying StatefulSets..." "INFO"
stateful_set_configs=$(find $MANIFEST_DIR/stateful-sets -type f -name "*.yaml")
for config in $stateful_set_configs; do
    k8s_apply_config $config
done

# Apply Deployments
print_message "Applying Deployments..." "INFO"
deployment_configs=$(find $MANIFEST_DIR/deployments -type f -name "*.yaml")
for config in $deployment_configs; do
    k8s_apply_config $config
done

# Apply DaemonSets
print_message "Applying DaemonSets..." "INFO"
daemonset_configs=$(find $MANIFEST_DIR/daemonsets -type f -name "*.yaml")
for config in $daemonset_configs; do
    k8s_apply_config $config
done

# Apply Ingress configurations last
print_message "Applying Ingress configurations..." "INFO"
ingress_configs=$(find $MANIFEST_DIR/ingress -type f -name "*.yaml")
for config in $ingress_configs; do
    k8s_apply_config $config
done

print_message "All configurations have been applied." "INFO"
