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

## Install docker (optionally with buildkit)

Arch Linux:
```sh
pacman -S docker docker-buildx
```

## Set up a basic kubernetes cluster on GCP.

## Configure `scripts/config.ini`

# Using the scripts

## `scripts/config.ini`

This config file must be edited before running any of the scripts.

You can also add/remove/edit the configuration for the apps you want to enable in the cluster in this file.

## `scripts/status.sh`

Use this script to validate your config file, check status of the cluster, and fetch from artifact registry.

## `scripts/logs.sh`

Use this script to fetch logs from the cluster.

## `scripts/shell.sh`

Use this script to open a shell in a pod running in the cluster.

## `scripts/build_docker_images.sh`

Builds all the docker images for the apps in the cluster.

## `scripts/push_docker_images.sh`

Pushes all the docker images for the apps in the cluster to the artifact registry.

## `scripts/set_enviroment_variables.sh`

Helper script for the other scripts. Can also be sourced in your shell to set the environment variables according to your `config.ini`.

## `scripts/deploy.sh`

Applies all of the manifests in the `kubernetes-manifests` directory to the cluster.






