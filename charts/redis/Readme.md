# Redis Helm Chart

The Redis Helm chart provides a simple and efficient way to deploy Redis instances in your Kubernetes cluster. It is optimized for scalability, persistence, and performance, making it suitable for caching, messaging, and data storage workloads.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+

---

## Add Helm Repository

Before deploying the Redis chart, add the repository to your Helm installation and update the repository index:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

See [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for more information.

---

## Install Helm Chart

To install the Redis Helm chart, execute the following command:

```bash
helm install [RELEASE_NAME] zopdev/redis
```

Replace `[RELEASE_NAME]` with the desired release name.

For example:

```bash
helm install my-redis zopdev/redis
```

To customize the deployment, use a custom `values.yaml` file or override values via command-line arguments.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To uninstall the Redis Helm chart and remove all associated Kubernetes resources, use:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-redis
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

The Redis Helm chart provides a variety of configurable parameters. The table below outlines the key configurations:

| **Input**               | **Type**  | **Description**                                                                                  | **Default**           |
|--------------------------|-----------|--------------------------------------------------------------------------------------------------|-----------------------|
| `image`                  | `string`  | Docker image and tag for the Redis container.                                                    | `redis:6.2.13`       |
| `resources.requests.cpu` | `string`  | Minimum CPU resources required by the Redis container.                                           | `"500m"`             |
| `resources.requests.memory` | `string` | Minimum memory resources required by the Redis container.                                        | `"256M"`             |
| `resources.limits.cpu`   | `string`  | Maximum CPU resources the Redis container can use.                                               | `"1500m"`            |
| `resources.limits.memory` | `string` | Maximum memory resources the Redis container can use.                                            | `"1Gi"`              |
| `diskSize`               | `string`  | Size of the persistent volume claim (PVC) for storing Redis data.                               | `"10Gi"`             |
| `updateStrategy.type`    | `string`  | Update strategy for the deployment. Options: `RollingUpdate` or `Recreate`.                     | `RollingUpdate`      |

You can override these values in a `values.yaml` file or pass them as flags during installation.

---

### Example `values.yaml` File

```yaml
diskSize: "10Gi"

version: "6.2.13"

# Resource configuration
resources:
  requests:
    cpu: "500m"
    memory: "256M"
  limits:
    cpu: "1500m"
    memory: "1Gi"
```

To use this configuration, save it in a `values.yaml` file and apply it during installation:

```bash
helm install my-redis zopdev/redis -f values.yaml
```

---

## Features

- **Persistence:** Store Redis data across pod restarts using persistent volume claims.
- **Resource Optimization:** Define resource requests and limits to suit your workload and cluster capacity.
- **Rolling Updates:** Ensure zero downtime during updates with the default `RollingUpdate` strategy.
- **Customizable Configurations:** Flexibly tailor the deployment using Helm values.

---

## Advanced Usage

### Custom Persistent Volume Configuration

You can customize the persistent volume size and storage class for Redis data by updating the `values.yaml` file:

```yaml
diskSize: "50Gi"
storageClass: "fast-storage"
```

### Scaling Redis

To scale Redis pods or create replicas, adjust the configuration to enable clustering. For example, use a stateful set for Redis replicas or Sentinel for high availability.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.