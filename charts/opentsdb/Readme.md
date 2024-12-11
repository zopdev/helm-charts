# OpenTSDB Helm Chart

The OpenTSDB Helm chart enables the deployment of OpenTSDB, a scalable time-series database, in a Kubernetes cluster. OpenTSDB is designed for large-scale data collection, storage, and analysis, providing an efficient way to handle time-series data.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+  

---

## Add Helm Repository

Add the Helm repository to your local setup:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

Refer to the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for more information.

---

## Install Helm Chart

To install the OpenTSDB Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/opentsdb
```

Replace `[RELEASE_NAME]` with your desired release name. For example:

```bash
helm install my-opentsdb zopdev/opentsdb
```

To customize configurations, provide a `values.yaml` file or override values via the command line.

Refer to [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for more details.

---

## Uninstall Helm Chart

To uninstall the OpenTSDB Helm chart and remove all associated Kubernetes resources, use the command:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-opentsdb
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

Below is a summary of configurable parameters for the OpenTSDB Helm chart:

| **Input**               | **Type**  | **Description**                                                    | **Default**                       |
|--------------------------|-----------|--------------------------------------------------------------------|-----------------------------------|
| `replicaCount`           | `integer` | Number of replicas for the OpenTSDB StatefulSet.                   | `1`                               |
| `image.opentsdb`         | `string`  | Docker image and tag for the OpenTSDB container.                   | `petergrace/opentsdb-docker:latest` |
| `image.pullPolicy`       | `string`  | Image pull policy for the OpenTSDB container.                      | `IfNotPresent`                   |
| `resources.requests.cpu` | `string`  | Minimum CPU resources required by the OpenTSDB container.          | `"100m"`                          |
| `resources.requests.memory` | `string` | Minimum memory resources required by the OpenTSDB container.       | `"256M"`                          |
| `resources.limits.cpu`   | `string`  | Maximum CPU resources the OpenTSDB container can use.              | `"1000m"`                         |
| `resources.limits.memory`| `string`  | Maximum memory resources the OpenTSDB container can use.           | `"1Gi"`                           |
| `diskSize`               | `string`  | Size of the persistent volume for OpenTSDB data storage.           | `"10Gi"`                          |
| `updateStrategy.type`    | `string`  | Update strategy for the OpenTSDB StatefulSet.                      | `RollingUpdate`                   |
| `opentsdb_port`          | `integer` | Port on which OpenTSDB listens for incoming connections.           | `4242`                            |

You can override these values in a `values.yaml` file or via the command line during installation.

---

### Example `values.yaml` File

```yaml
replicaCount: 2

image:
  opentsdb: petergrace/opentsdb-docker:latest
  pullPolicy: Always

resources:
  requests:
    cpu: "500m"
    memory: "512M"
  limits:
    cpu: "2000m"
    memory: "2Gi"

diskSize: "20Gi"

updateStrategy:
  type: RollingUpdate

opentsdb_port: 4242
```

Apply the configuration file during installation:

```bash
helm install my-opentsdb zopdev/opentsdb -f values.yaml
```

---

## Features

- **Scalable Deployment:** Adjust replica count for high availability and load distribution.
- **Custom Resource Allocation:** Define resource requests and limits for CPU and memory to suit workload requirements.
- **Persistent Storage:** Ensure data persistence using configurable persistent volumes.
- **Rolling Updates:** Apply changes to the StatefulSet with zero downtime using the `RollingUpdate` strategy.

---

## Advanced Usage

### Persistent Volume Configuration

Customize the persistent volume size and storage class for OpenTSDB data:

```yaml
diskSize: "50Gi"
storageClass: "high-performance"
```

### Network Configuration

Specify the OpenTSDB port and integrate with other services:

```yaml
opentsdb_port: 8080
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