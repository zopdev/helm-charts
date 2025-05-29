# CronJob Helm Chart

This Helm chart deploys a Kubernetes CronJob with configurable scheduling, resource management, and monitoring capabilities. It provides a flexible template for running scheduled tasks in your Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3+

## Get Helm Repository Info

```console
helm repo add zopdev https://helm.zop.dev
helm repo update
```

_See [`helm repo`](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Helm Chart

```console
helm install [RELEASE_NAME] zopdev/cron-job
```

_See [configuration](#configuration) below._

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Helm Chart

```console
helm uninstall [RELEASE_NAME]
```

This removes all the Kubernetes components associated with the chart and deletes the release.

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

## Configuration

### Basic Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `name` | string | Name of the cron job | `"hello-api"` |
| `image` | string | Docker container image with tag | `"zopdev/sample-go-api:latest"` |
| `schedule` | string | Cron schedule for job execution | `"0 */1 * * *"` |
| `suspend` | boolean | Whether to suspend the cron job | `false` |
| `concurrencyPolicy` | string | How to handle concurrent executions (`Allow`, `Forbid`, `Replace`) | `"Replace"` |
| `command` | string | Command to execute in the container | `""` |

### Resource Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `minCPU` | string | Minimum CPU resources required | `"100m"` |
| `minMemory` | string | Minimum memory resources required | `"128M"` |
| `maxCPU` | string | Maximum CPU resources allowed | `"500m"` |
| `maxMemory` | string | Maximum memory resources allowed | `"512M"` |

### Port Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `httpPort` | integer | HTTP port for the container | `8000` |
| `metricsPort` | integer | Metrics port for Prometheus scraping | `2121` |

### Environment Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `env` | map | Environment variables for the container | `{"APP_NAME": "hello-api"}` |
| `envList` | list | Environment variables as a list | `[]` |
| `envFrom.configmaps` | list | List of ConfigMaps to mount as environment variables | `[]` |
| `envFrom.secrets` | list | List of Secrets to mount as environment variables | `[]` |

### Volume Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `volumeMounts.configmaps` | list | List of ConfigMaps to mount | `[]` |
| `volumeMounts.secrets` | list | List of Secrets to mount | `[]` |
| `volumeMounts.pvc` | list | List of PVCs to mount | `[]` |

### Alerting Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `alerts.standard.infra.cronjobFailedThreshold` | integer | Alert if cron job execution fails beyond threshold | `0` |

## Example values.yaml

```yaml
# Name of the cron
name: hello-api

# Docker container image with tag
image: "zopdev/sample-go-api:latest"

imagePullSecrets:
# - gcr-secrets
# - acr-secrets
# - ecr-secrets

#cron JOB
schedule: "0 */1 * * *"
suspend: false
concurrencyPolicy: "Replace"
command: ""

# Port on which container runs its service
httpPort: 8000
metricsPort: 2121

# Resource allocations
minCPU: "100m"
minMemory: "128M"
maxCPU: "500m"
maxMemory: "512M"

envFrom:
  secrets: [] #List of secrets
  configmaps: [] #List of Configmaps

# All environment variables can be passed as a map
env:
  APP_NAME: hello-api

# Environment variables as a list (new format)
envList:
# - name: APP_NAME
#   value: hello-api
# - name: DB_HOST
#   value: localhost


appSecrets: false

volumeMounts:
  configmaps:
  #    - name: zopdev-configmap
  #      mountPath: /etc/env
  secrets:
  #    - name: zopdev-secret
  #      mountPath: /etc/secret
  pvc:
#    - name: zopdev-volume
#      mountPath: /etc/data

alerts:
  standard:
    infra:
      cronjobFailedThreshold: 0
datastores:
  mysql:
  postgres:
  redis:
  surrealdb:
  solr:
  chromadb:
  mariadb:
  cockroachdb:
  cassandra:
  redisdistributed:
  scylladb:
  kafka: 
```

## Features

- Configurable cron schedule
- Resource limits and requests
- Environment variable management
- Volume mounting support
- Prometheus metrics integration
- Job failure monitoring
- Concurrency policy control
- Support for various data stores:
  - MySQL
  - PostgreSQL
  - Redis
  - Solr
  - SurrealDB
  - ChromaDB
  - MariaDB
  - CockroachDB
  - Cassandra
  - Redis Distributed
  - ScyllaDB
  - Kafka

## Architecture

The CronJob deployment includes:
- Kubernetes CronJob resource
- Configurable container resources
- Volume mounts for data persistence
- Environment variable configuration
- Metrics endpoint for monitoring
- Alert rules for job failures

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.

