from flask import Flask, request, jsonify, make_response, send_from_directory
from flask_jwt_extended import JWTManager, jwt_required, create_access_token
from kubernetes import client, config
import datetime
import os
app = Flask(__name__, static_folder='client')

# Configure JWT
app.config['JWT_SECRET_KEY'] = 'your_jwt_secret'  # Change this to a random secret key
jwt = JWTManager(app)

# Load Kubernetes config
config.load_incluster_config()

@app.route('/login', methods=['POST'])
def login():
    if not request.is_json:
        return jsonify({"msg": "Missing JSON in request"}), 400

    username = request.json.get('username', None)
    password = request.json.get('password', None)

    # Validate username and password (use a proper user management system in production)
    if username != 'admin' or password != 'password':
        return jsonify({"msg": "Bad username or password"}), 401

    # Create JWT token
    expires = datetime.timedelta(hours=1)
    access_token = create_access_token(identity=username, expires_delta=expires)
    return jsonify(access_token=access_token), 200

@app.route('/cluster-info', methods=['GET'])
@jwt_required()
def get_cluster_info():
    v1 = client.CoreV1Api()
    nodes = v1.list_node()
    node_info = [{"name": node.metadata.name, "labels": node.metadata.labels} for node in nodes.items]
    return jsonify(node_info)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({ "msg": "Server is running"}), 200

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve(path):
    if path != "" and os.path.exists(app.static_folder + '/' + path):
        return send_from_directory(app.static_folder, path)
    else:
        return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
