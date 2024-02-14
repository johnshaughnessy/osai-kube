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


