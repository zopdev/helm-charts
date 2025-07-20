# MySQL Helm Chart

The MySQL Helm chart provides an easy way to deploy and manage MySQL instances in your Kubernetes environment. This chart includes configurations for persistence, resource management, and scalability to suit various use cases.

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+

## Add Helm Repository

Before installing the MySQL chart, add the repository to your Helm installation and update the repository index:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

See [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for more details.

---

## Install Helm Chart

To install the MySQL Helm chart, run the following command:

```bash
helm install [RELEASE_NAME] zopdev/mysql
```

Replace `[RELEASE_NAME]` with your desired release name. 

For example:

```bash
helm install my-mysql zopdev/mysql
```

You can customize the installation by providing a custom `values.yaml` file or overriding values via the command line.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To uninstall the MySQL Helm chart and remove all associated Kubernetes resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-mysql
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The following table describes the configurable parameters of the MySQL Helm chart and their default values:

| **Input**              | **Type**  | **Description**                                                                                  | **Default**           |
|-------------------------|-----------|--------------------------------------------------------------------------------------------------|-----------------------|
| `mysqlRootPassword`     | `string`  | Root password for the MySQL instance. Leave unset for default random generation.                | _None_               |
| `updateStrategy.type`   | `string`  | Update strategy for the deployment. Options: `RollingUpdate` or `Recreate`.                    | `RollingUpdate`      |
| `diskSize`              | `string`  | Size of the persistent volume claim (PVC) for storing MySQL data.                              | `"10Gi"`             |
| `image`                 | `string`  | Docker image and tag for the MySQL container.                                                   | `mysql:8.0`          |
| `resources.requests.cpu`| `string`  | Minimum CPU resources required by the MySQL container.                                          | `"500m"`             |
| `resources.requests.memory`| `string`| Minimum memory resources required by the MySQL container.                                       | `"256M"`             |
| `resources.limits.cpu`  | `string`  | Maximum CPU resources the MySQL container can use.                                              | `"1500m"`            |
| `resources.limits.memory`| `string` | Maximum memory resources the MySQL container can use.                                           | `"1Gi"`              |
| `customMyCnf`           | `string`  | Custom MySQL configuration to be layered on top of the default config. Provided as a full INI file. | `""`                 |

You can override these values in your `values.yaml` file or pass them as flags when installing the chart.

### Example `values.yaml` File

```yaml
diskSize: "10Gi"

# Resource configuration
resources:
  requests:
    cpu: "500m"
    memory: "256M"
  limits:
    cpu: "1500m"
    memory: "1024M"

version: "8.0"

customMyCnf: ""
```

To use this configuration, save it in a `values.yaml` file and pass it to the Helm install command:

```bash
helm install my-mysql zopdev/mysql -f values.yaml
```

### Example: Providing Custom MySQL Configuration

To override or add to the default MySQL configuration, provide your own `my.cnf` content using the `customMyCnf` value. This will be mounted as `/etc/mysql/conf.d/custom.cnf` in the container and layered on top of the default config.

Example `values.yaml`:

```yaml
customMyCnf: |
  [mysqld]
  max_connections = 200
  sql_mode = STRICT_ALL_TABLES
```

This allows you to specify any MySQL configuration options you need, without losing the chart's defaults.

---

## Features

- **Persistence:** The chart supports persistent volume claims to store MySQL data across pod restarts.
- **Customizable Resources:** Define resource requests and limits to optimize performance and manage costs.
- **Scalable:** Use the `updateStrategy` configuration to handle updates with zero downtime.
- **Pre-configured Settings:** Defaults are optimized for a variety of workloads.

---

## Advanced Usage

### Custom Secrets for Root Password

You can provide a pre-existing Kubernetes secret for the MySQL root password. To enable this, modify the `values.yaml` file with the secret name:

```yaml
mysqlRootPassword:
  secretName: my-mysql-secret
```

Ensure the secret is created before deploying the chart:

```bash
kubectl create secret generic my-mysql-secret --from-literal=mysql-root-password=my-secure-password
```

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for guidelines.

---

## Code of Conduct

To ensure a respectful and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.