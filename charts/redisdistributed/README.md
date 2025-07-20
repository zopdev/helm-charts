# Redis Distributed Helm Chart

This Helm chart deploys a Distributed Redis cluster on Kubernetes with master-slave replication, high availability, and monitoring capabilities. Below is a detailed guide to the configuration options available.

---

## Prerequisites
- Kubernetes 1.19+
- Helm 3.0+
- Prometheus Operator (for monitoring and alerts)

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

To deploy the Redis Distributed Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/redisdistributed
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-redis-distributed zopdev/redisdistributed
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the Redis Distributed Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-redis-distributed
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The table below outlines the essential global configuration options. For specific master and slave configurations, refer to their respective sections below.

### Global Configuration
| Input                | Type    | Description                                | Default                    |
|----------------------|---------|--------------------------------------------|----------------------------|
| `image.registry`     | String  | Docker registry for the Redis image.       | `docker.io`               |
| `image.repository`   | String  | Repository for the Redis image.            | `redis`                   |
| `image.tag`          | String  | Redis image tag.                           | `6.2.13`                  |
| `image.pullPolicy`   | String  | Image pull policy.                         | `IfNotPresent`            |

---

### Master Configuration

| Input                              | Type    | Description                                    | Default          |
|------------------------------------|---------|------------------------------------------------|------------------|
| `master.resources.requests.cpu`    | String  | CPU request for the Redis master.              | `"100m"`         |
| `master.resources.requests.memory` | String  | Memory request for the Redis master.           | `"500Mi"`        |
| `master.resources.limits.cpu`      | String  | CPU limit for the Redis master.                | `"500m"`         |
| `master.resources.limits.memory`   | String  | Memory limit for the Redis master.             | `"1000Mi"`       |
| `master.persistence.size`          | String  | Persistent storage size for the master.        | `"10Gi"`         |
| `master.livenessProbe.enabled`     | Bool    | Enable liveness probe for the master.          | `true`           |
| `master.livenessProbe.initialDelaySeconds`| Int| Initial delay for the master liveness probe.   | `30`             |
| `master.readinessProbe.enabled`    | Bool    | Enable readiness probe for the master.         | `true`           |
| `master.readinessProbe.initialDelaySeconds`| Int| Initial delay for the master readiness probe.  | `10`             |
| `master.service.type`              | String  | Service type for the master pod.               | `ClusterIP`      |
| `master.service.port`              | Int     | Port exposed by the master service.            | `6379`           |

---

### Slave Configuration

| Input                              | Type    | Description                                    | Default          |
|------------------------------------|---------|------------------------------------------------|------------------|
| `slave.enable`                     | Bool    | Enable slave deployment.                       | `true`           |
| `slave.count`                      | Int     | Number of Redis slave replicas.               | `1`              |
| `slave.resources.requests.cpu`     | String  | CPU request for Redis slave pods.             | `"100m"`         |
| `slave.resources.requests.memory`  | String  | Memory request for Redis slave pods.          | `"500Mi"`        |
| `slave.resources.limits.cpu`       | String  | CPU limit for Redis slave pods.               | `"500m"`         |
| `slave.resources.limits.memory`    | String  | Memory limit for Redis slave pods.            | `"1000Mi"`       |
| `slave.persistence.size`           | String  | Persistent storage size for slaves.           | `"10Gi"`         |
| `slave.livenessProbe.enabled`      | Bool    | Enable liveness probe for the slave pods.      | `true`           |
| `slave.livenessProbe.initialDelaySeconds`| Int | Initial delay for slave liveness probe.        | `30`             |
| `slave.readinessProbe.enabled`     | Bool    | Enable readiness probe for the slave pods.     | `true`           |
| `slave.readinessProbe.initialDelaySeconds`| Int| Initial delay for slave readiness probe.       | `10`             |
| `slave.service.type`               | String  | Service type for slave pods.                  | `ClusterIP`      |
| `slave.service.port`               | Int     | Port exposed by the slave service.            | `6379`           |

---

## Example `values.yaml`

```yaml
version: "6.2.13"

master:
  resources:
    requests:
      cpu: "100m"
      memory: "500Mi"
    limits:
      cpu: "500m"
      memory: "1000Mi"

  persistence:
    size: 10Gi

slave:
  enable : true
  count: 1
  resources:
    requests:
      cpu: "100m"
      memory: "500Mi"
    limits:
      cpu: "500m"
      memory: "1000Mi"

  persistence:
    size: 10Gi
```

---

## Features
- Deploy Redis master-slave architecture with high availability on Kubernetes.
- Configurable master and slave resources, persistence, and scaling options.
- Built-in health monitoring with liveness and readiness probes.
- Automatic failover and replication management for data reliability.
- Comprehensive monitoring with Redis Exporter and Prometheus integration.
- Customizable service types and ports for flexible networking.
- Rolling updates with zero downtime for seamless deployments.
- Persistent storage for both master and slave nodes.

---

## Monitoring

The chart includes a Redis Exporter container that exposes metrics on port 2121. These metrics are automatically collected by Prometheus when using the Prometheus Operator.

Key metrics include:
- Redis instance information
- Connected slaves count
- Memory usage
- Command statistics
- Replication status
- Connection metrics

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 