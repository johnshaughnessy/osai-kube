from kubernetes import client, config

def load_kube_config():
    config.load_incluster_config()

def get_cluster_info():
    load_kube_config()
    v1 = client.CoreV1Api()
    nodes = v1.list_node()
    return [{"name": node.metadata.name, "labels": node.metadata.labels} for node in nodes.items]

def update_deployment_replicas(deployment_name, replicas, namespace):
    load_kube_config()
    apps_v1 = client.AppsV1Api()
    deployment = apps_v1.read_namespaced_deployment(deployment_name, namespace)
    deployment.spec.replicas = replicas
    apps_v1.patch_namespaced_deployment(deployment_name, namespace, deployment)
