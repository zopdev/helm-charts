# Mosquitto Helm Chart

The Mosquitto Helm chart enables the deployment of Eclipse Mosquitto, a lightweight MQTT message broker, in a Kubernetes cluster. Mosquitto is designed for IoT messaging and supports MQTT protocol versions 5.0, 3.1.1, and 3.1.

---

## Prerequisites

- Kubernetes 1.19+  
- Helm 3+  

---

## Add Helm Repository

Add the Helm repository to your local setup:

helm repo add zopdev https://helm.zop.dev
helm repo update

Refer to the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for more information.

---

## Install Helm Chart

To install the Mosquitto Helm chart, use the following command:

helm install [RELEASE_NAME] zopdev/mosquitto

Replace `[RELEASE_NAME]` with your desired release name. For example:

helm install my-mosquitto zopdev/mosquitto

To customize configurations, provide a `values.yaml` file or override values via the command line.

Refer to [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for more details.

---

## Uninstall Helm Chart

To uninstall the Mosquitto Helm chart and remove all associated Kubernetes resources, use the command:

helm uninstall [RELEASE_NAME]

For example:

helm uninstall my-mosquitto

See [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

Below is a summary of configurable parameters for the Mosquitto Helm chart:

| **Input**               | **Type**  | **Description**                                                    | **Default**                       |
|--------------------------|-----------|--------------------------------------------------------------------|-----------------------------------|
| `replicaCount`           | `integer` | Number of replicas for the Mosquitto deployment.                  | `1`                               |
| `image.repository`       | `string`  | Docker image repository for the Mosquitto container.              | `eclipse-mosquitto`               |
| `image.tag`              | `string`  | Docker image tag for the Mosquitto container.                     | `2.0.18`                          |
| `image.pullPolicy`       | `string`  | Image pull policy for the Mosquitto container.                    | `IfNotPresent`                    |
| `resources.requests.cpu` | `string`  | Minimum CPU resources required by the Mosquitto container.        | `"250m"`                          |
| `resources.requests.memory` | `string` | Minimum memory resources required by the Mosquitto container.     | `"500Mi"`                         |
| `resources.limits.cpu`   | `string`  | Maximum CPU resources the Mosquitto container can use.            | `"500m"`                          |
| `resources.limits.memory`| `string`  | Maximum memory resources the Mosquitto container can use.         | `"1000Mi"`                        |
| `diskSize`               | `string`  | Size of the persistent volume for Mosquitto data storage.         | `"10Gi"`                          |
| `service.port`           | `integer` | Port on which Mosquitto listens for MQTT connections.             | `1883`                            |
| `service.tlsPort`        | `integer` | Port on which Mosquitto listens for MQTT over TLS connections.    | `8883`                            |

You can override these values in a `values.yaml` file or via the command line during installation.

---

### Example `values.yaml` File

diskSize : "10Gi"

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

version: "1.0"

Apply the configuration file during installation:

helm install my-mosquitto zopdev/mosquitto -f values.yaml

---

## Features

- **Lightweight MQTT Broker:** Supports MQTT protocol versions 5.0, 3.1.1, and 3.1 for IoT messaging.
- **Authentication & Authorization:** Optional user authentication via Kubernetes Secrets.
- **TLS Support:** Secure MQTT connections using TLS encryption.
- **Persistent Storage:** Ensure data persistence using configurable persistent volumes.
- **Custom Configuration:** Deploy custom `mosquitto.conf` via ConfigMap.
- **Health Probes:** Built-in liveness and readiness probes for reliability.

---

## Advanced Usage

### Persistent Volume Configuration

Customize the persistent volume size and storage class for Mosquitto data:

diskSize: "50Gi"
persistence:
storageClass: "high-performance"

### Network Configuration

Specify the MQTT ports and service type:

service:
type: LoadBalancer
port: 1883
tlsPort: 8883

### Authentication Setup

Enable authentication and configure users:

auth:
enabled: true
users:
- username: admin
- username: client1

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.

---

## Connection Config

- **MQTT_HOST** : Hostname or service name for the Mosquitto MQTT broker.
- **MQTT_PORT** : Port number to connect to Mosquitto MQTT. Defaults to 1883.
- **MQTT_TLS_PORT** : Port number for secure MQTT connections. Defaults to 8883.

---