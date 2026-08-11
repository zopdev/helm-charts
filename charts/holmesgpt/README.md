# HolmesGPT Helm Chart

[HolmesGPT](https://holmesgpt.dev/) is an open-source SRE agent, a CNCF
sandbox project, that investigates production incidents by reading your
cluster and correlating it with your observability data. This chart
deploys it as an in-cluster HTTP API.

The chart carries its own templates. The workloads follow what upstream
deploys, and the three `holmesgpt.dev` CRDs are vendored under `crds/`,
but the values, naming and structure are this repo's rather than
upstream's — which is what lets the settings UI describe them, and what
keeps an upstream value rename from silently changing our surface.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3+
- An API key for a supported [AI provider](https://holmesgpt.dev/ai-providers/),
  or any OpenAI-compatible endpoint

---

## Dependencies

None. The chart deploys HolmesGPT directly and needs no subcharts, so
there is nothing to `helm dependency build` before installing from a
checkout.

It does need an LLM, which is not a chart dependency: any supported AI
provider, or any OpenAI-compatible endpoint — including the `localai`
chart in this repo.

---

## Add Helm Repository

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

---

## Install Helm Chart

```bash
helm install my-holmesgpt zopdev/holmesgpt
```

That deploys the API, but **nothing is configured by default and it
cannot investigate anything until it has a model.** There is no sensible
default to pick: the model and the credential are yours to choose. See
*Giving it a model* below.

---

## Uninstall Helm Chart

```bash
helm uninstall my-holmesgpt
```

The CRDs are not removed by `helm uninstall`,
which is Helm's behaviour for anything under `crds/`. Delete them by hand
if you want them gone.

---

## Configuration

| **Input** | **Type** | **Description** | **Default** |
|---|---|---|---|
| `image.repository` | `string` | Image repository. | `"robustadev/holmes"` |
| `image.tag` | `string` | Image tag. | `"0.39.0"` |
| `image.pullPolicy` | `string` | When the kubelet pulls the image. | `"IfNotPresent"` |
| `replicaCount` | `integer` | Number of API replicas. Ignored when autoscaling is enabled. | `1` |
| `modelList` | `object` | Models Holmes may use. Empty means it cannot investigate. Prefix a credential with `envRef:` to read it from a mounted Secret. | `{}` |
| `extraEnvVarsSecrets` | `array` | Existing Secrets loaded as environment variables, which is how an `envRef:` credential reaches the pod. | `[]` |
| `env` | `object` | Plain environment variables, for anything that is not a credential. | `{}` |
| `toolsets` | `object` | Data sources Holmes may use. Those beyond the defaults need credentials. | `{}` |
| `logLevel` | `string` | Log verbosity. | `"INFO"` |
| `service.type` | `string` | Kubernetes Service type. | `"ClusterIP"` |
| `service.port` | `integer` | Port the API is served on. | `80` |
| `resources.requests.cpu` | `string` | CPU request. | `"100m"` |
| `resources.requests.memory` | `string` | Memory request. | `"2048Mi"` |
| `resources.limits.memory` | `string` | Memory limit. | `"2048Mi"` |
| `autoscaling.enabled` | `boolean` | Create a HorizontalPodAutoscaler. | `false` |
| `autoscaling.minReplicas` | `integer` | Lower bound. | `1` |
| `autoscaling.maxReplicas` | `integer` | Upper bound. | `5` |
| `autoscaling.targetCPUUtilizationPercentage` | `integer` | Target CPU utilisation. | `60` |
| `rbac.create` | `boolean` | Create the ServiceAccount, ClusterRole and binding. | `true` |
| `rbac.serviceAccountName` | `string` | Existing ServiceAccount to use when create is false. | `""` |
| `rbac.extraRules` | `array` | Additional ClusterRole rules. | `[]` |
| `ingress.enabled` | `boolean` | Create an Ingress. | `false` |
| `ingress.className` | `string` | IngressClass to use. | `""` |
| `ingress.host` | `string` | Hostname. Required when the ingress is enabled. | `""` |
| `ingress.annotations` | `object` | Annotations applied to the Ingress. | `{}` |
| `ingress.tlsSecretName` | `string` | Existing TLS secret for the host. | `""` |
| `alerts.enabled` | `boolean` | Create the PrometheusRule. | `true` |
| `alerts.unavailableReplicasThreshold` | `integer` | Unavailable replicas tolerated before alerting. | `0` |
| `alerts.podRestartThreshold` | `integer` | Restarts tolerated in the window below. | `3` |
| `alerts.podRestartTimeWindow` | `string` | Window the restart count is measured over. | `"10m"` |

### Giving it a model

Keep the credential in a Secret and reference it, so it never passes
through values or a rendered manifest. `envRef:` means
"read this from the environment at runtime":

```bash
kubectl create secret generic holmes-llm-keys \
  --from-literal=ANTHROPIC_API_KEY=sk-ant-...

helm upgrade my-holmesgpt zopdev/holmesgpt --reuse-values \
  --set 'extraEnvVarsSecrets[0]=holmes-llm-keys' \
  --set modelList.claude.model=anthropic/claude-sonnet-4-20250514 \
  --set modelList.claude.api_key=envRef:ANTHROPIC_API_KEY
```

`extraEnvVarsSecrets` mounts whole Secrets; `env` sets plain
variables for anything that is not a credential. Either satisfies an
`envRef:`.

Referencing a key with `envRef:` while *none* of them supplies it is
rejected when the chart renders. That combination looks configured, but
nothing puts the key in the pod's environment, so it resolves to nothing
and every investigation fails on authentication rather than on the
missing credential.

Any OpenAI-compatible endpoint works, including one in the same cluster —
the `localai` chart in this repo serves that API, which keeps prompts
containing cluster state off the public internet:

```yaml
extraEnvVarsSecrets:
  - holmes-llm-keys        # holds LOCALAI_API_KEY
modelList:
  local:
    model: openai/qwen3-1.7b
    api_base: http://my-localai:8080/v1
    api_key: envRef:LOCALAI_API_KEY
```

### What it can see

Holmes reads cluster state to investigate, so this chart creates a
ServiceAccount bound to a read-mostly ClusterRole covering workloads,
events, logs, metrics and the CRDs of operators it knows about. That is
a broad grant: add to it with `rbac.extraRules`, or set
`rbac.create=false` with `rbac.serviceAccountName` to bind a narrower
role of your own — at the cost of Holmes being blind to what you leave
out.

Its answers are only as good as its data sources. Of the 42 toolsets
shipped, roughly 10 enable themselves from in-cluster access alone; the
rest need credentials for Prometheus, Datadog, GitHub and so on. See
[data sources](https://holmesgpt.dev/data-sources/).

### Observability

`alerts.enabled` renders a PrometheusRule with three rules —
unavailable replicas, scaled-to-zero, and pod restarts — each guarded so
a rollout does not fire them.

**There is no ServiceMonitor, deliberately.** The server exposes
`/api/chat`, `/api/model`, `/api/info`, `/healthz` and `/readyz`, and no
Prometheus endpoint. A ServiceMonitor pointed at it would be a
permanently failing scrape target that looks configured, so the alerts
above read kube-state-metrics instead.

There are no stakater reloader annotations, and none are needed: the
config ConfigMap is hashed into the pod template, so changing a model
through `helm upgrade` rolls the deployment on its own.

The PrometheusRule needs the Prometheus Operator CRDs. Turn it off on a
cluster without them:

```bash
helm install my-holmesgpt zopdev/holmesgpt --set alerts.enabled=false
```

---

## Example `values.yaml`

```yaml
replicaCount: 2

extraEnvVarsSecrets:
  - holmes-llm-keys

modelList:
  claude-sonnet:
    model: anthropic/claude-sonnet-4-20250514
    api_key: envRef:ANTHROPIC_API_KEY
    temperature: 0

resources:
  requests:
    cpu: "500m"
    memory: "2048Mi"
  limits:
    memory: "4096Mi"

ingress:
  enabled: true
  className: nginx
  host: holmes.example.com

alerts:
  enabled: true
```

```bash
helm install my-holmesgpt zopdev/holmesgpt -f values.yaml
```

---

## Features

- Deploys HolmesGPT as an in-cluster HTTP API for custom integrations
- Works with any supported AI provider, or any OpenAI-compatible endpoint including one inside the cluster
- Credentials referenced from an existing Secret, never written into values
- Half-configured credentials rejected when the chart renders rather than at the first investigation
- ServiceAccount and read-mostly ClusterRole created for cluster investigation, extendable with `rbac.extraRules` or replaceable entirely
- Optional HPA
- Ingress with optional TLS
- Alerting rules that hold through a rollout
- CRDs for scheduled and triggered health checks, vendored under `crds/`

---

## Architecture

The chart deploys:
- The HolmesGPT API (Deployment), serving HTTP on 5050 behind a Service
- A ConfigMap holding the toolset and model configuration, hashed into the pod template so a model change actually rolls the pods
- A ServiceAccount, ClusterRole and binding used to read cluster state
- Three `holmesgpt.dev` CRDs for health checks, vendored under `crds/`
- Optionally an Ingress, an HPA, and a PrometheusRule

A request to `/api/chat` is answered by the model in `modelList`, which
Holmes calls with the toolsets it has available — reading Kubernetes
objects, logs and events, plus whatever external sources are configured.

---

## Security Features

- LLM credentials supplied through an existing Secret and referenced with `envRef:`, so the key appears in no rendered manifest
- A model referencing a credential with no Secret mounted is rejected at render time
- The investigation ClusterRole is narrowable with `rbac.extraRules`, or replaceable with your own ServiceAccount
- Ingress TLS from an existing certificate secret

Worth weighing before exposing this: `/api/chat` is unauthenticated by
default (`auth_enabled: false` in `/api/info`), and anyone who can reach
it can ask the agent about your cluster and spend your LLM budget. Keep
it in-cluster, or put authentication in front of the ingress.

---

## Connection Config

The API is served on port 80 of the `<release>-holmes` service.

```bash
kubectl port-forward svc/my-holmesgpt-holmes 8080:80
curl http://localhost:8080/api/info
```

- **`/api/chat`** : ask a question, the main entry point.
- **`/api/model`** : which models are configured.
- **`/api/info`** : version, auth status, and a toolset summary.
- **`/healthz`**, **`/readyz`** : liveness and readiness.

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
