# Cassandra Helm Chart

The Cassandra Helm chart provides an easy way to deploy Apache Cassandra, a highly scalable and distributed NoSQL database. This chart allows you to manage Cassandra instances on Kubernetes with customizable resource allocation, persistence, and scaling options.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+

---

## Add Helm Repository

Before deploying the Cassandra chart, add the Helm repository to your local setup:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

For more details, refer to the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/).

---

## Install Helm Chart

To install the Cassandra Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/cassandra
```

Replace `[RELEASE_NAME]` with your desired release name. For example:

```bash
helm install my-cassandra zopdev/cassandra
```

To customize configurations, provide a `values.yaml` file or override values via the command line.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for more information.

---

## Uninstall Helm Chart

To remove the Cassandra deployment and all associated Kubernetes resources, use the following command:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-cassandra
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

The Cassandra Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

| **Input**                   | **Type** | **Description**                                               | **Default**                            |
|-----------------------------|----------|---------------------------------------------------------------|----------------------------------------|
| `image`                     | `string` | Docker image and tag for the Cassandra container.             | "bitnami/cassandra:5.0.2-debian-12-r3" |
| `resources.requests.memory` | `string` | Minimum memory resources required by the Cassandra container. | `"2000Mi"`                             |
| `resources.requests.cpu`    | `string` | Minimum CPU resources required by the Cassandra container.    | `"500m"`                               |
| `resources.limits.memory`   | `string` | Maximum memory resources the Cassandra container can use.     | `"4000Mi"`                             |
| `resources.limits.cpu`      | `string` | Maximum CPU resources the Cassandra container can use.        | `"1000m"`                              |

You can override these values in a `values.yaml` file or via the command line during installation.

---

### Example `values.yaml` File

```yaml
image: bitnami/cassandra:5.0.2-debian-12-r3
  
resources:
  requests:
    memory: "2000Mi"
    cpu: "500m"
  limits:
    memory: "4000Mi"
    cpu: "1000m"

diskSize: 10Gi
```

To use this configuration, save it to a `values.yaml` file and apply it during installation:

```bash
helm install my-cassandra zopdev/cassandra -f values.yaml
```

---

## Features

- **Scalable Architecture:** Configure resources and scaling options to optimize performance for distributed database workloads.
- **Persistent Storage:** Keep Cassandra data intact across pod restarts with configurable persistent volumes.
- **Customizable Resource Allocation:** Tailor CPU and memory resources to match workload requirements.
- **Multi-Database Support:** Configure multiple database services through the services configuration.
- **Easy Deployment:** Simplified Helm chart for rapid deployment of Cassandra in Kubernetes environments.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 