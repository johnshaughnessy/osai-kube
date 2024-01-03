from google.cloud import container_v1
from google.oauth2 import service_account
import configparser
import os

def load_doodle_config(ini_file_path='config.ini'):
    config = configparser.ConfigParser()
    config.read(ini_file_path)

    gcp_config = {
        'GCP_PROJECT': config.get('gcp', 'GCP_PROJECT'),
        'CLOUDSDK_COMPUTE_ZONE': config.get('gcp', 'CLOUDSDK_COMPUTE_ZONE'),
        'SERVICE_ACCOUNT_FILE': config.get('gcp', 'SERVICE_ACCOUNT_FILE', fallback='server/service-account-key.json'),
        'K8S_CLUSTER_NAME': config.get('kubernetes', 'K8S_CLUSTER_NAME'),
        'GPU_TYPE': 'nvidia-tesla-t4',
        'MACHINE_TYPE': 'n1-standard-4',
        'GPU_COUNT': 1,
        'NODE_POOL_NAME': config.get('doodle', 'DOODLE_NODE_POOL_NAME'),
        'NODE_POOL_LABEL': config.get('doodle', 'DOODLE_NODE_POOL_LABEL')
    }

    return gcp_config

def create_gpu_node_pool(config_data):
    project_id = config_data['GCP_PROJECT']
    zone = config_data['CLOUDSDK_COMPUTE_ZONE']
    cluster_name = config_data['K8S_CLUSTER_NAME']
    service_account_file = config_data['SERVICE_ACCOUNT_FILE']
    gpu_type = config_data['GPU_TYPE']
    gpu_count = config_data['GPU_COUNT']
    node_pool_name = config_data['NODE_POOL_NAME']
    node_pool_label = config_data['NODE_POOL_LABEL']
    machine_type = config_data['MACHINE_TYPE']

    credentials = service_account.Credentials.from_service_account_file(service_account_file)
    gcp_client = container_v1.ClusterManagerClient(credentials=credentials)

    node_config = container_v1.NodeConfig(
        machine_type=machine_type,
        accelerators=[container_v1.AcceleratorConfig(
            accelerator_count=gpu_count,
            accelerator_type=gpu_type)],
        labels={'pool': node_pool_label},
        image_type="COS_CONTAINERD"
    )

    node_pool = container_v1.NodePool(
        name=node_pool_name,
        initial_node_count=1,
        config=node_config
    )

    gcp_client.create_node_pool(
        project_id=project_id,
        zone=zone,
        cluster_id=cluster_name,
        node_pool=node_pool
    )


def delete_gpu_node_pool(config_data):
    project_id = config_data['GCP_PROJECT']
    zone = config_data['CLOUDSDK_COMPUTE_ZONE']
    cluster_name = config_data['K8S_CLUSTER_NAME']
    node_pool_name = config_data['NODE_POOL_NAME']
    service_account_file = config_data['SERVICE_ACCOUNT_FILE']

    credentials = service_account.Credentials.from_service_account_file(service_account_file)
    gcp_client = container_v1.ClusterManagerClient(credentials=credentials)

    gcp_client.delete_node_pool(
        project_id=project_id,
        zone=zone,
        cluster_id=cluster_name,
        node_pool_id=node_pool_name
    )
