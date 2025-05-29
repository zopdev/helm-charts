# MariaDB Helm Chart

This Helm chart deploys a MariaDB cluster on Kubernetes, including master-slave replication. Below is a detailed guide to the configuration options available.

---

## Prerequisites
- Kubernetes 1.18+
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

To deploy the MariaDB Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/mariadb
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-mariadb zopdev/mariadb
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the MariaDB Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-mariadb
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The table below outlines the essential global configuration options. For specific master and slave configurations, refer to their respective sections below.

### Global Configuration
| Input                         | Type    | Description                                | Default                    |
|-------------------------------|---------|--------------------------------------------|----------------------------|
| `image.registry`              | String  | Docker registry for the MariaDB image.     | `docker.io`               |
| `image.repository`            | String  | Repository for the MariaDB image.          | `bitnami/mariadb`         |
| `image.tag`                   | String  | MariaDB image tag.                         | `10.3.22-debian-10-r27`   |
| `image.pullPolicy`            | String  | Image pull policy.                         | `IfNotPresent`            |
| `rootUser.password`           | String  | Root password for MariaDB.                 | `"root"`                  |
| `replication.enabled`         | Bool    | Enable master-slave replication.           | `true`                    |
| `replication.user`            | String  | Username for replication.                  | `replicator`              |
| `replication.password`        | String  | Password for the replication user.         | `"root"`                  |

---

### Master Configuration

| Input                              | Type    | Description                                    | Default          |
|------------------------------------|---------|------------------------------------------------|------------------|
| `master.resources.requests.cpu`    | String  | CPU request for the MariaDB master.            | `"500m"`         |
| `master.resources.requests.memory` | String  | Memory request for the MariaDB master.         | `"256Mi"`        |
| `master.resources.limits.cpu`      | String  | CPU limit for the MariaDB master.              | `"1500m"`        |
| `master.resources.limits.memory`   | String  | Memory limit for the MariaDB master.           | `"1Gi"`          |
| `master.persistence.size`          | String  | Persistent storage size for the master.        | `"10Gi"`         |
| `master.livenessProbe.enabled`     | Bool    | Enable liveness probe for the master.          | `true`           |
| `master.livenessProbe.initialDelaySeconds`| Int| Initial delay for the master liveness probe.   | `120`            |
| `master.readinessProbe.enabled`    | Bool    | Enable readiness probe for the master.         | `true`           |
| `master.readinessProbe.initialDelaySeconds`| Int| Initial delay for the master readiness probe.  | `30`             |
| `master.service.type`              | String  | Service type for the master pod.               | `ClusterIP`      |
| `master.service.port`              | Int     | Port exposed by the master service.            | `3306`           |

---

### Slave Configuration

| Input                              | Type    | Description                                    | Default          |
|------------------------------------|---------|------------------------------------------------|------------------|
| `slave.replicas`                   | Int     | Number of MariaDB slave replicas.             | `1`              |
| `slave.resources.requests.cpu`     | String  | CPU request for MariaDB slave pods.           | `"500m"`         |
| `slave.resources.requests.memory`  | String  | Memory request for MariaDB slave pods.        | `"256Mi"`        |
| `slave.resources.limits.cpu`       | String  | CPU limit for MariaDB slave pods.             | `"1500m"`        |
| `slave.resources.limits.memory`    | String  | Memory limit for MariaDB slave pods.          | `"1Gi"`          |
| `slave.persistence.size`           | String  | Persistent storage size for slaves.           | `"10Gi"`         |
| `slave.livenessProbe.enabled`      | Bool    | Enable liveness probe for the slave pods.      | `true`           |
| `slave.livenessProbe.initialDelaySeconds`| Int | Initial delay for slave liveness probe.        | `120`            |
| `slave.readinessProbe.enabled`     | Bool    | Enable readiness probe for the slave pods.     | `true`           |
| `slave.readinessProbe.initialDelaySeconds`| Int| Initial delay for slave readiness probe.       | `30`             |
| `slave.service.type`               | String  | Service type for slave pods.                  | `ClusterIP`      |
| `slave.service.port`               | Int     | Port exposed by the slave service.            | `3306`           |

---

## Example `values.yaml`

```yaml
version: 10.3.22-debian-10-r27

replication:
  enabled: true

master:
  resources:
    requests:
      cpu: "500m"
      memory: "256M"
    limits:
      cpu: "1500m"
      memory: "1Gi"
  persistence:
    size: 10Gi

slave:
  replicas: 1

  resources:
    requests:
      cpu: "500m"
      memory: "256M"
    limits:
      cpu: "1500m"
      memory: "1Gi"

  persistence:
    size: 10Gi
```

---

## Features
- Deploy MariaDB master-slave architecture on Kubernetes.
- Configurable master and slave resources and persistence.
- Probes for liveness and readiness checks for health monitoring.
- Master-slave replication with customizable credentials and scaling.
- Customizable service types and ports for networking flexibility.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.