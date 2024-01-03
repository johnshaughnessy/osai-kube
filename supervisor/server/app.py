from flask import Flask, request, jsonify, make_response, send_from_directory
from flask_jwt_extended import JWTManager, jwt_required, create_access_token
import datetime
import os
import kube_utils
import gcp_utils

app = Flask(__name__, static_folder='../client')

# Configure JWT
app.config['JWT_SECRET_KEY'] = 'your_jwt_secret'  # Change this to a random secret key
jwt = JWTManager(app)

@app.route('/login', methods=['POST'])
def login():
    username = request.json.get('username', None)
    password = request.json.get('password', None)

    # Replace with your authentication logic
    if username != 'admin' or password != 'password':
        return jsonify({"msg": "Bad username or password"}), 401

    expires = datetime.timedelta(hours=1)
    access_token = create_access_token(identity=username, expires_delta=expires)
    return jsonify(access_token=access_token), 200

@app.route('/cluster-info', methods=['GET'])
@jwt_required()
def get_cluster_info():
    node_info = kube_utils.get_cluster_info()
    return jsonify(node_info)

@app.route('/doodle-control', methods=['POST'])
@jwt_required()
def doodle_control():
    action = request.json.get('action', None)
    config_data = gcp_utils.load_doodle_config()

    if action == 'start':
        kube_utils.update_deployment_replicas('doodle-deployment', 1, 'default-namespace')
        gcp_utils.create_gpu_node_pool(config_data)
    elif action == 'stop':
        kube_utils.update_deployment_replicas('doodle-deployment', 0, 'default-namespace')
        gcp_utils.delete_gpu_node_pool(config_data)
    else:
        return jsonify({"msg": "Invalid action"}), 400
    return jsonify({"message": f"Doodle {action}ed"}), 200

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"msg": "Server is running"}), 200

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve(path):
    if path != "" and os.path.exists(app.static_folder + '/' + path):
        return send_from_directory(app.static_folder, path)
    else:
        return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
