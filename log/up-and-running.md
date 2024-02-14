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
