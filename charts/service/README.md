# Service Helm Chart

This Helm chart deploys a generic service with configurable components for Kubernetes. It provides a flexible template for deploying applications with features like health checks, resource management, monitoring, and alerting.

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
helm install [RELEASE_NAME] zopdev/service
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
| `name` | string | Name of the service | `"hello-api"` |
| `replicaCount` | integer | Number of replicas to run | `2` |
| `image` | string | Docker container image with tag | `"zopdev/sample-go-api:latest"` |
| `httpPort` | integer | HTTP Port on which container runs its services | `8000` |
| `metricsPort` | integer | Metrics port for scraping the metrics from container | `2121` |
| `metricsScrapeInterval` | string | Time interval that metrics will be scraped | `"30s"` |

### Resource Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `minCPU` | string | Minimum CPU resources required | `"100m"` |
| `minMemory` | string | Minimum memory resources required | `"128M"` |
| `maxCPU` | string | Maximum CPU resources allowed | `"500m"` |
| `maxMemory` | string | Maximum memory resources allowed | `"512M"` |
| `minReplicas` | integer | Minimum number of replicas | `2` |
| `maxReplicas` | integer | Maximum number of replicas | `4` |
| `minAvailable` | integer | Minimum number of pods that must be available during voluntary disruptions | `1` |

### Health Checks

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `livenessProbe.enable` | boolean | Whether to enable liveness probe | `false` |
| `livenessProbe.initialDelaySeconds` | integer | Initial delay for liveness probe | `3` |
| `livenessProbe.timeoutSeconds` | integer | Timeout for liveness probe | `3` |
| `livenessProbe.periodSeconds` | integer | Period for liveness probe | `10` |
| `livenessProbe.failureThreshold` | integer | Failure threshold for liveness probe | `3` |
| `readinessProbe.enable` | boolean | Whether to enable readiness probe | `false` |
| `readinessProbe.initialDelaySeconds` | integer | Initial delay for readiness probe | `3` |
| `readinessProbe.timeoutSeconds` | integer | Timeout for readiness probe | `3` |
| `readinessProbe.periodSeconds` | integer | Period for readiness probe | `10` |
| `readinessProbe.failureThreshold` | integer | Failure threshold for readiness probe | `3` |

### Environment Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `env` | map | Environment variables for the container | `{}` |
| `envList` | list | Environment variables as a list | `[]` |
| `envFrom.configmaps` | list | List of ConfigMaps to mount as environment variables | `[]` |
| `envFrom.secrets` | list | List of Secrets to mount as environment variables | `[]` |

### Volume Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `volumeMounts.emptyDir` | list | List of emptyDir volumes to mount | `[]` |
| `volumeMounts.configmaps` | list | List of ConfigMaps to mount | `[]` |
| `volumeMounts.secrets` | list | List of Secrets to mount | `[]` |
| `volumeMounts.pvc` | list | List of PVCs to mount | `[]` |

### Alerting Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `alerts.standard.infra.unavailableReplicasThreshold` | integer | Alert if available replicas is less than desired | `0` |
| `alerts.standard.infra.podRestartThreshold` | integer | Alert if pod restarts exceed threshold | `0` |
| `alerts.standard.infra.hpaNearingMaxPodThreshold` | integer | Alert if replica count exceeds threshold percentage | `80` |
| `alerts.standard.infra.serviceMemoryUtilizationThreshold` | integer | Alert if memory utilization exceeds threshold | `90` |
| `alerts.standard.infra.serviceCpuUtilizationThreshold` | integer | Alert if CPU utilization exceeds threshold | `90` |

### Custom Alerts

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `alerts.custom[].name` | string | Name of the custom alert | `""` |
| `alerts.custom[].description` | string | Description of the alert | `""` |
| `alerts.custom[].alertRule` | string | Metric name exposed by /metric endpoint | `""` |
| `alerts.custom[].sumByLabel` | string | Metric events key | `""` |
| `alerts.custom[].percentile` | number | Percentile for histogram queries | `-1.0` |
| `alerts.custom[].labelValue` | string | Metric event name | `""` |
| `alerts.custom[].queryOperator` | string | Query operator for comparison | `">"` |
| `alerts.custom[].timeWindow` | string | Time window for the alert | `"5m"` |
| `alerts.custom[].threshold` | number | Threshold value for the alert | `0` |

## Example values.yaml

