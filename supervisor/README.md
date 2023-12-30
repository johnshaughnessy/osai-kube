# `osai-kube/supervisor`

A python (Flask) web server that allows clients to query and change the kubernetes cluster.

## Instructions

Install `kubectl`, `docker`, `gcloud`.

Update the configuration file `./config.ini`.

Update the registry config map: `registry-config.ini`.

Apply the ConfigMap: `kubectl apply -f registry-config.yaml`

Perform one-time docker configuration (Replace `us-central1-docker.pkg.dev` with your artifact registry location):

```sh
gcloud auth configure-docker us-central1-docker.pkg.dev
```

Build and upload the docker image with `./build_and_upload.sh`.

Apply the deployment (first time only): `kubectl apply -f supervisor-deployment.yaml`

Run/replace the live deployment with `./update_k8s_deployment.sh`.
