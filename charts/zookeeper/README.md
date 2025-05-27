# Zookeeper Helm Chart

This Helm chart deploys Apache Zookeeper, a distributed coordination service for distributed applications, on Kubernetes. Zookeeper provides a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Persistent volume provisioner for storage

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

To deploy the Zookeeper Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/zookeeper
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-zookeeper zopdev/zookeeper
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the Zookeeper Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-zookeeper
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The Zookeeper Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

### Image Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `image.registry`             | `string`  | Container registry for Zookeeper image.                                                        | `"docker.io"`        |
| `image.repository`           | `string`  | Container image repository.                                                                    | `"confluentinc/cp-zookeeper"` |
| `image.tag`                  | `string`  | Container image tag.                                                                          | `"7.8.0"`            |
| `image.pullPolicy`           | `string`  | Container image pull policy.                                                                  | `""`                 |
| `imagePullSecrets`           | `array`   | Image pull secrets.                                                                           | `[]`                 |

### Deployment Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `replicaCount`               | `integer` | Number of Zookeeper replicas.                                                                  | `3`                  |
| `minAvailable`               | `integer` | Minimum available replicas.                                                                    | `1`                  |
| `diskSize`                   | `string`  | Size of persistent volume.                                                                     | `"1Gi"`              |

### Resource Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `resources.requests.cpu`     | `string`  | CPU resource requests.                                                                         | `"100m"`             |
| `resources.requests.memory`  | `string`  | Memory resource requests.                                                                      | `"500Mi"`            |
| `resources.limits.cpu`       | `string`  | CPU resource limits.                                                                           | `"500m"`             |
| `resources.limits.memory`    | `string`  | Memory resource limits.                                                                        | `"1000Mi"`           |

### Zookeeper Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `tickTime`                   | `integer` | Basic time unit in milliseconds.                                                              | `2000`               |
| `initLimit`                  | `integer` | Time to sync followers with leader.                                                           | `10`                 |
| `syncLimit`                  | `integer` | Time to sync followers with leader.                                                           | `5`                  |
| `maxClientCnxns`             | `integer` | Maximum number of client connections.                                                         | `60`                 |
| `quorumListenOnAllIPs`       | `boolean` | Whether to listen on all IPs.                                                                  | `true`               |
| `maxSessionTimeout`          | `integer` | Maximum session timeout in milliseconds.                                                      | `40000`              |
| `adminEnableServer`          | `boolean` | Whether to enable admin server.                                                               | `true`               |
| `heapOpts`                   | `string`  | JVM heap options.                                                                             | `"-XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"` |
| `log4jRootLogLevel`          | `string`  | Log4j root log level.                                                                         | `"INFO"`             |

### Port Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `port.peers`                 | `integer` | Port for peer communication.                                                                   | `2888`               |
| `port.leader`                | `integer` | Port for leader election.                                                                      | `3888`               |
| `port.admin`                 | `integer` | Port for admin server.                                                                         | `8080`               |
| `port.client`                | `integer` | Port for client connections.                                                                   | `2181`               |

### Probe Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `livenessProbe.enabled`      | `boolean` | Whether to enable liveness probe.                                                             | `true`               |
| `readinessProbe.enabled`     | `boolean` | Whether to enable readiness probe.                                                            | `true`               |

---

## Example `values.yaml`

```yaml
image:
  registry: docker.io
  repository: confluentinc/cp-zookeeper
  tag: "7.8.0"
  pullPolicy:
imagePullSecrets:  []

replicaCount: 3
minAvailable: 1

livenessProbe:
  enabled: true
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 6
  successThreshold: 1

readinessProbe:
  enabled: true
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 6
  successThreshold: 1


podSecurityContext:
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsUser: 1000
  runAsGroup: 1000
  capabilities:
    drop:
      - ALL

resources:
  requests:
    cpu: "100m"
    memory: "500Mi"
  limits:
    cpu: "500m"
    memory: "1000Mi"

diskSize : 1Gi

## Zookeeper Configuration
tickTime: 2000
initLimit: 10
syncLimit: 5
maxClientCnxns: 60
autopurge:
  purgeInterval: 24
  snapRetainCount: 3
quorumListenOnAllIPs: true
maxSessionTimeout: 40000
adminEnableServer: true
heapOpts: "-XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"
log4jRootLogLevel: INFO

port:
  peers: 2888
  leader: 3888
  admin: 8080
  client: 2181
```

---

## Features

- Deploys Zookeeper with configurable replicas
- Automatic leader election
- Persistent storage for data
- Configurable resource limits and requests
- Health monitoring with liveness and readiness probes
- Security context configuration
- JVM heap optimization
- Log level configuration
- Admin server support
- Client connection management
- Snapshot and transaction log management

---

## Architecture

The Zookeeper deployment includes:
- Multiple Zookeeper pods for high availability
- Persistent volumes for data storage
- Leader election mechanism
- Health check endpoints
- Resource management
- Security context
- Network configuration for peer and client communication

---

## Security Features

- Pod security context
- Container security context
- Privilege escalation prevention
- Read-only root filesystem
- Capability restrictions
- Resource limits
- Network security
- Persistent volume security

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 