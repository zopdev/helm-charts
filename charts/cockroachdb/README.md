# CockroachDB Helm Chart

The CockroachDB Helm chart provides an easy way to deploy CockroachDB, a distributed SQL database built on a transactional and strongly-consistent key-value store. This chart allows you to manage CockroachDB instances on Kubernetes with customizable resource allocation, persistence, and scaling options.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+

---

## Add Helm Repository

Before deploying the CockroachDB chart, add the Helm repository to your local setup:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

For more details, refer to the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/).

---

## Install Helm Chart

To install the CockroachDB Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/cockroachdb
```

Replace `[RELEASE_NAME]` with your desired release name. For example:

```bash
helm install my-cockroachdb zopdev/cockroachdb
```

To customize configurations, provide a `values.yaml` file or override values via the command line.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for more information.

---

## Uninstall Helm Chart

To remove the CockroachDB deployment and all associated Kubernetes resources, use the following command:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-cockroachdb
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

The CockroachDB Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

| **Input**                   | **Type** | **Description**                                                 | **Default**                     |
|-----------------------------|----------|-----------------------------------------------------------------|---------------------------------|
| `image`                     | `string` | Docker image and tag for the Cassandra container.               | `cockroachdb/cockroach:v25.1.2` |
| `resources.requests.memory` | `string` | Minimum memory resources required by the CockroachDB container. | `"512Mi"`                       |
| `resources.requests.cpu`    | `string` | Minimum CPU resources required by the CockroachDB container.    | `"100m"`                        |
| `resources.limits.memory`   | `string` | Maximum memory resources the CockroachDB container can use.     | `"512Mi"`                       |
| `resources.limits.cpu`      | `string` | Maximum CPU resources the CockroachDB container can use.        | `"100m"`                        |
| `diskSize`                  | `string` | Size of the persistent volume for storing CockroachDB data.     | `"10Gi"`                        |

You can override these values in a `values.yaml` file or via the command line during installation.

---

### Example `values.yaml` File

```yaml
image: cockroachdb/cockroach:v25.1.2

resources:
  requests:
    memory: "512Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "100m"

diskSize: 10Gi
```

To use this configuration, save it to a `values.yaml` file and apply it during installation:

```bash
helm install my-cockroachdb zopdev/cockroachdb -f values.yaml
```

---

## Features

- **Distributed SQL Database:** Deploy a scalable, distributed SQL database with strong consistency guarantees.
- **Persistent Storage:** Keep CockroachDB data intact across pod restarts with configurable persistent volumes.
- **Customizable Resource Allocation:** Tailor CPU and memory resources to match workload requirements.
- **Version Control:** Specify the CockroachDB version to deploy.
- **Multi-Database Support:** Configure multiple database services through the services configuration.
- **Easy Deployment:** Simplified Helm chart for rapid deployment of CockroachDB in Kubernetes environments.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.
