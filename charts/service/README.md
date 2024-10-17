# Service 

Installs the service, a collection of kubernetes manifest for Deployment, Services, HPA, PDB, ServiceMonitor, Alerts, etc.

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

# Configuration

| Inputs                             | Type    | Description                                                                                                         | Default                              |
|------------------------------------|---------|---------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| appSecrets                        | boolean | Boolean whether to mount csi secrets on the container                                                               | `false`                              |
| cliService                         | boolean | Whether application is a CLI service                                                                                | `false`                              |
| env                                | map     | Environment Variables can be provided to the container                                                              | `eg APP_NAME: hello-api`             |
| envFrom.configmaps                 | list    | List of Configmaps from which env should be mounted on to containers                                                | `[]`                                 |
| envFrom.secrets                    | list    | List of secrets from which env should be mounted on to containers                                                   | `[]`                                 |
| heartbeatURL                       | string  | Heartbeat URL of the service                                                                                        | `""`                                 |
| httpPort                           | number  | HTTP Port on which container runs its services                                                                      | `8000`                               |
| image                              | string  | Docker container image with tag                                                                                     | `zopdev/sample-go-api:latest` |
| imagePullSecrets                   | list    | configuration to specify secrets that contain credentials for pulling container images from private registries      | `[]`                                 |
| livenessProbe.enable               | boolean | Whether liveness Probe should be configured on the container or not                                                 | `false`                              |
| livenessProbe.initialDelaySeconds  | number  | Specifies how long Kubernetes should wait after the container starts before it begins liveness probes (in seconds)  | `3`                                  |
| livenessProbe.timeoutSeconds       | number  | Specifies the number of seconds after which the probe times out                                                     | `3`                                  |
| livenessProbe.periodSeconds        | number  | Specifies how often (in seconds) to perform the liveness probe                                                      | `10`                                 |
| livenessProbe.failureThreshold     | number  | Specifies the number of consecutive failures needed to mark the probe as failed                                     | `3`                                  |
| maxCPU                             | string  | Specify the maximum amount of CPU that the container is limited to use                                              | `"500m"`                             |
| maxMemory                          | string  | Specify the maximum amount of Memory that the container is limited to use                                           | `"512Mi"`                            |
| maxReplicas                        | number  | Specify maximum number of pod replicas that the autoscaler can scale up to in response to increased load            | `4`                                  |
| metricsPort                        | number  | Metrics port for scraping the metrics from container                                                                | `2121`                               |
| metricsScrapeInterval              | string  | Time interval that metrics will be scraped                                                                          | `"30s"`                              |
| minAvailable                       | number  | Minimum number of pods that must be available during voluntary disruptions                                          | `1`                                  |
| minCPU                             | string  | Specify the minimum amount of CPU that the container requires                                                       | `"250m"`                             |
| minMemory                          | string  | Specify the minimum amount of Memory that the container requires                                                    | `"128Mi"`                            |
| minReplicas                        | number  | Specify the baseline number of identical pods allowed to be running                                                 | `2`                                  |
| name                               | string  | Name of the service                                                                                                 | `"hello-api"`                        |
| ports                              | map     | Provide the ports on which container runs its services                                                              | `null`                               |
| readinessProbe.enable              | boolean | Whether Readiness Probe should be configured on the container or not                                                | `false`                              |
| readinessProbe.initialDelaySeconds | number  | Specifies how long Kubernetes should wait after the container starts before it begins readiness probes (in seconds) | `3`                                  |
| readinessProbe.timeoutSeconds      | number  | Specifies the number of seconds after which the probe times out                                                     | `3`                                  |
| readinessProbe.periodSeconds       | number  | Specifies how often (in seconds) to perform the readiness probe                                                     | `10`                                 |
| readinessProbe.failureThreshold    | number  | Specifies the number of consecutive failures needed to mark the probe as failed                                     | `3`                                  |
| replicaCount                       | number  | Number of replicas to run                                                                                           | `2`                                  |
| volumeMounts.configmaps            | list    | List of Configmaps with name and mount-path to be mounted into the container to inject configuration data           | `[]`                                 |
| volumeMounts.pvc                   | list    | List of Persistent Volume Claims with name and mount-path to be mounted into the container for bounding             | `[]`                                 |
| volumeMounts.secrets               | list    | List of Secrets with name and mount-path to be mounted into the container to inject sensitive information           | `[]`                                 |


### ALERTS
##### Note:
1. The thresholds which has default values as `-1`, the alerts associated to that thresholds will not be created unless the thresholds are modified to a value greater than  `-1`.
2. Alerts can be disabled by modifying the threshold value of respective alert to `-1`.


| Inputs                                                                    | Type             | <div style="width:400px">Description</div>                                                                                                | Default      |
|---------------------------------------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| alerts.custom                                                             | list             | For creating the custom alerts you can refer the below table values. It takes the list of values as inputs                                | `[]`         |
| alerts.standard.infra.healthCheckFailureThreshold                      | optional(number) | Alert if  application health-check failures goes beyond 50 in a 5-minute window                                                           | `50`         |
| alerts.standard.infra.healthCheckFailureTimeWindow                    | optional(string) | Time window for health check failure                                                                                                      | `"5m"`       |
| alerts.standard.infra.hpaNearingMaxPodThreshold                       | optional(number) | Alert if replica count crosses the threshold percentage of max pod count                                                                  | `80`         |
| alerts.standard.infra.podRestartThreshold                               | optional(number) | Alert if the pod restarts goes beyond threshold over a 5-minute window                                                                    | `0`          |
| alerts.standard.infra.podRestartTimeWindow                             | optional(string) | Time window for pod restart                                                                                                               | `"5m"`       |
| alerts.standard.infra.serviceMemoryUtilizationThreshold                | optional(number) | Alert if service memory utilization exceeds threshold                                                                                     | `90`         |
| alerts.standard.infra.serviceCpuUtilizationThreshold                   | optional(number) | Alert if service cpu utilization exceeds threshold                                                                                        | `90`         |
| alerts.standard.infra.serviceCpuUtilizationTimeWindow                 | optional(string) | Time window for service cpu utilization                                                                                                   | `"5m"`       |
| alerts.standard.infra.unavailableReplicasThreshold                      | optional(number) | Alert if the available replicas is lesser than number of desired replicas                                                                 | `0`          |

#### `custom-alerts`

| Inputs          | Type             | Description                                                                                     | Default |
|-----------------|------------------|-------------------------------------------------------------------------------------------------|---------|
| alertRule      | optional(string) | Metric Name exposed by /metric endpoint (eg. "user_post_get_counter")                           | nil     |
| description     | optional(string) | Description of custom alert (eg. "alert if user_created events goes below threshold for 5 min") | `""`    |
| labelValue     | optional(string) | Metric Event Name (eg. "user_created")                                                          | `""`    |
| labels.severity | optional(string) | Severity for the alert (eg. "critical" or "warning")                                            | `""`    |
| name            | string           | Name of the alert (eg. "custom alert if user_created events goes below threshold for 5 min")    | `""`    |
| percentile      | optional(number) | Percentile is useful for histogram queries (eg. 0.99 percentile)                                | `0.0`   |
| queryOperator  | optional(string) | Query Operator to compare the thresholds values                                                 | `>`     |
| sumByLabel    | optional(string) | Metric events key (eg. "events")                                                                | `""`    |
| timeWindow     | optional(string) | Time window for the custom alerts                                                               | `""`    |
| threshold       | optional(number) | Threshold value for custom alerts                                                               | `""`    |


