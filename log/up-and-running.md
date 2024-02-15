# Up and Running

This is a log of the steps I took to get `osai-kube` running in a fresh GCP project.

I created a GCP project and enabled:
- compute.googleapis.com
- networkservices.googleapis.com
- container.googleapis.com

I created a service account with:
- Artifact Registry Administrator
- Kubernetes Engine Admin
- Compute Admin
- Compute Network Admin
- Cloud SQL Admin
- Cloud Resource Manager API

I created a key for this service account and saved it to my computer.

I created a repository in artifact registry.

I created a VPC network.

I created a GKE cluster.

I set up a `gcloud` profile for this project.

```sh
gcloud config configurations create osai-kube1
gcloud config configurations activate osai-kube1
```

I set up my config file.

```sh
cp ./etc/example/config.ini ./etc/live/config.ini
```

I ran `./scripts/status.sh`:

```sh
16:52:07 in ~/src/osai-kube on  main took 12s
➜ ./scripts/status.sh
[osai-kube] [INFO]  Checking configuration.
[osai-kube] [OK]    Service account key file: /home/john/src/osai-kube/etc/live/moz-fx-dev-jshaughnessy-osai1-23b8d0adb1f3.json
[osai-kube] [OK]    Service account activated: osai-kube-1@moz-fx-dev-jshaughnessy-osai1.iam.gserviceaccount.com
[osai-kube] [OK]    The service account can list clusters.
[osai-kube] [OK]    GCP project: moz-fx-dev-jshaughnessy-osai1
Context "gke_moz-fx-dev-jshaughnessy-osai1_us-central1-c_cluster-1" modified.
[osai-kube] [OK]    Kubernetes context: gke_moz-fx-dev-jshaughnessy-osai1_us-central1-c_cluster-1
[osai-kube] [OK]    Artifact registry: us-central1-docker.pkg.dev/moz-fx-dev-jshaughnessy-osai1/af-1
[osai-kube] [INFO]  Checking status of live cluster.
[osai-kube] [INFO]  Listing node pools

NAME          MACHINE_TYPE  DISK_SIZE_GB  NODE_VERSION
default-pool  e2-medium     100           1.27.8-gke.1067004

[osai-kube] [INFO]  kubectl get nodes,pods,deployments,services

NAME                                            STATUS   ROLES    AGE   VERSION
node/gke-cluster-1-default-pool-5c3108a5-3lhd   Ready    <none>   33m   v1.27.8-gke.1067004
node/gke-cluster-1-default-pool-5c3108a5-4bd6   Ready    <none>   33m   v1.27.8-gke.1067004
node/gke-cluster-1-default-pool-5c3108a5-xhxj   Ready    <none>   32m   v1.27.8-gke.1067004

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.8.0.1     <none>        443/TCP   34m

[osai-kube] [INFO]  Checking artifact registry.
IMAGE  TAG  DIGEST  TIMESTAMP
```

I installed docker build kit.

```
trizen -S docker-buildx
```

I ran `./scripts/docker_build_images.sh`

