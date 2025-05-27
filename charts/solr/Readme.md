# Solr Helm Chart

The Solr Helm chart allows you to deploy Solr, an open-source enterprise search platform, in your Kubernetes cluster. Solr is highly reliable and scalable, enabling you to build search solutions for various applications.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+  

---

## Add Helm Repository

To add the Helm repository, run the following commands:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

Refer to the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for additional details.

---

## Install Helm Chart

To install the Solr Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/solr
```

Replace `[RELEASE_NAME]` with your desired release name. For example:

```bash
helm install my-solr zopdev/solr
```

For customized installation, provide a `values.yaml` file or override values during installation.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for additional details.

---

## Uninstall Helm Chart

To uninstall the Solr Helm chart and remove all associated Kubernetes resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-solr
```

Refer to [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

Below are the configurable parameters for the Solr Helm chart:

| **Input**                 | **Type**  | **Description**                                                        | **Default**      |
|----------------------------|-----------|------------------------------------------------------------------------|------------------|
| `image`                   | `string`  | Docker image and tag for the Solr container.                           | `"solr:8.4"`     |
| `resources.requests.cpu`   | `string`  | Minimum CPU resources required by the Solr container.                  | `"100m"`         |
| `resources.requests.memory`| `string`  | Minimum memory resources required by the Solr container.               | `"1Gi"`          |
| `resources.limits.cpu`     | `string`  | Maximum CPU resources the Solr container can use.                      | `"1"`            |
| `resources.limits.memory`  | `string`  | Maximum memory resources the Solr container can use.                   | `"2Gi"`          |
| `securityContext.runAsUser`| `integer` | User ID under which the Solr process runs for security.                | `1001`           |
| `securityContext.fsGroup`  | `integer` | Group ID for filesystem permissions.                                   | `1001`           |
| `tlsSecretName`            | `string`  | Name of the Kubernetes secret for TLS certificates.                    | `""`             |
| `host`                     | `string`  | Hostname for Solr's HTTP endpoint.                                      | `""`             |
| `tlsHost`                  | `string`  | Hostname for Solr's HTTPS endpoint.                                     | `""`             |
| `diskSize`                 | `string`  | Size of the persistent volume for Solr data storage.                   | `"10Gi"`         |

You can override these values in a `values.yaml` file or via the command line.

---

### Example `values.yaml` File

```yaml
version: "9.8"

resources:
  requests:
    memory: "2500Mi"
    cpu: "250m"
  limits:
    memory: "3000Mi"
    cpu: "500m"

diskSize: "10Gi"
```

Apply the configuration file during installation:

```bash
helm install my-solr zopdev/solr -f values.yaml
```

---

## Features

- **High Security:** The Helm chart allows you to configure secure environments using `securityContext` and TLS secrets.
- **Persistent Storage:** Persistent volumes ensure that Solr's data is durable across deployments.
- **Resource Control:** Customizable CPU and memory resource allocations to optimize performance.
- **Scalable Deployment:** Easily scale resources or replicas for production use.

---

## Advanced Usage

### TLS Configuration

To enable secure communication, specify a Kubernetes secret containing TLS certificates in the `tlsSecretName` field. You can also set `host` and `tlsHost` for custom endpoints.

```yaml
tlsSecretName: "solr-tls-secret"
host: "solr.example.com"
tlsHost: "secure-solr.example.com"
```

### Persistent Volume Configuration

Customize the disk size and storage class to match your requirements:

```yaml
diskSize: "50Gi"
storageClass: "fast-storage"
```

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.