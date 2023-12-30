from flask import Flask, request, jsonify
from kubernetes import client, config

app = Flask(__name__)

# Load Kubernetes config
config.load_incluster_config()

@app.route('/cluster-info', methods=['GET'])
def get_cluster_info():
    # Basic Authentication
    auth = request.authorization
    if not auth or not (auth.username == 'admin' and auth.password == 'password'):
        return jsonify({"message": "Authentication failed"}), 401

    v1 = client.CoreV1Api()
    nodes = v1.list_node()

    node_info = [{"name": node.metadata.name, "labels": node.metadata.labels} for node in nodes.items]

    return jsonify(node_info)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
