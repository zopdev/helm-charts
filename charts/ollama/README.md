# Ollama Helm Chart

[Ollama](https://github.com/ollama/ollama) runs LLMs (Llama 3, Mistral,
etc.) locally and serves them over a REST API. This chart deploys a
single Ollama server backed by a persistent volume for pulled models.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3+

---

## Add Helm Repository

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

---

## Install Helm Chart

```bash
helm install my-ollama zopdev/ollama
```

To pull one or more models automatically on first start:

```bash
helm install my-ollama zopdev/ollama \
  --set models={llama3,mistral}
```

Without `models` set, the server comes up with no models installed —
pull one afterwards with:

```bash
kubectl exec my-ollama-ollama-0 -- ollama pull llama3
```

---

## Uninstall Helm Chart

```bash
helm uninstall my-ollama
```

The PersistentVolumeClaim created from the volume template outlives the
release. Delete it separately to reclaim the disk:

```bash
kubectl delete pvc models-my-ollama-ollama-0
```

---

## Configuration

| **Input** | **Type** | **Description** | **Default** |
|---|---|---|---|
| `image.repository` | `string` | Container image. | `ollama/ollama` |
| `image.tag` | `string` | Image tag. | `0.32.9` |
| `image.pullPolicy` | `string` | Image pull policy. | `IfNotPresent` |
| `service.type` | `string` | Service type for the API. | `ClusterIP` |
| `service.port` | `int` | Service port for the API. | `11434` |
| `diskSize` | `string` | Size of the models volume. | `"20Gi"` |
| `resources` | `object` | CPU and memory for the pod. | 500m/2Gi – 2000m/4Gi |
| `models` | `list` | Models to pull automatically on first start. See *Model pulling* below. | `[]` |
| `nodeSelector` | `object` | Node labels to constrain scheduling. | `{}` |
| `tolerations` | `list` | Tolerations to allow scheduling onto tainted nodes. | `[]` |
| `env` | `object` | Extra environment variables. | `{}` |
| `ingress.enabled` | `bool` | Create an Ingress for the API. | `false` |
| `ingress.className` | `string` | IngressClass name. | `""` |
| `ingress.host` | `string` | Hostname. Required when the ingress is enabled. | `""` |
| `ingress.annotations` | `object` | Ingress annotations. | `{}` |
| `ingress.tlsSecretName` | `string` | Existing TLS secret for the host. | `""` |

### Model pulling

`models` is a plain list of model names, e.g. `["llama3", "mistral"]`.
When it's non-empty, an init container starts a throwaway Ollama server
against the same volume the main container uses, pulls each model in
order, then exits — the main container only starts once every model is
already on disk. Pulling several large models can take a while on first
install; there's no per-model timeout, so a stuck pull blocks the pod
from becoming Ready rather than serving a half-downloaded model.

Changing `models` on an existing release and running `helm upgrade`
pulls any newly-added models but does not remove ones taken off the
list — they stay on the volume until deleted manually.

### Running on GPU nodes

This chart adds no Ollama-specific GPU field. Target a GPU node pool the
same way as any other workload, through the generic `nodeSelector` and
`tolerations` passthrough, and request the GPU itself through
`resources.limits`:

```bash
helm install my-ollama zopdev/ollama \
  --set resources.limits."nvidia\.com/gpu"=1 \
  --set nodeSelector.cloud\\.google\\.com/gke-accelerator=nvidia-tesla-t4
```

Requires the appropriate device plugin (e.g. NVIDIA's) already installed
on the cluster.

---

## Example `values.yaml`

```yaml
models:
  - llama3
  - mistral

resources:
  requests:
    cpu: "2000m"
    memory: "8Gi"
  limits:
    cpu: "4000m"
    memory: "16Gi"

diskSize: "50Gi"

ingress:
  enabled: true
  className: nginx
  host: ollama.example.com
```

```bash
helm install my-ollama zopdev/ollama -f values.yaml
```

---

## Features

- Persistent model storage, so pulled models survive pod restarts
- Optional automatic model pulling on first start via `models`
- Generic `nodeSelector`/`tolerations` passthrough for targeting GPU nodes
- Ingress with optional TLS
- Configurations that cannot work (a bad ingress setup) are rejected when
  the chart renders, naming the cause, rather than installing and
  crash-looping

---

## Connection Config

The API is served on `service.port` (11434) of the `<release>-ollama`
service.

```bash
kubectl port-forward svc/my-ollama-ollama 11434:11434
curl http://localhost:11434/api/generate \
  -d '{"model": "llama3", "prompt": "hello"}'
```

- **`/api/generate`**, **`/api/chat`**, **`/api/embeddings`** — inference endpoints.
- **`/api/pull`** — pull a model over the API instead of `kubectl exec`.
- **`/api/tags`** — list models currently pulled.
- **`/`** — used for readiness/liveness; returns `Ollama is running`.

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the
[CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution
guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our
[Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please
review it for terms of use.
