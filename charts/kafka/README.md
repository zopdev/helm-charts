# Kafka Helm Chart

The Kafka Helm chart provides an easy way to deploy Apache Kafka, a distributed event streaming platform. This chart allows you to manage Kafka instances on Kubernetes with customizable resource allocation, persistence, and scaling options. It includes built-in monitoring with Kafka Exporter and Prometheus alerts.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+
- Prometheus Operator (for monitoring and alerts)

---

## Dependencies

Before installing the chart, you need to download the required dependencies. Run the following command in the chart directory:

```bash
helm dependency build
```

This command will:
1. Read the dependencies from `Chart.yaml`
2. Download the required charts (ZooKeeper) from the specified repositories
3. Store them in the `charts/` directory
4. Create or update the `Chart.lock` file with the exact versions

If you encounter any issues with the dependencies, you can try:
```bash
helm dependency update  # Updates dependencies to the latest versions
```

This chart requires the following dependencies to be installed:

### ZooKeeper
- **Chart**: `zookeeper`
- **Version**: `0.0.1`
- **Repository**: `https://helm.zop.dev`
- **Condition**: `zookeeper.enabled`
- **Purpose**: Provides distributed coordination and configuration management for Kafka

To install this dependency automatically, ensure the following in your `values.yaml`:

```yaml
zookeeper:
  enabled: true
  # Additional ZooKeeper configuration...
```

The dependency will be automatically installed when you deploy the Kafka chart. You can customize its configuration through the respective section in your `values.yaml` file.

---

## Add Helm Repository

Before deploying the Kafka chart, add the Helm repository to your local setup:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

For more details, refer to the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/).

---

## Install Helm Chart

To install the Kafka Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/kafka
```

Replace `[RELEASE_NAME]` with your desired release name. For example:

```bash
helm install my-kafka zopdev/kafka
```

To customize configurations, provide a `values.yaml` file or override values via the command line.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for more information.

---

## Uninstall Helm Chart

To remove the Kafka deployment and all associated Kubernetes resources, use the following command:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-kafka
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

The Kafka Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

| **Input**                   | **Type** | **Description**                                            | **Default**    |
|-----------------------------|----------|------------------------------------------------------------|----------------|
| `image`                   | `string` | Image and tag for the Kafka container.                     | `danielqsj/kafka-exporter:v1.9.0`            |
| `zookeeper.enabled`         | `boolean`| Whether to deploy ZooKeeper as part of the chart.          | `true`        |
| `zookeeper.url`            | `string` | URL of external ZooKeeper if not deploying with the chart. | `""`          |
| `resources.requests.memory` | `string` | Minimum memory resources required by the Kafka container.  | `"500Mi"`     |
| `resources.requests.cpu`    | `string` | Minimum CPU resources required by the Kafka container.     | `"500m"`      |
| `resources.limits.memory`   | `string` | Maximum memory resources the Kafka container can use.      | `"1500Mi"`    |
| `resources.limits.cpu`      | `string` | Maximum CPU resources the Kafka container can use.         | `"1000m"`     |
| `diskSize`                  | `string` | Size of the persistent volume for storing Kafka data.      | `"10Gi"`      |

### Default Kafka Configuration

The chart includes several pre-configured Kafka settings:

- Replication Factor: 3
- Number of Partitions: 3
- Min In-Sync Replicas: 2
- Log Retention: 168 hours (7 days)
- Log Segment Size: 1GB
- Message Max Bytes: ~1MB
- Auto Create Topics: Disabled
- Delete Topic: Enabled

---

### Example `values.yaml` File

```yaml
version: "7.8.0"

zookeeper:
  enabled: true
  url: ""  # Only needed if zookeeper.enabled is false

resources:
  requests:
    cpu: "500m"
    memory: "500Mi"
  limits:
    cpu: "1000m"
    memory: "1500Mi"

diskSize: 10Gi
```

To use this configuration, save it to a `values.yaml` file and apply it during installation:

```bash
helm install my-kafka zopdev/kafka -f values.yaml
```

---

## Features

- **High Availability:** Deploy a 3-node Kafka cluster with proper replication and fault tolerance.
- **Built-in Monitoring:** Includes Kafka Exporter for Prometheus metrics collection.
- **Comprehensive Alerts:** Pre-configured Prometheus alerts.
- **Security:** 
  - Read-only root filesystem
  - Non-root user execution
  - Dropped capabilities
  - Configurable security protocols
- **Resource Management:**
  - Configurable CPU and memory limits
  - Persistent volume storage
  - JVM heap optimization
- **Networking:**
  - Internal and external listeners
  - Headless service for pod discovery
  - Service monitor for Prometheus integration
- **Operational Features:**
  - Rolling updates with configurable strategy
  - Pod disruption budget
  - Parallel pod management
  - Configurable pod affinity

---

## Monitoring

The chart includes a Kafka Exporter container that exposes metrics on port 2121. These metrics are automatically collected by Prometheus when using the Prometheus Operator.

Key metrics include:
- Broker status
- Topic and partition information
- Consumer group lag
- Replication status
- JVM metrics

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 