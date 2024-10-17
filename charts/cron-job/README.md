# CronJob

Installs the cron-job, a collection of kubernetes manifest for CronJob, Alerts, etc.

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

## configuration

| Inputs                  | Type    | Description                                                                                                                                                   | Default                              |
|-------------------------|---------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| appSecrets             | boolean | Boolean whether to mount csi secrets on the container                                                                                                         | `false`                              |
| concurrencyPolicy       | string  | Specify how to handle concurrent executions of the same job (allowed values are `Allow`, `Forbid` and `Replace`)                                              | `"Replace"`                          |
| env                     | map     | Environment Variables can be provided to the container                                                                                                        | `eg APP_NAME: hello-api`             |
| envFrom.configmaps      | list    | List of Configmaps from which env should be mounted on to containers                                                                                          | `[]`                                 |
| envFrom.secrets         | list    | List of secrets from which env should be mounted on to containers                                                                                             | `[]`                                 |
| image                   | string  | Docker container image with tag                                                                                                                               | `zopdev/sample-go-api:latest` |
| imagePullSecrets        | list    | configuration to specify secrets that contain credentials for pulling container images from private registries                                                | `[]`                                 |
| maxCPU                  | string  | Specify the maximum amount of CPU that the container is limited to use                                                                                        | `"500m"`                             |
| maxMemory               | string  | Specify the maximum amount of Memory that the container is limited to use                                                                                     | `"512Mi"`                            |
| metricsPort             | number  | Metrics port for scraping the metrics from container                                                                                                          | `2121`                               |
| minCPU                  | string  | Specify the minimum amount of CPU that the container requires                                                                                                 | `"250m"`                             |
| minMemory               | string  | Specify the minimum amount of Memory that the container requires                                                                                              | `"128Mi"`                            |
| name                    | string  | Name of the service                                                                                                                                           | `"hello-api"`                        |
| volumeMounts.configmaps | list    | List of Configmaps with name and mount-path to be mounted into the container to inject configuration data                                                     | `[]`                                 |
| volumeMounts.secrets    | list    | List of Secrets with name and mount-path to be mounted into the container to inject sensitive information                                                     | `[]`                                 |
| schedule                | string  | Schedule for executing a job repeatedly at specified intervals. Default schedule executes job `At minute 0 past every hour.`                                  | `0 */1 * * *`                        |
| suspend                 | boolean | Boolean whether to temporarily suspend the execution of scheduled jobs. This is useful when you need to pause the execution of a CronJob without deleting it. | `false`                              |
| volumeMounts.configmaps | list    | List of Configmaps with name and mount-path to be mounted into the container to inject configuration data                                                     | `[]`                                 |
| volumeMounts.pvc        | list    | List of Persistent Volume Claims with name and mount-path to be mounted into the container for bounding                                                       | `[]`                                 |
| volumeMounts.secrets    | list    | List of Secrets with name and mount-path to be mounted into the container to inject sensitive information                                                     | `[]`                                 |

####  ALERTS
All the listed values are related to the alerts.

##### Note:
1. The thresholds which has default values as `-1`, the alerts associated to that thresholds will not be created unless the thresholds are modified to a value greater than  `-1`.
2. Alerts can be disabled by modifying the threshold value of respective alert to `-1`.

| Inputs                                          | Type   | <div style="width:400px">Description</div>             | Default |
|-------------------------------------------------|--------|--------------------------------------------------------|---------|
| alerts.standard.infra.cronjob_restart_threshold | number | Alert if cronjob execution failed beyond the threshold | `0`     |

