# OSAI Kube

The purpose of this repo is run open source AI apps within an auto-scaling Kubernetes cluster, spinning up and down GPU instances as needed to avoid unnecessary costs.

# Setup

## Install `google-cloud-sdk`

Install `gcloud` following the [installation instructions](https://cloud.google.com/sdk/docs/install-sdk).

On arch-linux, AUR packages are available:

```sh
trizen -S aur/google-cloud-cli aur/google-cloud-cli-gke-gcloud-auth-plugin
```

## Setup `gcloud`

```sh 
gcloud auth login
gcloud config set project $GCP_PROJECT
```

Replace `$GCP_PROJECT` with the name of your project.

## Set up a basic kubernetes cluster on GCP.

## Build and run the supervisor

Follow the instructions in [`supervisor/README.md`](./supervisor/README.md).