```yaml
# Name of the service
name: hello-api

# Number of replicas to run
replicaCount: 2

# Docker container image with tag
image: "zopdev/sample-go-api:latest"

extraAnnotations:

Containers:
  privileged: false

imagePullSecrets:
# - gcr-secrets
# - acr-secrets
# - ecr-secrets

# Port on which container runs its services
httpPort: 8000
metricsPort: 2121

ports: # Provide the ports on which container runs its services
# grpc: 9100

nginx:
  host:
  annotations:
  tlsHost:
  tlsSecretName:

metricsScrapeInterval: 30s

envFrom:
  secrets: [] #List of secrets
  configmaps: [] #List of Configmaps

# Resource allocations
minCPU: "100m"
minMemory: "128M"
maxCPU: "500m"
maxMemory: "512M"
minReplicas: 2
maxReplicas: 4
minAvailable: 1

# Whether application is a CLI service
cliService: false

# Heartbeat URL
heartbeatURL: ""

readinessProbe:
  enable: false
#  initialDelaySeconds: 3
#  timeoutSeconds: 3
#  periodSeconds: 10
#  failureThreshold: 3

livenessProbe:
  enable: false
#  initialDelaySeconds: 3
#  timeoutSeconds: 3
#  periodSeconds: 10
#  failureThreshold: 3

# All environment variables can be passed as a map
env:
# APP_NAME: hello-api

# Environment variables as a list (new format)
envList:
# - name: APP_NAME
#   value: hello-api
# - name: DB_HOST
#   value: localhost


appSecrets: false

command :

volumeMounts:
  emptyDir:
  #    - name: zopdev-emptydir
  configmaps:
  #    - name: zopdev-configmap
  #      mountPath: /etc/env
  #      configName:
  #      readOnly: true
  secrets:
  #    - name: zopdev-secret
  #      mountPath: /etc/secret
  #      readOnly: true
  #      secretName: 
  pvc:
#    - name: zopdev-volume
#      mountPath: /etc/data
#      pvcName: zopdev-pvc

alerts:
  standard:
    infra:
      unavailableReplicasThreshold: 0                   # Alert if the available replicas is lesser than number of desired replicas
      podRestartThreshold: 0                            # Alert if the pod restarts goes beyond threshold over a 5-minute window.
      podRestartTimeWindow: "5m"                        # Time window  ,default "5m"
      hpaNearingMaxPodThreshold: 80                     # Alert if replica count crosses the threshold percentage of max pod count
      serviceMemoryUtilizationThreshold: 90             # Alert if service memory exceeds threshold
      serviceCpuUtilizationThreshold: 90                # Alert if service cpu exceeds threshold
      serviceCpuUtilizationTimeWindow: "5m"             # Time window for service cpu utilization
      healthCheckFailureThreshold: 50                   # Alert if  application health-check failures goes beyond 50 in a 5-minute window.
      healthCheckFailureTimeWindow: "5m"                # Time window  ,default "5m"
  custom:
  # - name: "Custom alert if user_created events goes below threshold for 5 min"
  #   description: "Custom alert if user_created events goes below threshold for 5 min"
  #   alertRule: "user_post_get_counter" # Metric Name exposed by /metric endpoint
  #   sumByLabel: "events" # Metric events key; can be empty string
  #   percentile: -1.0 #Percentile is useful for histogram queries
  #   labelValue: "user_created" # Metric Event Name; can be empty string
  #   queryOperator: <= # Query Operator, by default its `>`
  #   timeWindow: "5m"
  #   threshold: 1
  #   labels:
  #     severity: critical

  # initContainer can be used to run database migration or other types of initialization operation before deployment
  #initContainer:
  #  image:
  #  args: ["gofr migrate -method=UP -database=gorm"]
  #  env:
  #    cloud: "AWS"
  #  secrets:
  #   DB_PASSWORD: zs-test-postgresqldb-db-secret      # Secrets will be in the format env_variable: AWS_Secret_Name

# This section deals with creating custom dashboards for grafana
grafanaDashboard:
#  sample format for using json model
#  custom_dashboard.json: 
#  {"annotations":{"list":[{"builtIn":1,"datasource":"-- Grafana --","enable":true,"hide":true,"iconColor":"rgba(0, 211, 255, 1)","name":"Annotations & Alerts","target":{"limit":100,"matchAny":false,"tags":[],"type":"dashboard"},"type":"dashboard"}]},"editable":true,"gnetId":null,"graphTooltip":0,"id":27,"links":[],"panels":[],"schemaVersion":30,"style":"dark","tags":[],"templating":{"list":[]},"time":{"from":"now-6h","to":"now"},"timepicker":{},"timezone":"","title":"Custom dashboard","version":1} 

datastores:
  mysql:
  postgres:
  redis:
  solr:
  surrealdb:
  chromadb:
  mariadb:
  cockroachdb:
  cassandra:
  redisdistributed:
  scylladb:
  kafka:
  solrcloud:
```

## Features

- Configurable resource limits and requests
- Health monitoring with liveness and readiness probes
- Environment variable management
- Volume mounting support
- Prometheus metrics integration
- Custom alerting rules
- Horizontal Pod Autoscaling
- Pod Disruption Budget
- Service monitoring
- Custom Grafana dashboards support

## Architecture

The service deployment includes:
- Application pods with configurable replicas
- Service for network access
- Horizontal Pod Autoscaler
- Pod Disruption Budget
- ServiceMonitor for Prometheus
- ConfigMaps and Secrets management
- Volume management
- Health check endpoints
- Metrics endpoints

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.

