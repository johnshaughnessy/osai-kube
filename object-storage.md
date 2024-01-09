# Object Storage

The web apps running in the osai-kube cluster need a way to save objects that will be generally available across the services/apps in the cluster. If a user generates an image with one app, she should be able to use it in another. This enables a "collection of tools" to be deployed in the cluster with a coherent view of user data.

When a user generates an image, it should only be accessed by that user or by other users with appropriate permissions. For example, if the image is added to a project, other users with access to that project should be able to read/write it.

Generically, we'll call the files we are saving "objects", because this is the terminology used by GCP (and other cloud providers) for their storage services. We will use Google Cloud Storage (GCS) as our underlying object storage.

This gives us a few "layers" for managing access:

- `keycloak` and `keycloak-gatekeeper` provide authenticated identity and roles for each individual user. This will be a major component of our access control strategy.
- Kubernetes service accounts manage access specifically to resources within the cluster. This won't be relevant for this task.
- GCP service accounts and IAM manages access to GCS resources. Whatever wants to access the objects directly will need the appropriate permissions assigned to their GCP service account / identity.

Unfortunately, these layers are not enough. We want each user to have their own personal bucket, but also to be able to dynamically create buckets for projects:

- We could attempt to achieve this using roles and groups in `keycloak`, but this would lead to an explosion of roles, and would make managing other, more basic roles hard to manage.
- Kubernetes service accounts don't help here, because the issue is not about managing kubernetes resources.
- We do not want to create GCP service accounts or identities for each end user and manage their permissions dynamically. This would lead to an explosion of service accounts / identities, would make our GCP project harder to manage, and would even further tie us to one specific cloud provider. (While it's not our goal to be cloud agnostic, we do not want to make it unnecessarily difficult to migrate to another cloud like Azure, AWS, Digital Ocean, etc.)

We will build a new application to add to our cluster. This new application will be a web server that manages authorized access to the GCS storage. Other applications in the cluster will interact with storage through this application. Authentication and high-level authorization will still be managed by keycloak and keycloak-gateway, but fine-grained access control to individual GCS resources will be managed by this application's (postgresql) database.

I will need to:

- Create a docker image with rust and other prerequisites installed.
- Write a web server that uses actix_web for handling http requests, diesel for handling postgresql data, and cloud-storage for handling objects stored in gcp.
- Create a general ops flow for building and deploying this web app as a docker image to artifact registry
- Create a general ops flow for migrating the database, doing backup, etc.
- Create the required kubernetes manifests for deploying the web app to my cluster.
- Configure keycloak to treat my web app as another openid connect client. Run gatekeeper as a sidecar to my web app.
- From within the web app, fetch information like the user id in order to authorize requests to objects in the GCS buckets.

I can use the [track app](https://github.com/johnshaughnessy/track/wiki) as inspiration. It implements several of the items above without very much additional cruft. Obviously the specific migrations, APIs, and code in the project is not quite correct, but generally speaking it is a similar kind of application.

This step seems like it may be significantly more difficult / time consuming than setting up other parts of osai-kube, but having shared object storage seems like a good (and necessary) thing.
