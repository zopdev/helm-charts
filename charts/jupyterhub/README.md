# JupyterHub Helm Chart

This Helm chart deploys JupyterHub on Kubernetes, providing a multi-user server for Jupyter notebooks. JupyterHub allows multiple users to access their own Jupyter notebook servers in a shared environment, making it ideal for educational institutions, research labs, and data science teams.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Storage class for persistent volumes (if using dynamic storage)

---

## Add Helm Repository

Add the Helm repository by running:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

For more details, see the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/).

---

## Install Helm Chart

To deploy the JupyterHub Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/jupyterhub
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-jupyterhub zopdev/jupyterhub
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the JupyterHub Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-jupyterhub
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The JupyterHub Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

### Hub Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `hub.config.JupyterHub.admin_access` | `boolean` | Whether to allow admin access.                                                      | `true`               |
| `hub.config.JupyterHub.authenticator_class` | `string` | Authentication class to use.                                                | `"dummy"`            |
| `hub.baseUrl`               | `string`  | Base URL for the JupyterHub instance.                                                        | `"/"`                |

### Proxy Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `proxy.https.enabled`        | `boolean` | Whether to enable HTTPS.                                                                       | `false`              |
| `proxy.https.type`           | `string`  | Type of HTTPS configuration (letsencrypt).                                                    | `"letsencrypt"`      |
| `proxy.https.letsencrypt.contactEmail` | `string` | Contact email for Let's Encrypt.                                          | `""`                 |
| `proxy.https.letsencrypt.acmeServer` | `string` | ACME server URL for Let's Encrypt.                                        | `"https://acme-v02.api.letsencrypt.org/directory"` |

### Single User Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `singleuser.image.name`      | `string`  | Docker image for single-user servers.                                                         | `"quay.io/jupyterhub/k8s-singleuser-sample"` |
| `singleuser.image.tag`       | `string`  | Tag for the single-user server image.                                                         | `"4.1.1-0.dev.git.6957.h0e735928"` |
| `singleuser.storage.type`    | `string`  | Type of storage to use (dynamic/static).                                                      | `"dynamic"`          |
| `singleuser.storage.capacity`| `string`  | Storage capacity for user volumes.                                                            | `"10Gi"`             |
| `singleuser.storage.homeMountPath` | `string` | Path to mount user home directory.                                                    | `"/home/jovyan"`     |

### Scheduling Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `scheduling.userScheduler.enabled` | `boolean` | Whether to enable user scheduler.                                                    | `true`               |
| `scheduling.userScheduler.replicas` | `integer` | Number of scheduler replicas.                                                      | `2`                  |
| `scheduling.userScheduler.logLevel` | `integer` | Log level for the scheduler.                                                         | `4`                  |

### Culling Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `cull.enabled`               | `boolean` | Whether to enable culling of inactive servers.                                                | `true`               |
| `cull.timeout`               | `integer` | Time in seconds before culling inactive servers.                                              | `3600`               |
| `cull.every`                 | `integer` | How often to check for culling in seconds.                                                    | `600`                |

---

## Example `values.yaml`

```yaml
hub:
  config:
    JupyterHub:
      admin_access: true
      authenticator_class: dummy
  baseUrl: /

proxy:
  https:
    enabled: false
    type: letsencrypt
    letsencrypt:
      contactEmail: admin@example.com
      acmeServer: https://acme-v02.api.letsencrypt.org/directory

singleuser:
  image:
    name: quay.io/jupyterhub/k8s-singleuser-sample
    tag: "4.1.1-0.dev.git.6957.h0e735928"
  storage:
    type: dynamic
    capacity: 10Gi
    homeMountPath: /home/jovyan

scheduling:
  userScheduler:
    enabled: true
    replicas: 2
    logLevel: 4

cull:
  enabled: true
  timeout: 3600
  every: 600
```

---

## Features

- Multi-user Jupyter notebook server deployment
- Configurable authentication system
- HTTPS support with Let's Encrypt integration
- Persistent storage for user data
- Automatic culling of inactive servers
- Network policies for security
- Customizable resource limits
- User scheduling capabilities
- Pre-pulling of container images
- Cloud metadata blocking for security

---

## Architecture

The JupyterHub deployment includes:
- Hub pod for user authentication and management
- Proxy pod for routing requests
- Single-user server pods for each user
- Persistent volume claims for user data
- Network policies for security
- User scheduler for pod placement
- Image pre-puller for faster startup
- Culling service for resource management

---

## Security Features

- Network policies to control pod communication
- Cloud metadata blocking
- Configurable authentication system
- HTTPS support
- Privilege escalation prevention
- User isolation through separate pods
- Configurable security contexts

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 