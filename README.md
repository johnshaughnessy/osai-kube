# OSAI Kube

Run open source AI apps in an auto-scaling Kubernetes cluster.

# About

[This blog post](https://www.johnshaughnessy.com/blog/posts/osai-kube) describes the motivation for this project. Here is a brief summary of the features, capabilities, and intended use:

- Configure and run applications with various GPU requirements.
- Auto-scale GPU nodes in app-specific node pools.
- User account authentication and authorization powered by [`keycloak`](https://github.com/keycloak/keycloak) and [`keycloak-gatekeeper`](https://github.com/oneconcern/keycloak-gatekeeper), including support for OpenID Connect, SAML, SSO, etc.
- Individual applications do not need to implement auth. (Requests are routed through gatekeepers, running as sidecar containers.)
- [Traefik](https://doc.traefik.io/traefik/) for reverse proxy and ssl termination.
- Shared object storage, so that users can bring their data to each app.

# Development Dependencies

These are the most frequently used tools in the development environment.

- `gcloud`
- `kubectl`
- `docker`

Additional dependencies will vary based on the specific apps configured to run.

# Setup

You'll need a GCP project with GKE, Object Storage, Artifact Registry.

Copy `./scripts/example-config.ini` to `./scripts/config.ini` and configure.

Copy `./kubernetes-manifests/examples-secrets/*` to `./kubernetes-manifests/secrets/` and configure each secret. Secrets must be base64 encoded. Some helpers are available in `./scripts` (e.g. `./scripts/write-gatekeeper-doodle-secret.sh`).

A step-by-step log of what I did to set things up on a fresh GCP project is in `./log/up-and-running.md`. A word of caution: As the project changes, this document will _not_ be updated.