```sh
➜ ./scripts/build_docker_images.sh
[osai-kube] [INFO]  Building the supervisor image.
[+] Building 19.9s (14/14) FINISHED                                                                                      docker:default
 => [internal] load build definition from Dockerfile.supervisor                                                                    0.0s
 => => transferring dockerfile: 718B                                                                                               0.0s
 => [internal] load metadata for docker.io/library/python:3.9-slim                                                                 0.7s
 => [auth] library/python:pull token for registry-1.docker.io                                                                      0.0s
 => [internal] load .dockerignore                                                                                                  0.0s
 => => transferring context: 2B                                                                                                    0.0s
 => [1/8] FROM docker.io/library/python:3.9-slim@sha256:e0bc011bb55918109921b913fe30160cb8297c570621a450477d44999a792beb           3.7s
 => => resolve docker.io/library/python:3.9-slim@sha256:e0bc011bb55918109921b913fe30160cb8297c570621a450477d44999a792beb           0.0s
 => => sha256:9c14a9ca10408336092a7089469ef9a84f3caf196f7f65c512677e1f06e5d839 6.92kB / 6.92kB                                     0.0s
 => => sha256:e1caac4eb9d2ec24aa3618e5992208321a92492aef5fef5eb9e470895f771c56 29.12MB / 29.12MB                                   0.9s
 => => sha256:51d1f07906b71fd60ac43c61035514996a8ad8dbfd39d4f570ac5446b064ee5d 3.51MB / 3.51MB                                     0.4s
 => => sha256:336c7f590cb97722bfee12f22e354df879feae9f28bfd5cebeaffccb3fb8fbf5 11.89MB / 11.89MB                                   0.6s
 => => sha256:e0bc011bb55918109921b913fe30160cb8297c570621a450477d44999a792beb 1.86kB / 1.86kB                                     0.0s
 => => sha256:51c781cd11dd1f2a95e2bef833a5920042743fa502d66c9e12c1a841d983f9a7 1.37kB / 1.37kB                                     0.0s
 => => sha256:93b25b5c998e137849343851763bbc686f369399894e766c37a55304b1f66cfb 244B / 244B                                         0.5s
 => => sha256:2b527dfdb0a9ecb9a5bf5c264aeb4ac254e0752886f187095f6960b933aab941 3.13MB / 3.13MB                                     0.6s
 => => extracting sha256:e1caac4eb9d2ec24aa3618e5992208321a92492aef5fef5eb9e470895f771c56                                          1.6s
 => => extracting sha256:51d1f07906b71fd60ac43c61035514996a8ad8dbfd39d4f570ac5446b064ee5d                                          0.2s
 => => extracting sha256:336c7f590cb97722bfee12f22e354df879feae9f28bfd5cebeaffccb3fb8fbf5                                          0.6s
 => => extracting sha256:93b25b5c998e137849343851763bbc686f369399894e766c37a55304b1f66cfb                                          0.0s
 => => extracting sha256:2b527dfdb0a9ecb9a5bf5c264aeb4ac254e0752886f187095f6960b933aab941                                          0.3s
 => [internal] load build context                                                                                                  0.0s
 => => transferring context: 15.21kB                                                                                               0.0s
 => [2/8] WORKDIR /usr/src/app                                                                                                     0.0s
 => [3/8] RUN pip install --upgrade pip                                                                                            2.6s
 => [4/8] RUN mkdir -p server                                                                                                      0.4s
 => [5/8] COPY server/requirements.txt server/                                                                                     0.0s
 => [6/8] RUN pip install --no-cache-dir -r server/requirements.txt                                                                7.5s
 => [7/8] RUN apt-get update && apt-get install -y vim                                                                             4.3s
 => [8/8] COPY . .                                                                                                                 0.1s
 => exporting to image                                                                                                             0.5s
 => => exporting layers                                                                                                            0.5s
 => => writing image sha256:07d0d798dbac0a4007268ac289e4d8bfd496bf374fbf8aa388bc019711444121                                       0.0s
 => => naming to us-central1-docker.pkg.dev/moz-fx-dev-jshaughnessy-osai1/af-1/osai-kube/supervisor:latest                         0.0s
[osai-kube] [OK]    Successfully built the supervisor image.
```

I ran `./scripts/push_docker_images.sh`

```sh
17:08:39 in ~/src/osai-kube on  main
➜ ./scripts/push_docker_images.sh
Activated service account credentials for: [osai-kube-1@moz-fx-dev-jshaughnessy-osai1.iam.gserviceaccount.com]
[osai-kube] [INFO]   Uploading supervisor image to artifact registry.
The push refers to repository [us-central1-docker.pkg.dev/moz-fx-dev-jshaughnessy-osai1/af-1/osai-kube/supervisor]
0f8d33dd7243: Pushed
46fabd5ed495: Pushed
33e8955054eb: Pushed
dbfe1df13d6d: Pushed
c4b8a69e8321: Pushed
ac85581ace0d: Pushed
3116d6bb7e34: Pushed
7ce4521e7cb2: Pushed
619b503a99a8: Pushed
defa49bf7f54: Pushed
ba473bfdf54e: Pushed
ceb365432eec: Pushed

latest: digest: sha256:f792fe5e97706d8358435dd855884442a2396ab247f7f81e730659ea3da3c1ae size: 2834
[osai-kube] [OK]    Uploaded supervisor image to artifact registry.
```

