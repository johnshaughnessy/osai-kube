import os
import logging
import sys
from google.cloud import container_v1
from google.oauth2 import service_account
from kubernetes import client, config

# Constants
PROJECT_ID = "hubs-dev-333333"
ZONE = "us-central1-c"
CLUSTER_NAME = "ocho-osai-cluster-1"
NODE_POOL_NAME = "doodle-node-pool"
DOODLE_DEPLOYMENT_NAME = "doodle-deployment"
NAMESPACE = "osai-kube"
GPU_TYPE = "nvidia-tesla-t4"
GPU_COUNT = 1

# Configure logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s]: %(message)s')

# The service account file is in the same directory as this script
service_account_file = os.path.join(os.path.dirname(__file__), "service-account-key.json")

# Initialize GCP Container client with specified service account
credentials = service_account.Credentials.from_service_account_file(service_account_file)
gcp_client = container_v1.ClusterManagerClient(credentials=credentials)

# Initialize Kubernetes client
config.load_incluster_config()
kube_client = client.AppsV1Api()

def create_gpu_node_pool():
    logging.info("Creating GPU node pool with automatic GPU driver installation...")
    node_config = container_v1.NodeConfig(
        machine_type="n1-standard-4",
        accelerators=[container_v1.AcceleratorConfig(
            accelerator_count=GPU_COUNT,
            accelerator_type=GPU_TYPE)],
        labels={'pool': 'doodle'},
        image_type="COS_CONTAINERD",  # Use a GPU-compatible image type
        metadata={"nvidia-driver-installer": "cos-stable"}
    )
    node_pool = container_v1.NodePool(
        name=NODE_POOL_NAME,
        initial_node_count=1,
        config=node_config
    )
    operation = gcp_client.create_node_pool(
        project_id=PROJECT_ID,
        zone=ZONE,
        cluster_id=CLUSTER_NAME,
        node_pool=node_pool
    )
    logging.info(f"Node pool creation operation: {operation.name}")


def delete_node_pool():
    logging.info("Deleting GPU node pool...")
    operation = gcp_client.delete_node_pool(
        project_id=PROJECT_ID,
        zone=ZONE,
        cluster_id=CLUSTER_NAME,
        node_pool_id=NODE_POOL_NAME
    )
    logging.info(f"Node pool deletion operation ID: {operation.name}")

def get_dedicated_doodle_node_pool():
    try:
        logging.info("Checking for existing dedicated 'doodle' node pool...")
        response = gcp_client.list_node_pools(project_id=PROJECT_ID, zone=ZONE, cluster_id=CLUSTER_NAME)
        for node_pool in response.node_pools:
            if node_pool.name == NODE_POOL_NAME:
                return node_pool
        return None
    except Exception as e:
        logging.error(f"Error checking for node pool: {e}")
        return None


def scale_doodle_deployment(replicas):
    logging.info(f"Scaling 'doodle' deployment to {replicas} replicas...")
    deployment = kube_client.read_namespaced_deployment(DOODLE_DEPLOYMENT_NAME, NAMESPACE)
    deployment.spec.replicas = replicas
    kube_client.patch_namespaced_deployment(DOODLE_DEPLOYMENT_NAME, NAMESPACE, deployment)
    logging.info("'doodle' deployment scaled successfully.")

def start_doodle():
    logging.info("Starting 'doodle' service...")
    node_pool = get_dedicated_doodle_node_pool()
    if not node_pool:
        create_gpu_node_pool()
    scale_doodle_deployment(1)
    logging.info("'doodle' service started.")

def stop_doodle():
    logging.info("Stopping 'doodle' service...")
    scale_doodle_deployment(0)
    delete_node_pool()
    logging.info("'doodle' service stopped.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        logging.error("Usage: python test-node-up-down.py [start|stop]")
        sys.exit(1)

    action = sys.argv[1]
    if action == "start":
        start_doodle()
    elif action == "stop":
        stop_doodle()
    else:
        logging.error("Invalid argument. Use 'start' or 'stop'.")
        sys.exit(1)
