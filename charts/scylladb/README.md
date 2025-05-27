# ScyllaDB Helm Chart

This Helm chart deploys a ScyllaDB cluster on Kubernetes with high performance and scalability. ScyllaDB is a highly-performant NoSQL database compatible with Apache Cassandra, designed for high throughput and low latency.

---

## Prerequisites
- Kubernetes 1.19+
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

To deploy the ScyllaDB Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/scylladb
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-scylladb zopdev/scylladb
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the ScyllaDB Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-scylladb
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The ScyllaDB Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

| **Input**               | **Type**  | **Description**                                                                                | **Default**           |
|--------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `image`                  | `string`  | Docker image and tag for the ScyllaDB container.                                               | `scylladb/scylla:latest` |
| `pullPolicy`            | `string`  | Image pull policy for the ScyllaDB container.                                                  | `IfNotPresent`       |
| `config.cluster_name`   | `string`  | Name of the ScyllaDB cluster.                                                                  | `"Cluster"`          |
| `resources.requests.memory` | `string` | Minimum memory resources required by the ScyllaDB container.                                   | `"1Gi"`              |
| `resources.requests.cpu` | `string` | Minimum CPU resources required by the ScyllaDB container.                                      | `"500m"`             |
| `resources.limits.memory` | `string` | Maximum memory resources the ScyllaDB container can use.                                       | `"2Gi"`              |
| `resources.limits.cpu`   | `string`  | Maximum CPU resources the ScyllaDB container can use.                                          | `"1000m"`            |
| `diskSize`               | `string`  | Size of the persistent volume for storing ScyllaDB data.                                       | `"10Gi"`             |
| `scylladbRootPassword`   | `string`  | Root password for ScyllaDB authentication.                                                     | `""` (auto-generated)|

You can override these values in a `values.yaml` file or via the command line during installation.

---

## Example `values.yaml`

```yaml
image: "scylladb/scylla:latest"
pullPolicy: IfNotPresent

resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

diskSize: "10Gi"

config:
  cluster_name: "MyCluster"

scylladbRootPassword: "my-secure-password"

services:
```

---

## Features
- Deploy ScyllaDB cluster with high performance and scalability.
- Automatic system tuning for optimal performance.
- Built-in authentication and authorization.
- Persistent storage with configurable disk size.
- Health monitoring with liveness and readiness probes.
- Prometheus metrics integration for monitoring.
- Automatic seed node configuration for cluster formation.
- Configurable resource limits and requests.

---

## Architecture

The ScyllaDB deployment includes:
- StatefulSet for stable network identities and persistent storage
- Service for cluster communication
- ConfigMap for ScyllaDB configuration
- Secret for secure password storage
- Init container for system tuning
- Health checks for monitoring

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.