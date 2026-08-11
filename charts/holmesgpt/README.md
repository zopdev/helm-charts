# HolmesGPT Helm Chart

[HolmesGPT](https://holmesgpt.dev/) is an open-source SRE agent, a CNCF
sandbox project, that investigates production incidents by reading your
cluster and correlating it with your observability data. This chart
deploys it as an in-cluster HTTP API.

It wraps the chart HolmesGPT publishes rather than reimplementing it.
Upstream owns the parts that should not be duplicated — the CRDs, the
ClusterRole it needs to read a cluster, the operator, and the
per-integration MCP servers. This chart adds what the zop.dev platform
expects and upstream does not ship: a `values.schema.json` for the
settings UI, an ingress, and alerting rules.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3+
- An API key for a supported [AI provider](https://holmesgpt.dev/ai-providers/),
  or any OpenAI-compatible endpoint

---

## Dependencies

This chart depends on the upstream `holmes` chart. Download it before
installing from a checkout:

```bash
helm dependency build
```

This command will:
1. Read the dependencies from `Chart.yaml`
2. Download the `holmes` chart from `https://robusta-charts.storage.googleapis.com`
3. Store it in the `charts/` directory
4. Create or update the `Chart.lock` file with the exact version

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

The CRDs the upstream chart installs are not removed by `helm uninstall`,
which is Helm's behaviour for anything under `crds/`. Delete them by hand
if you want them gone.

---

## Configuration

Everything under `holmes` is passed to the upstream chart verbatim, so
any value it accepts can be set there — not only the ones given defaults
here.

| **Input** | **Type** | **Description** | **Default** |
|---|---|---|---|
| `holmes.modelList` | `object` | Models Holmes may use. Empty means it cannot investigate. | `{}` |
| `holmes.extraEnvVarsSecrets` | `array` | Existing Secrets mounted as env vars, which is how an `envRef:` credential reaches the pod. | `[]` |
| `holmes.replicas` | `int` | Number of replicas. | `1` |
| `holmes.resources` | `object` | CPU and memory. | 100m/2048Mi, limit 2048Mi |
| `holmes.autoscaling.enabled` | `bool` | Create an HPA. | `false` |
| `holmes.autoscaling.minReplicas` | `int` | Lower bound. | `1` |
| `holmes.autoscaling.maxReplicas` | `int` | Upper bound. | `5` |
| `holmes.autoscaling.targetCPU` | `string` | Target CPU utilisation. | `"60"` |
| `holmes.createServiceAccount` | `bool` | Create the ServiceAccount and ClusterRole Holmes reads the cluster with. | `true` |
| `ingress.enabled` | `bool` | Create an Ingress for the API. | `false` |
| `ingress.className` | `string` | IngressClass name. | `""` |
| `ingress.host` | `string` | Hostname. Required when the ingress is enabled. | `""` |
| `ingress.annotations` | `object` | Ingress annotations. | `{}` |
| `ingress.tlsSecretName` | `string` | Existing TLS secret for the host. | `""` |
| `alerts.enabled` | `bool` | Create the PrometheusRule. Needs the Prometheus Operator CRDs. | `true` |
| `alerts.unavailableReplicasThreshold` | `int` | Unavailable replicas tolerated. | `0` |
| `alerts.podRestartThreshold` | `int` | Restarts tolerated in the window. | `3` |
| `alerts.podRestartTimeWindow` | `string` | Window the restarts are counted over. | `"10m"` |

### Giving it a model

Keep the credential in a Secret and reference it, so it never passes
through values or a rendered manifest. `envRef:` is upstream's sugar for
"read this from the environment at runtime":

```bash
kubectl create secret generic holmes-llm-keys \
  --from-literal=ANTHROPIC_API_KEY=sk-ant-...

helm upgrade my-holmesgpt zopdev/holmesgpt --reuse-values \
  --set 'holmes.extraEnvVarsSecrets[0]=holmes-llm-keys' \
  --set holmes.modelList.claude.model=anthropic/claude-sonnet-4-20250514 \
  --set holmes.modelList.claude.api_key=envRef:ANTHROPIC_API_KEY
```

`extraEnvVarsSecrets` is the shorthand for mounting a whole Secret;
`holmes.additionalEnvVars` and `holmes.additional_env_froms` work too
when you need to remap a key or read from a ConfigMap. Any of them
satisfies an `envRef:`.

Referencing a key with `envRef:` while *none* of them supplies it is
rejected when the chart renders. That combination looks configured, but
nothing puts the key in the pod's environment, so it resolves to nothing
and every investigation fails on authentication rather than on the
missing credential.

Any OpenAI-compatible endpoint works, including one in the same cluster —
the `localai` chart in this repo serves that API, which keeps prompts
containing cluster state off the public internet:

```yaml
holmes:
  modelList:
    local:
      model: openai/qwen3-1.7b
      api_base: http://my-localai:8080/v1
      api_key: not-needed
```

### What it can see

Holmes reads cluster state to investigate, so the upstream chart creates
a ServiceAccount bound to a read-mostly ClusterRole. That is a broad
grant: narrow it with `holmes.customClusterRoleRules`, or set
`holmes.createServiceAccount=false` and bind your own.

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

There are also no stakater reloader annotations, and none are needed:
the upstream chart already hashes `modelList`, `toolsets` and the MCP
server config into the pod template, so changing a model through
`helm upgrade` rolls the pods on its own.

The PrometheusRule needs the Prometheus Operator CRDs. Turn it off on a
cluster without them:

```bash
helm install my-holmesgpt zopdev/holmesgpt --set alerts.enabled=false
```

---

## Example `values.yaml`

```yaml
holmes:
  replicas: 2
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
- ServiceAccount and read-mostly ClusterRole created for cluster investigation, narrowable or replaceable
- Optional HPA
- Ingress with optional TLS
- Alerting rules that hold through a rollout
- CRDs for scheduled and triggered health checks, from the upstream chart

---

## Architecture

The chart deploys:
- The HolmesGPT API (Deployment), serving HTTP on 5050 behind a Service on port 80
- A ServiceAccount with a ClusterRole and binding, used to read cluster state (dependency)
- A ConfigMap holding the toolset and model configuration (dependency)
- CRDs for health checks (dependency)
- Optional MCP server deployments for integrations such as AWS, GCP, GitHub (dependency, off by default)
- An Ingress and a PrometheusRule, added by this chart

A request to `/api/chat` is answered by the model in `modelList`, which
Holmes calls with the toolsets it has available — reading Kubernetes
objects, logs and events, plus whatever external sources are configured.

---

## Security Features

- LLM credentials supplied through an existing Secret and referenced with `envRef:`, so the key appears in no rendered manifest
- A model referencing a credential with no Secret mounted is rejected at render time
- The investigation ClusterRole is narrowable with `holmes.customClusterRoleRules`, or replaceable with your own ServiceAccount
- MCP server integrations ship NetworkPolicies (dependency)
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
