# Dgraph Helm Chart

This Helm chart deploys a Dgraph cluster on Kubernetes, including Dgraph Zero and Dgraph Alpha components. Below is a detailed guide to the configuration options available.

---

## Prerequisites
- Kubernetes 1.18+
- Helm 3.0+

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

To deploy the dgraph Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/dgraph
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-dgraph zopdev/dgraph
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the dgraph Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-dgraph
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration
The table below outlines the essential configuration options. For a complete list, refer to the `values.yaml` file.

### Helm Chart Configuration
| Input                   | Type   | Description                             | Default         |
|-------------------------|--------|-----------------------------------------|-----------------|
| `global.image.repository`| String | The Dgraph Docker image repository.     | `dgraph/dgraph`|
| `global.image.tag`       | String | The Dgraph image tag.                   | `v23.0.0`       |
| `global.debug`           | Bool   | Enables debug logging for Dgraph.       | `false`         |
| `global.serviceAccount`  | String | Service account for Dgraph pods.        | `default`       |

---

### Zero Configuration
| Input                            | Type   | Description                                           | Default         |
|----------------------------------|--------|-------------------------------------------------------|-----------------|
| `zero.replicas`                  | Int    | Number of Dgraph Zero replicas.                      | `3`             |
| `zero.resources.requests.cpu`    | String | CPU request for Zero pods.                           | `250m`          |
| `zero.resources.requests.memory` | String | Memory request for Zero pods.                        | `512Mi`         |
| `zero.persistence.enabled`       | Bool   | Enables persistence for Zero pods.                   | `true`          |
| `zero.persistence.storageClass`  | String | Storage class for Zero persistence.                  | `""`           |
| `zero.service.type`              | String | Service type for Zero pods.                          | `ClusterIP`     |
| `zero.tls.enabled`               | Bool   | Enables TLS for Zero communication.                  | `false`         |

---

### Alpha Configuration
| Input                            | Type   | Description                                           | Default         |
|----------------------------------|--------|-------------------------------------------------------|-----------------|
| `alpha.replicas`                 | Int    | Number of Dgraph Alpha replicas.                     | `3`             |
| `alpha.resources.requests.cpu`   | String | CPU request for Alpha pods.                          | `500m`          |
| `alpha.resources.requests.memory`| String | Memory request for Alpha pods.                       | `1Gi`           |
| `alpha.persistence.enabled`      | Bool   | Enables persistence for Alpha pods.                  | `true`          |
| `alpha.persistence.storageClass` | String | Storage class for Alpha persistence.                 | `""`           |
| `alpha.acl.enabled`              | Bool   | Enables ACL for securing Alpha endpoints.            | `false`         |
| `alpha.encryption.enabled`       | Bool   | Enables encryption at rest for Alpha data.           | `false`         |
| `alpha.service.type`             | String | Service type for Alpha pods.                         | `ClusterIP`     |
| `alpha.tls.enabled`              | Bool   | Enables TLS for Alpha communication.                 | `false`         |

---

## Example `values.yaml`
```yaml
zero:
  replicas: 3
  resources:
    requests:
      cpu: 250m
      memory: 512Mi
  persistence:
    enabled: true
    storageClass: ""
  service:
    type: ClusterIP
  tls:
    enabled: false

alpha:
  replicas: 3
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
  persistence:
    enabled: true
    storageClass: ""
  acl:
    enabled: false
  encryption:
    enabled: false
  service:
    type: ClusterIP
  tls:
    enabled: false
```

---

## Features
- Simplifies Dgraph cluster deployment on Kubernetes.
- Configurable Dgraph Zero and Dgraph Alpha replicas.
- Supports TLS, encryption, and ACL for secure deployments.
- Persistent Volume support for data durability.
- Customizable resource requests and limits for scalability.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.