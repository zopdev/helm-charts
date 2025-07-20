# Outline Helm Chart

This Helm chart deploys Outline, a modern team knowledge base and wiki platform, on Kubernetes. Outline provides a beautiful, real-time collaborative editing experience with features like rich text editing, markdown support, and team collaboration tools.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- PostgreSQL database (automatically installed as a dependency)
- Redis instance (automatically installed as a dependency)

---

## Dependencies

Before installing the chart, you need to download the required dependencies. Run the following command in the chart directory:

```bash
helm dependency build
```

This command will:
1. Read the dependencies from `Chart.yaml`
2. Download the required charts (PostgreSQL, Redis, and Service) from the specified repositories
3. Store them in the `charts/` directory
4. Create or update the `Chart.lock` file with the exact versions

If you encounter any issues with the dependencies, you can try:
```bash
helm dependency update  # Updates dependencies to the latest versions
```

This chart requires the following dependencies to be installed:

### PostgreSQL
- **Chart**: `postgres`
- **Version**: `0.0.3`
- **Repository**: `https://helm.zop.dev`
- **Purpose**: Provides the primary database for Outline's content and user data

### Redis
- **Chart**: `redis`
- **Version**: `0.0.1`
- **Repository**: `https://helm.zop.dev`
- **Purpose**: Used for caching and real-time collaboration features

### Service
- **Chart**: `service`
- **Version**: `0.0.17`
- **Repository**: `https://helm.zop.dev`
- **Purpose**: Manages the Outline application deployment and service configuration

To install these dependencies automatically, ensure the following in your `values.yaml`:

```yaml
postgres:
  enabled: true
  # Additional PostgreSQL configuration...

redis:
  enabled: true
  # Additional Redis configuration...

service:
  enabled: true
  # Additional service configuration...
```

The dependencies will be automatically installed when you deploy the Outline chart. You can customize their configuration through the respective sections in your `values.yaml` file.

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

To deploy the Outline Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/outline
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-outline zopdev/outline
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the Outline Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-outline
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The Outline Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

### Service Configuration

| **Input**             | **Type**  | **Description**                    | **Default**             |
|-----------------------|-----------|------------------------------------|-------------------------|
| `service.name`        | `string`  | Name of the Outline service.       | `"outline"`             |
| `service.image`       | `string`  | Docker image for Outline.          | `"outlinewiki/outline"` |
| `service.minCPU`      | `string`  | Minimum CPU resources required.    | `"250m"`                |
| `service.minMemory`   | `string`  | Minimum memory resources required. | `"1000Mi"`              |
| `service.maxCPU`      | `string`  | Maximum CPU resources allowed.     | `"500m"`                |
| `service.maxMemory`   | `string`  | Maximum memory resources allowed.  | `"1500Mi"`              |
| `service.minReplicas` | `integer` | Minimum number of replicas.        | `1`                     |

### Environment Configuration

| **Input**                  | **Type**  | **Description**                          | **Default**        |
|----------------------------|-----------|------------------------------------------|--------------------|
| `service.env.SECRET_KEY`   | `string`  | Secret key for encryption (32-byte hex). | Randomly generated |
| `service.env.UTILS_SECRET` | `string`  | Secret for utilities (32-byte hex).      | Randomly generated |
| `service.env.FILE_STORAGE` | `string`  | File storage backend type.               | `"local"`          |
| `service.env.FORCE_HTTPS`  | `boolean` | Whether to force HTTPS.                  | `false`            |
| `service.env.PGSSLMODE`    | `string`  | PostgreSQL SSL mode.                     | `"disable"`        |
| `service.env.PORT`         | `integer` | Port for the Outline service.            | `3000`             |

### Database Configuration

| **Input**                       | **Type** | **Description**                  | **Default** |
|---------------------------------|----------|----------------------------------|-------------|
| `postgres.services[0].name`     | `string` | Name of the PostgreSQL service.  | `"outline"` |
| `postgres.services[0].database` | `string` | Name of the PostgreSQL database. | `"outline"` |
| `redis.services[0].name`        | `string` | Name of the Redis service.       | `"outline"` |
| `redis.services[0].database`    | `string` | Redis database number.           | `"outline"` |

### Health Check Configuration

| **Input**                                    | **Type**  | **Description**                    | **Default** |
|----------------------------------------------|-----------|------------------------------------|-------------|
| `service.livenessProbe.enable`               | `boolean` | Whether to enable liveness probe.  | `true`      |
| `service.livenessProbe.initialDelaySeconds`  | `integer` | Initial delay for liveness probe.  | `30`        |
| `service.readinessProbe.enable`              | `boolean` | Whether to enable readiness probe. | `true`      |
| `service.readinessProbe.initialDelaySeconds` | `integer` | Initial delay for readiness probe. | `30`        |

---

## Example `values.yaml`

```yaml
service:
  name: outline
  image: outlinewiki/outline
  minCPU: "250m"
  minMemory: "1000Mi"
  maxCPU: "500m"
  maxMemory: "1500Mi"
  minReplicas: 1

  env:
    SECRET_KEY: ""
    UTILS_SECRET: ""
    FILE_STORAGE: "local"
    FORCE_HTTPS: false
    PGSSLMODE: "disable"
    PORT: 3000
    FILE_STORAGE_LOCAL_ROOT_DIR: "/data"

postgres:
  services:
    - name: "outline"
      database: "outline"

redis:
  services:
    - name: "outline"
      database: "outline"
```

---

## Features

- Deploys Outline wiki platform with all dependencies
- Automatic PostgreSQL database setup
- Redis integration for caching and real-time features
- Configurable resource limits and requests
- Health monitoring with liveness and readiness probes
- Local file storage support
- HTTPS support
- Customizable environment variables
- Automatic database migrations
- Persistent storage for file uploads

---

## Architecture

The Outline deployment includes:
- Outline application pods
- PostgreSQL database (dependency)
- Redis instance (dependency)
- Persistent volume for file storage
- Health check endpoints
- Ingress configuration for external access
- Environment variable configuration
- Database connection management

---

## Security Features

- Configurable secret keys for encryption
- HTTPS support
- Database SSL configuration
- Health check monitoring
- Resource limits and requests
- Secure environment variable handling

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 