I copied `./kubernetes-manifests/examples-secrets/*` to `./kubernetes-manifests/secrets/` and configured each secret. I made sure to base64 encode each secret. (Not for security: base64 isn't encryption. Just to make sure the secrets are in the right format for kubernetes.)


I ran `./scripts/deploy.sh`

```sh
17:20:27 in ~/src/osai-kube on  main
➜ ./scripts/deploy.sh
[osai-kube] [UPDATED]    Updated osai-kube/supervisor in deployments/supervisor-deployment.yaml to sha256:f792fe5e97706d8358435dd855884442a2396ab247f7f81e730659ea3da3c1ae.
[osai-kube] [UPDATED]    Updated browserlab/doodle in deployments/doodle-deployment.yaml to null.
[osai-kube] [INFO]       Applying namespace configurations...
[osai-kube] [CREATED]    Applied namespaces/namespace-osai-kube.yaml
[osai-kube] [INFO]       Applying CRDs...
[osai-kube] [CREATED]    Applied crds/traefik.apiextensions.k8s.io.v1.yaml
[osai-kube] [INFO]       Applying ConfigMaps...
[osai-kube] [CREATED]    Applied config-maps/pg-hba-config-map.yaml
[osai-kube] [CREATED]    Applied config-maps/registry-config.yaml
[osai-kube] [CREATED]    Applied config-maps/init-db-users-config-map.yaml
[osai-kube] [INFO]       Applying Secrets...
Secret manifest created: ./scripts/../kubernetes-manifests/secrets/gatekeeper-doodle-secret.yaml
[osai-kube] [INFO]       Rewrote gatekeeper-doodle-secret.yaml. (Not necessarily changed.)
[osai-kube] [CREATED]    Applied secrets/keycloak-secret.decode.yaml
[osai-kube] [CREATED]    Applied secrets/postgresql-admin-secret.yaml
[osai-kube] [CREATED]    Applied secrets/postgresql-keycloak-secret.yaml
[osai-kube] [UNCHANGED]  Applied secrets/keycloak-secret.yaml
[osai-kube] [CREATED]    Applied secrets/postgresql-storage-gateway-secret.yaml
[osai-kube] [CREATED]    Applied secrets/gatekeeper-doodle-secret.yaml
[osai-kube] [INFO]       Applying RBAC configurations...
[osai-kube] [CREATED]    Applied roles/rolebinding.yaml
[osai-kube] [CREATED]    Applied roles/clusterrole.yaml
[osai-kube] [CREATED]    Applied roles/role.yaml
[osai-kube] [CREATED]    Applied roles/deployment-manager-role-binding.yaml
[osai-kube] [CREATED]    Applied roles/00-traefik-cluster-role.yaml
[osai-kube] [CREATED]    Applied roles/01-traefik-cluster-role-binding.yaml
[osai-kube] [CREATED]    Applied roles/clusterrolebinding.yaml
[osai-kube] [CREATED]    Applied roles/deployment-manager-role.yaml
[osai-kube] [INFO]       Applying Service Accounts...
[osai-kube] [CREATED]    Applied service-accounts/00-traefik-service-account.yaml
[osai-kube] [INFO]       Applying Persistent Volume Claims...
[osai-kube] [CREATED]    Applied pvcs/traefik-acme-storage.yaml
[osai-kube] [INFO]       Applying Middleware configurations...
[osai-kube] [CREATED]    Applied middleware/traefik-middleware.yaml
[osai-kube] [INFO]       Applying Service configurations...
[osai-kube] [CREATED]    Applied services/supervisor-service.yaml
[osai-kube] [CREATED]    Applied services/02-traefik-dashboard-service.yaml
[osai-kube] [CREATED]    Applied services/doodle-service.yaml
[osai-kube] [CREATED]    Applied services/03-whoami.yaml
[osai-kube] [CREATED]    Applied services/keycloak-service.yaml
[osai-kube] [CREATED]    Applied services/postgresql-service.yaml
[osai-kube] [CREATED]    Applied services/02-traefik-web-service.yaml
[osai-kube] [INFO]       Applying StatefulSets...
[osai-kube] [CREATED]    Applied stateful-sets/postgresql-stateful-set.yaml
[osai-kube] [INFO]       Applying Deployments...
[osai-kube] [CREATED]    Applied deployments/keycloak-deployment.yaml
[osai-kube] [CREATED]    Applied deployments/doodle-deployment.yaml
[osai-kube] [CREATED]    Applied deployments/02-traefik-deployment.yaml
[osai-kube] [CREATED]    Applied deployments/supervisor-deployment.yaml
[osai-kube] [INFO]       Applying DaemonSets...
[osai-kube] [CREATED]    Applied daemonsets/nvidia-daemonset-preloaded.yaml
[osai-kube] [INFO]       Applying Ingress configurations...
[osai-kube] [CREATED]    Applied ingress/doodle-ingress.yaml
[osai-kube] [CREATED]    Applied ingress/04-whoami-ingress.yaml
[osai-kube] [CREATED]    Applied ingress/supervisor-ingress-https.yaml
[osai-kube] [CREATED]    Applied ingress/keycloak-ingress.yaml
[osai-kube] [INFO]       All configurations have been applied.
```

I set the `osai-kube` namespace as the default namespace for `kubectl`.

```sh
kubectl config set-context --current --namespace=osai-kube
```




