#!/bin/bash
#
# Delete postgres from the live kube cluster

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/set_environment_variables.sh"
source "$SCRIPT_DIR/log.sh"

log "WARN" "This script will delete ALL POSTGRES DATA in the live kube cluster."

# Force the user to confirm the deletion
read -p "Are you sure you want to delete postgres from the live kube cluster? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "INFO" "Aborting."
    exit 0
fi

log "WARN" "This script deletes ALL POSTGRES DATA, including the PV and PVC. Make sure you have a backup!"

log "INFO" "Checking the status of postgres in the live kube cluster..."

kubectl get statefulset postgresql
kubectl get pvc -l app=postgresql -o name

log "WARN" "Make sure the above resources are the ones you want to delete."

# Force the user to type the word "DELETE" in all caps to proceed

read -p "Type the word DELETE in all caps to proceed: " -r
echo ""

if [[ $REPLY != "DELETE" ]]; then
    log "INFO" "Aborting."
    exit 0
fi

log "INFO" "Deleting postgres from the live kube cluster..."
kubectl delete statefulset postgresql
kubectl get pvc -l app=postgresql -o name | xargs kubectl delete
