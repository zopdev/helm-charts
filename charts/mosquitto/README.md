# Mosquitto Helm Chart

The Mosquitto Helm chart enables the deployment of Eclipse Mosquitto, a lightweight MQTT message broker, in a Kubernetes cluster. Mosquitto is designed for IoT messaging and supports MQTT protocol versions 5.0, 3.1.1, and 3.1.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3+

---

## Add Helm Repository

Add the Helm repository to your local setup:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

Refer to the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/) for more information.

---

## Install Helm Chart

To install the Mosquitto Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/mosquitto
```

Replace `[RELEASE_NAME]` with your desired release name. For example:

```bash
helm install my-mosquitto zopdev/mosquitto
```

To customize configurations, provide a `values.yaml` file or override values via the command line.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for more details.

---

## Uninstall Helm Chart

To uninstall the Mosquitto Helm chart and remove all associated Kubernetes resources, use the command:

```bash
helm uninstall [RELEASE_NAME]
```

For example:

```bash
helm uninstall my-mosquitto
```

See the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for additional details.

---

## Configuration

Below is a summary of configurable parameters for the Mosquitto Helm chart:

| Input | Type | Description | Default |
| --- | --- | --- | --- |
| `version` | string | Eclipse Mosquitto image version. | `2.0.18` |
| `disk_size` | string | Size of the persistent volume for Mosquitto data. | `10Gi` |
| `auth.enabled` | boolean | Enable password authentication. | `true` |
| `auth.users` | list | List of usernames to create (passwords auto-generated). | `[admin]` |
| `service.type` | string | Kubernetes Service type (ClusterIP, LoadBalancer, NodePort). | `ClusterIP` |
| `tls.enabled` | boolean | Enable TLS encryption (requires existing secret). | `false` |
| `tls.cert_secret` | string | Name of the Kubernetes Secret containing TLS certs. | `mosquitto-tls-secret` |
| `resources.requests.cpu` | string | Minimum CPU resources required. | `50m` |
| `resources.requests.memory` | string | Minimum memory resources required. | `64Mi` |
| `resources.limits.cpu` | string | Maximum CPU resources allowed. | `100m` |
| `resources.limits.memory` | string | Maximum memory resources allowed. | `128Mi` |

You can override these values in a `values.yaml` file or via the command line during installation.

---

## Example `values.yaml` File

```yaml
disk_size: "20Gi"

version: "2.0.18"

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

service:
  type: LoadBalancer
```

Apply the configuration file during installation:

```bash
helm install my-mosquitto zopdev/mosquitto -f values.yaml
```

---

## Features

- Lightweight MQTT broker supporting MQTT 5.0, 3.1.1, and 3.1.
- Authentication and authorization via Kubernetes Secrets.
- TLS support for secure MQTT connections.
- Persistent storage through StatefulSet volume claims.
- Built-in liveness and readiness probes for high availability.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.

---

## Connection Config

- `MQTT_HOST`: Service name for the Mosquitto broker.
- `MQTT_PORT`: Port number (default: 1883).
- `MQTT_TLS_PORT`: Secure port number (default: 8883).
- `MQTT_USERNAME`: Admin username (retrieved from Secret).
- `MQTT_PASSWORD`: Admin password (retrieved from Secret).

---