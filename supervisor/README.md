# `osai-kube/supervisor`

A python (Flask) web server that allows clients to query and change the kubernetes cluster.

## Setup

Install `kubectl`, `docker`, `gcloud`.

Update the configuration file `./config.ini`.

Update the registry config map: `registry-config.ini`.

Log in to `gcloud`: `glcoud auth login`.

Perform one-time docker configuration:
```sh
gcloud auth configure-docker us-central1-docker.pkg.dev
```
(Replace `us-central1-docker.pkg.dev` with your artifact registry location)

Build and upload the docker image with `./build_and_upload.sh`.

Update the cluster with `./update_k8s_deployment.sh`. In addition to running the container, the script will also:

- Apply the ConfigMap: `kubectl apply -f registry-config.yaml`
- Apply the deployment: `kubectl apply -f supervisor-deployment.yaml`
- Apply the service: `kubectl apply -f supervisor-service.yaml`

## Update

Build and upload the docker image with `./build_and_upload.sh`.

Update the live deployment with `./update_k8s_deployment.sh`.

## Run

Set up port forward to the supervisor-service namespace.
``` sh
kubectl port-forward service/supervisor-service 8081:80 --namespace=osai-kub
```



