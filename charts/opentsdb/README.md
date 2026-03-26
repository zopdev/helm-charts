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

| **Input**                      | **Type**  | **Description**                                                         | **Default**    |
|--------------------------------|-----------|-------------------------------------------------------------------------|----------------|
| `version`                      | `string`  | Docker image tag for the OpenTSDB container.                            | `"v0.0.1"`     |
| `resources.requests.cpu`       | `string`  | Minimum CPU resources required by the OpenTSDB container.               | `"500m"`       |
| `resources.requests.memory`    | `string`  | Minimum memory resources required by the OpenTSDB container.            | `"1000Mi"`     |
| `resources.limits.cpu`         | `string`  | Maximum CPU resources the OpenTSDB container can use.                   | `"1000m"`      |
| `resources.limits.memory`      | `string`  | Maximum memory resources the OpenTSDB container can use.                | `"2000Mi"`     |
| `diskSize`                     | `string`  | Size of the persistent volume for OpenTSDB data storage.                | `"10Gi"`       |
| `zookeeper.replicaCount`       | `integer` | Number of replicas for the Zookeeper StatefulSet.                       | `1`            |
| `zookeeper.diskSize`           | `string`  | Size of the persistent volume for Zookeeper data storage.               | `"10Gi"`       |
| `zookeeper.resources.requests.cpu`    | `string` | Minimum CPU resources required by the Zookeeper container.       | `"100m"`       |
| `zookeeper.resources.requests.memory` | `string` | Minimum memory resources required by the Zookeeper container.    | `"500Mi"`      |
| `zookeeper.resources.limits.cpu`      | `string` | Maximum CPU resources the Zookeeper container can use.           | `"500m"`       |
| `zookeeper.resources.limits.memory`   | `string` | Maximum memory resources the Zookeeper container can use.        | `"1000Mi"`     |

You can override these values in a `values.yaml` file or via the command line during installation.

---

### Example `values.yaml` File

```yaml
version: "v0.0.1"

resources:
  requests:
    cpu: "500m"
    memory: "1000Mi"
  limits:
    cpu: "1000m"
    memory: "2000Mi"

diskSize: "10Gi"

zookeeper:
  replicaCount: 1
  diskSize: "10Gi"
  resources:
    requests:
      cpu: "100m"
      memory: "500Mi"
    limits:
      cpu: "500m"
      memory: "1000Mi"
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
- **Bundled Zookeeper:** Includes the ZopDev Zookeeper chart as a dependency — no external Zookeeper setup required.

---

## Advanced Usage

### Persistent Volume Configuration

Customize the persistent volume size for OpenTSDB data:

```yaml
diskSize: "50Gi"
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

---

## Connection Config

- **OPENTSDB_HOST** : Hostname or service name for the OpenTSDB server.
- **OPENTSDB_PORT** : Port number to connect to OpenTSDB. Defaults at 4242.

---