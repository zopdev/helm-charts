# SurrealDB Helm Chart

The SurrealDB Helm chart provides an easy way to deploy **SurrealDB**, a next-generation database for modern applications, in your Kubernetes cluster. SurrealDB supports SQL-like queries and is highly flexible, scalable, and efficient.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+  

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

To deploy the SurrealDB Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/surrealdb
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-surrealdb zopdev/surrealdb
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the SurrealDB Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-surrealdb
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The following table lists the configurable parameters of the SurrealDB Helm chart:

| **Input**                | **Type**  | **Description**                                                    | **Default**            |
|---------------------------|-----------|--------------------------------------------------------------------|------------------------|
| `replicaCount`           | `integer` | Number of SurrealDB replicas to deploy.                            | `1`                    |
| `image`                  | `string`  | Docker image and tag for the SurrealDB container.                  | `"surrealdb/surrealdb:latest"` |
| `resources.requests.cpu`  | `string`  | Minimum CPU resources required by the SurrealDB container.         | `"100m"`               |
| `resources.requests.memory`| `string` | Minimum memory resources required by the SurrealDB container.      | `"256M"`               |
| `resources.limits.cpu`    | `string`  | Maximum CPU resources the SurrealDB container can use.             | `"1000m"`              |
| `resources.limits.memory` | `string`  | Maximum memory resources the SurrealDB container can use.          | `"1Gi"`                |
| `diskSize`               | `string`  | Size of the persistent volume for SurrealDB data storage.          | `"10Gi"`               |
| `updateStrategy.type`    | `string`  | Update strategy for rolling updates.                               | `"RollingUpdate"`      |
| `port`                   | `integer` | Port on which SurrealDB listens for incoming connections.           | `8000`                 |

Override these values in a `values.yaml` file or via command-line arguments during installation.

---

### Example `values.yaml` File

Below is an example configuration for custom installation:

```yaml
replicaCount: 2

image: surrealdb/surrealdb:latest

resources:
  requests:
    cpu: "200m"
    memory: "512M"
  limits:
    cpu: "2"
    memory: "2Gi"

diskSize: "20Gi"

updateStrategy:
  type: RollingUpdate

port: 8080
```

Use the custom configuration with the following command:

```bash
helm install my-surrealdb zopdev/surrealdb -f values.yaml
```

---

## Features

- **Scalability:** Supports horizontal scaling with replica configuration.  
- **Resource Control:** Fine-grained control over resource limits and requests for optimized performance.  
- **Persistent Storage:** Configurable disk size to ensure data durability.  
- **Rolling Updates:** Seamless updates with no downtime using the rolling update strategy.  
- **Flexible Port Configuration:** Easily specify the port for database connections.  

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.