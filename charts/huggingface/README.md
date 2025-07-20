# HuggingFace TGI Helm Chart

This Helm chart deploys [Hugging Face Text Generation Inference (TGI)](https://github.com/huggingface/text-generation-inference) on Kubernetes. It is designed for running large language models (LLMs) with optimized serving and autoscaling.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- NVIDIA GPU support (for GPU-based deployments)
- `nvidia-device-plugin` installed (for GPU scheduling)

---

## Add Helm Repository

Add the Helm repository by running:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

---

## Install Helm Chart

To install the chart with default values:

```bash
helm install huggingface zopdev/huggingface
```

To install with custom values:

```bash
helm install huggingface zopdev/huggingface -f values.yaml
```

---

## Uninstall Helm Chart

```bash
helm uninstall huggingface
```

---

## Configuration

The following table lists the configurable parameters of the HuggingFace chart:

| **Parameter**              | **Type**  | **Description**                                                             | **Default**                              |
|----------------------------|-----------|-----------------------------------------------------------------------------|------------------------------------------|
| `image.repository`         | string    | Docker image repository                                                     | `ghcr.io/huggingface/text-generation-inference` |
| `image.tag`                | string    | Image tag                                                                   | `latest`                                 |
| `replicaCount`             | int       | Number of replicas                                                          | `1`                                      |
| `service.port`             | int       | Service port                                                                | `80`                                     |
| `model.id`                 | string    | Model ID to serve                                                           | `gpt2`                                   |
| `resources.limits.gpu`     | string    | GPU limits (e.g., `1` for 1 GPU)                                            | `1`                                      |
| `autoscaling.enabled`      | bool      | Enable Horizontal Pod Autoscaler                                           | `false`                                  |
| `ingress.enabled`          | bool      | Enable ingress                                                              | `false`                                  |
| `ingress.hosts`            | list      | List of ingress hosts                                                       | `[]`                                     |

---

## Example `values.yaml`

```yaml
image:
  repository: ghcr.io/huggingface/text-generation-inference
  tag: latest

replicaCount: 1

model:
  id: gpt2

resources:
  limits:
    nvidia.com/gpu: 1
  requests:
    cpu: "500m"
    memory: "2Gi"

autoscaling:
  enabled: false

ingress:
  enabled: false

service:
  type: ClusterIP
  port: 80
```

---

## Alerts

Prometheus-compatible alert included:

- **HuggingFaceDown**: Triggers when no instances are available for 1 minute.

---

## Features

- Deploy Hugging Face TGI inference server
- GPU support via NVIDIA plugin
- Configurable model loading
- Autoscaling via HPA
- Prometheus alerts and ServiceMonitor
- Ingress support
- Secure credential templating

---

## Architecture

This chart deploys the following components:

- TGI Deployment
- Kubernetes Service
- Optional Ingress resource
- HPA (if enabled)
- Prometheus ServiceMonitor
- Optional alert rules (e.g., HuggingFaceDown)
- Credential file templating via `huggingface-login.yaml`

---

## Security Features

- Container resource limits
- Pod security context
- Optional ingress security
- Credential secrets managed securely
- Cloud metadata blocking recommended

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.
