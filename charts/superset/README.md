# Apache Superset Helm Chart

This Helm chart deploys Apache Superset on Kubernetes, providing a modern, enterprise-ready business intelligence web application. Superset enables users to create and share interactive dashboards, perform data exploration, and visualize data through a rich set of charts and graphs.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- PostgreSQL database (automatically installed as a dependency)
- Redis instance (automatically installed as a dependency)

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

To deploy the Superset Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/superset
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-superset zopdev/superset
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the Superset Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-superset
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The Superset Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

### Service Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `service.nginx.host`         | `string`  | Hostname for the Superset service.                                                            | `""`                 |
| `service.nginx.tlshost`      | `string`  | TLS hostname for HTTPS access.                                                                | `""`                 |
| `service.nginx.tlsSecretname`| `string`  | Name of the TLS secret for HTTPS.                                                             | `""`                 |

### Resource Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `resources.requests.cpu`     | `string`  | Minimum CPU resources required.                                                                | `"250m"`             |
| `resources.requests.memory`  | `string`  | Minimum memory resources required.                                                             | `"250Mi"`            |
| `resources.limits.cpu`       | `string`  | Maximum CPU resources allowed.                                                                 | `"500m"`             |
| `resources.limits.memory`    | `string`  | Maximum memory resources allowed.                                                              | `"500Mi"`            |

### Superset Node Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `supersetNode.connections.redis_host` | `string` | Redis host address.                                                      | `"{{ .Release.Name }}-redis-headless-service"` |
| `supersetNode.connections.redis_port` | `string` | Redis port number.                                                       | `"6379"`             |
| `supersetNode.connections.db_host` | `string` | PostgreSQL host address.                                                | `"{{ .Release.Name }}-postgres"` |
| `supersetNode.connections.db_port` | `string` | PostgreSQL port number.                                                 | `"5432"`             |
| `supersetNode.connections.db_user` | `string` | PostgreSQL username.                                                   | `"superset_user"`    |
| `supersetNode.connections.db_pass` | `string` | PostgreSQL password.                                                   | `"superset"`         |
| `supersetNode.connections.db_name` | `string` | PostgreSQL database name.                                              | `"superset"`         |

### Initialization Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `init.createAdmin`          | `boolean` | Whether to create an admin user.                                                               | `true`               |
| `init.adminUser.username`   | `string`  | Admin username.                                                                                | `"admin"`            |
| `init.adminUser.firstname`  | `string`  | Admin first name.                                                                              | `"Superset"`         |
| `init.adminUser.lastname`   | `string`  | Admin last name.                                                                               | `"Admin"`            |
| `init.adminUser.email`      | `string`  | Admin email address.                                                                           | `"admin@superset.com"` |
| `init.adminUser.password`   | `string`  | Admin password.                                                                                | `"admin"`            |

### Celery Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `supersetCeleryBeat.enabled` | `boolean` | Whether to enable Celery Beat.                                                                 | `false`              |
| `supersetCeleryFlower.enabled` | `boolean` | Whether to enable Celery Flower.                                                           | `false`              |

---

## Example `values.yaml`

```yaml
service:
  nginx:
    host: "superset.example.com"
    tlshost: "superset.example.com"
    tlsSecretname: "superset-tls"

resources:
  requests:
    cpu: 250m
    memory: 250Mi
  limits:
    cpu: 500m
    memory: 500Mi

supersetNode:
  connections:
    redis_host: "my-superset-redis-headless-service"
    redis_port: "6379"
    db_host: "my-superset-postgres"
    db_port: "5432"
    db_user: "superset_user"
    db_pass: "superset"
    db_name: "superset"

init:
  createAdmin: true
  adminUser:
    username: "admin"
    firstname: "Superset"
    lastname: "Admin"
    email: "admin@example.com"
    password: "secure-password"

supersetCeleryBeat:
  enabled: true

supersetCeleryFlower:
  enabled: true

postgres:
  enabled: true
  postgresRootPassword: "superset"
  services:
    - name: "superset"
      password: "superset"
      database: "superset"

redis:
  enabled: true
```

---

## Features

- Deploys Apache Superset with all dependencies
- Automatic PostgreSQL database setup
- Redis integration for caching and task queue
- Configurable resource limits and requests
- Automatic admin user creation
- Database initialization and schema upgrades
- Optional Celery integration for async tasks
- Customizable feature flags
- Data source import support
- Role-based access control
- HTTPS support

---

## Architecture

The Superset deployment includes:
- Superset web application
- PostgreSQL database (dependency)
- Redis instance (dependency)
- Optional Celery workers
- Optional Celery Beat scheduler
- Optional Celery Flower monitoring
- Database initialization jobs
- Ingress configuration for external access
- Environment variable configuration
- Database connection management

---

## Security Features

- Configurable admin user creation
- Database password management
- HTTPS support
- Role-based access control
- Secure environment variable handling
- Resource limits and requests
- Database SSL configuration

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 