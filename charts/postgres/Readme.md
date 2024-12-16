# PostgreSQL Helm Chart

The PostgreSQL Helm chart provides a straightforward way to deploy and manage PostgreSQL instances in your Kubernetes cluster. It offers customizable options for persistence, resource configuration, and scalability to cater to a wide range of workloads.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+

---

## Add Helm Repository

Before installing the PostgreSQL chart, add the repository to your Helm installation and update the repository index:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

See [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for additional information.

---

## Install Helm Chart

To install the PostgreSQL Helm chart, execute the following command:

```bash
helm install [RELEASE_NAME] zopdev/postgres
```

Replace `[RELEASE_NAME]` with the desired release name.

For example:

```bash
helm install my-postgres zopdev/postgres
```

To customize the deployment, use a custom `values.yaml` file or override values directly via the command line.

See [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To uninstall the PostgreSQL Helm chart and remove all associated Kubernetes resources, use:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-postgres
```

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

The PostgreSQL Helm chart provides a variety of configurable parameters. The table below outlines the key configurations:

| **Input**               | **Type**  | **Description**                                                                                  | **Default**           |
|--------------------------|-----------|--------------------------------------------------------------------------------------------------|-----------------------|
| `postgresRootPassword`   | `string`  | Root password for the PostgreSQL instance. Leave unset for default random generation.            | _None_               |
| `image`                  | `string`  | Docker image and tag for the PostgreSQL container.                                               | `postgres:15.9`      |
| `resources.requests.cpu` | `string`  | Minimum CPU resources required by the PostgreSQL container.                                      | `"500m"`             |
| `resources.requests.memory` | `string` | Minimum memory resources required by the PostgreSQL container.                                   | `"256M"`             |
| `resources.limits.cpu`   | `string`  | Maximum CPU resources the PostgreSQL container can use.                                          | `"1500m"`            |
| `resources.limits.memory` | `string` | Maximum memory resources the PostgreSQL container can use.                                       | `"1Gi"`              |
| `diskSize`               | `string`  | Size of the persistent volume claim (PVC) for storing PostgreSQL data.                          | `"10Gi"`             |
| `updateStrategy.type`    | `string`  | Update strategy for the deployment. Options: `RollingUpdate` or `Recreate`.                     | `RollingUpdate`      |

You can override these values in a `values.yaml` file or pass them as flags during installation.

---

### Example `values.yaml` File

```yaml
postgresRootPassword: my-secure-password

image: "postgres:15.9"

resources:
  requests:
    cpu: "1"
    memory: "512Mi"
  limits:
    cpu: "2"
    memory: "2Gi"

diskSize: "20Gi"

updateStrategy:
  type: RollingUpdate
```

To use this configuration, save it in a `values.yaml` file and apply it during installation:

```bash
helm install my-postgres zopdev/postgres -f values.yaml
```

---

## Features

- **Persistence:** Store PostgreSQL data across pod restarts using persistent volume claims.
- **Resource Optimization:** Define resource requests and limits to suit your workload and cluster capacity.
- **Rolling Updates:** Ensure zero downtime during updates with the default `RollingUpdate` strategy.
- **Customizable Configurations:** Flexibly tailor the deployment using Helm values.

---

## Advanced Usage

### Custom Secrets for Root Password

You can provide a pre-existing Kubernetes secret to manage the PostgreSQL root password securely. Update the `values.yaml` file to include the secret name:

```yaml
postgresRootPassword:
  secretName: my-postgres-secret
```

Create the secret before deploying the chart:

```bash
kubectl create secret generic my-postgres-secret --from-literal=postgres-root-password=my-secure-password
```

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.