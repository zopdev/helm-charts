# ClickHouse Helm Chart

The ClickHouse Helm chart provides an easy way to deploy and manage a [ClickHouse](https://clickhouse.com/) OLAP database in your Kubernetes environment. This chart includes configurations for persistence, resource management, built-in Prometheus metrics, and automatic provisioning of application databases and users.

## Prerequisites

- Kubernetes 1.19+
- Helm 3+

## Add Helm Repository

Before installing the ClickHouse chart, add the repository to your Helm installation and update the repository index:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

See [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for more details.

---

## Install Helm Chart

To install the ClickHouse Helm chart, run the following command:

```bash
helm install [RELEASE_NAME] zopdev/clickhouse
```

Replace `[RELEASE_NAME]` with your desired release name.

For example:

```bash
helm install my-clickhouse zopdev/clickhouse
```

You can customize the installation by providing a custom `values.yaml` file or overriding values via the command line.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To uninstall the ClickHouse Helm chart and remove all associated Kubernetes resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-clickhouse
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The following table describes the configurable parameters of the ClickHouse Helm chart and their default values:

| **Input**                    | **Type**  | **Description**                                                                                       | **Default**     |
|------------------------------|-----------|-------------------------------------------------------------------------------------------------------|-----------------|
| `diskSize`                   | `string`  | Size of the persistent volume claim (PVC) for `/var/lib/clickhouse`.                                  | `"10Gi"`        |
| `version`                    | `string`  | ClickHouse server image tag (`clickhouse/clickhouse-server:<version>`).                               | `"25.3"`        |
| `resources.requests.cpu`     | `string`  | Minimum CPU resources required by the ClickHouse container.                                           | `"500m"`        |
| `resources.requests.memory`  | `string`  | Minimum memory resources required by the ClickHouse container.                                        | `"512M"`        |
| `resources.limits.cpu`       | `string`  | Maximum CPU resources the ClickHouse container can use.                                               | `"2000m"`       |
| `resources.limits.memory`    | `string`  | Maximum memory resources the ClickHouse container can use.                                            | `"2048M"`       |
| `customConfig`               | `string`  | Custom ClickHouse server XML, layered into `/etc/clickhouse-server/config.d/custom.xml`.              | `""`            |
| `services`                   | `array`   | List of `{ name, database }` entries; each provisions a database, a user, and a connection ConfigMap/Secret. | `[]`     |

You can override these values in your `values.yaml` file or pass them as flags when installing the chart.

### Example `values.yaml` File

```yaml
diskSize: "10Gi"

resources:
  requests:
    cpu: "500m"
    memory: "512M"
  limits:
    cpu: "2000m"
    memory: "2048M"

version: "25.3"

customConfig: ""

services:
  - name: orders
    database: analytics
```

To use this configuration, save it in a `values.yaml` file and pass it to the Helm install command:

```bash
helm install my-clickhouse zopdev/clickhouse -f values.yaml
```

### Example: Providing Custom ClickHouse Configuration

To override or add to the default ClickHouse server configuration, provide your own XML using the `customConfig` value. This is mounted as `/etc/clickhouse-server/config.d/custom.xml` and layered on top of the defaults.

```yaml
customConfig: |
  <clickhouse>
    <max_connections>2048</max_connections>
    <max_concurrent_queries>200</max_concurrent_queries>
  </clickhouse>
```

---

## Provisioning Databases and Users

Use the `services` array to provision one database and user per application. For each entry the chart creates:

- the database (`CREATE DATABASE IF NOT EXISTS`),
- a dedicated user with `SELECT, INSERT, ALTER, CREATE, DROP, TRUNCATE, OPTIMIZE` on that database,
- a `ConfigMap` (`<release>-<database>-<name>-clickhouse-configmap`) with the connection details, and
- a `Secret` (`<release>-<database>-<name>-clickhouse-database-secret`) holding the user's password.

A short-lived init `Pod` (`clickhouse-init-<release>-<name>`) applies the SQL via `clickhouse-client`. Generated credentials are preserved across upgrades by reading back the existing secret.

---

## Ports

| Port   | Name          | Purpose                                  |
|--------|---------------|------------------------------------------|
| `8123` | `http`        | HTTP interface (and `/ping` health check)|
| `9000` | `native`      | Native TCP protocol (used by drivers)    |
| `9009` | `interserver` | Inter-server data exchange               |
| `9363` | `metrics`     | Built-in Prometheus metrics (`/metrics`) |

---

## Features

- **Persistence:** Data is stored on a persistent volume claim, surviving pod restarts.
- **Customizable Resources:** Define resource requests and limits to optimize performance and manage costs.
- **Built-in Metrics:** ClickHouse's native Prometheus exporter is enabled on port `9363`; a `ServiceMonitor` and `PrometheusRule` are bundled.
- **Automatic Provisioning:** Declaratively create databases and users via the `services` value.
- **Health Probes:** Liveness and readiness probes use the `/ping` HTTP endpoint.

---

## Monitoring

The chart enables ClickHouse's built-in Prometheus endpoint (no sidecar exporter required) and ships:

- a `ServiceMonitor` scraping the `metrics-port` (`/metrics`, 30s interval), and
- a `PrometheusRule` with alerts for instance down, recent restart, read-only replicas, rejected inserts, and excessive connections.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for guidelines.

---

## Code of Conduct

To ensure a respectful and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.

---

## Connection Config

- **DB_DIALECT** : Specifies the database dialect. In this context always set to `clickhouse`.
- **DB_USER** : Username used to connect to the ClickHouse database.
- **DB_PORT** : The native protocol port used to connect to the ClickHouse server. Defaults to `9000`. (HTTP clients use `8123`.)
- **DB_NAME** : The name of the specific database to connect to.
- **DB_HOST** : The hostname or service name of the ClickHouse server.
- **DB_PASSWORD** : The password for `DB_USER`, stored securely in a Kubernetes secret.

---
