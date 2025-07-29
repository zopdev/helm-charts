# WordPress Helm Chart

This Helm chart deploys WordPress, the world's most popular content management system, on Kubernetes. WordPress provides a flexible and user-friendly platform for creating websites, blogs, and web applications.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- MySQL database (automatically installed as a dependency)

---

## Dependencies

Before installing the chart, you need to download the required dependencies. Run the following command in the chart directory:

```bash
helm dependency build
```

This command will:
1. Read the dependencies from `Chart.yaml`
2. Download the required charts (MySQL and Service) from the specified repositories
3. Store them in the `charts/` directory
4. Create or update the `Chart.lock` file with the exact versions

If you encounter any issues with the dependencies, you can try:
```bash
helm dependency update  # Updates dependencies to the latest versions
```

This chart requires the following dependencies to be installed:

### MySQL
- **Chart**: `mysql`
- **Version**: `0.0.17`
- **Repository**: `https://helm.zop.dev`
- **Purpose**: Provides the primary database for WordPress content and configuration

### Service
- **Chart**: `service`
- **Version**: `0.0.17`
- **Repository**: `https://helm.zop.dev`
- **Purpose**: Manages the WordPress application deployment and service configuration

To install these dependencies automatically, ensure the following in your `values.yaml`:

```yaml
mysql:
  enabled: true
  # Additional MySQL configuration...

service:
  enabled: true
  # Additional service configuration...
```

The dependencies will be automatically installed when you deploy the WordPress chart. You can customize their configuration through the respective sections in your `values.yaml` file.

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

To deploy the WordPress Helm chart, use the following command:

```bash
helm install wordpress zopdev/wordpress
```

The release name must be `wordpress` for the chart to install properly.

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the WordPress Helm chart and associated resources, run:

```bash
helm uninstall wordpress
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The WordPress Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

### Service Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `service.name`               | `string`  | Name of the WordPress service.                                                                 | `"wordpress"`        |
| `service.image`              | `string`  | Docker image for WordPress.                                                                    | `"wordpress:latest"` |
| `service.minCPU`            | `string`  | Minimum CPU resources required.                                                                | `"250m"`             |
| `service.minMemory`         | `string`  | Minimum memory resources required.                                                             | `"1000Mi"`           |
| `service.maxCPU`            | `string`  | Maximum CPU resources allowed.                                                                 | `"500m"`             |
| `service.maxMemory`         | `string`  | Maximum memory resources allowed.                                                              | `"1500Mi"`           |
| `service.minReplicas`       | `integer` | Minimum number of replicas.                                                                    | `1`                  |
| `service.maxReplicas`       | `integer` | Maximum number of replicas.                                                                    | `1`                  |
| `service.httpPort`          | `integer` | HTTP port for the WordPress service.                                                          | `80`                 |

### Environment Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `service.env.WORDPRESS_DB_HOST` | `string` | MySQL database host.                                                                  | `"$(DB_HOST):$(DB_PORT)"` |
| `service.env.WORDPRESS_DB_USER` | `string` | MySQL database username.                                                               | `"$(DB_USER)"`       |
| `service.env.WORDPRESS_DB_PASSWORD` | `string` | MySQL database password.                                                         | `"$(DB_PASSWORD)"`   |
| `service.env.WORDPRESS_DB_NAME` | `string` | MySQL database name.                                                                  | `"$(DB_NAME)"`       |

### MySQL Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `mysql.services[0].name`     | `string`  | Name of the MySQL service.                                                                     | `"wordpress"`        |
| `mysql.services[0].database` | `string`  | Name of the MySQL database.                                                                    | `"wordpress"`        |

### Ingress Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `service.nginx.annotations`  | `object`  | Nginx ingress annotations.                                                                     | `{}`                 |

---

## Example `values.yaml`

```yaml
mysql:
  services:
    - name: wordpress
      database: wordpress

service:
  name: wordpress
  image: wordpress:latest
  minCPU: "250m"
  minMemory: "1000Mi"
  maxCPU: "500m"
  maxMemory: "1500Mi"
  minReplicas: 1
  maxReplicas: 1

  env:
    WORDPRESS_DB_HOST: "$(DB_HOST):$(DB_PORT)"
    WORDPRESS_DB_USER: "$(DB_USER)"
    WORDPRESS_DB_PASSWORD: "$(DB_PASSWORD)"
    WORDPRESS_DB_NAME: "$(DB_NAME)"

  datastores:
    mysql:
      - datastore: wordpress
        database: wordpress

  httpPort: 80
```

---

## Features

- Deploys WordPress with all dependencies
- Automatic MySQL database setup
- Configurable resource limits and requests
- Horizontal pod autoscaling support
- Ingress configuration for external access
- Environment variable configuration
- Database connection management
- Persistent storage for uploads
- Customizable WordPress settings
- Nginx ingress support

---

## Architecture

The WordPress deployment includes:
- WordPress application pods
- MySQL database (dependency)
- Persistent volume for uploads
- Ingress configuration for external access
- Environment variable configuration
- Database connection management
- Health check endpoints
- Resource management

---

## Security Features

- Database password management
- Ingress authentication support
- Resource limits and requests
- Secure environment variable handling
- Database connection security
- Pod security context
- Network policies

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 