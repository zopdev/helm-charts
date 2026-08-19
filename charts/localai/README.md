# LocalAI Helm Chart

<p align="center">
  <a href="https://zop.dev/zopday/app/deploy?install=localai"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday"></a>
</p>

[LocalAI](https://github.com/mudler/LocalAI) is a drop-in replacement for
the OpenAI API that runs models on your own hardware. This chart deploys
it in either of two topologies, chosen with a single value.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3+

---

## Dependencies

This chart depends on the zopdev `postgres` chart and the upstream `nats`
chart, both of which the distributed topology requires. Download them
before installing from a checkout:

```bash
helm dependency build
```

This command will:
1. Read the dependencies from `Chart.yaml`
2. Download the required charts (PostgreSQL and NATS) from the specified repositories
3. Store them in the `charts/` directory
4. Create or update the `Chart.lock` file with the exact versions

Neither is installed unless you ask for it: both are conditional on
`postgres.enabled` and `nats.enabled`, which default to `false`, so the
standalone topology deploys nothing but LocalAI itself.

---

## Add Helm Repository

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

---

## Install Helm Chart

### Standalone (default)

One pod serves the API and runs the model itself. Nothing else is
installed.

```bash
helm install my-localai zopdev/localai
```

### Distributed

Stateless API frontends route inference to a pool of workers. Shared
state lives in PostgreSQL and coordination happens over NATS, both of
which this chart can install for you:

```bash
helm install my-localai zopdev/localai \
  --set distributed.enabled=true \
  --set postgres.enabled=true \
  --set nats.enabled=true \
  --set distributed.worker.replicaCount=3
```

`postgres.enabled` and `nats.enabled` are separate switches because
Helm evaluates subchart conditions against their own values path. Both
default to `false` so a standalone install stays self-contained. Turning
on `distributed.enabled` without a database or a NATS server is rejected
at template time with a message saying which one is missing, rather than
installing and then crash-looping.

To scale the pool later, raise the worker count:

```bash
helm upgrade my-localai zopdev/localai --reuse-values \
  --set distributed.worker.replicaCount=6
```

---

## Uninstall Helm Chart

```bash
helm uninstall my-localai
```

PersistentVolumeClaims created from volume templates outlive the
release. Delete them separately to reclaim the disks.

---

## Configuration

| **Input** | **Type** | **Description** | **Default** |
|---|---|---|---|
| `image.repository` | `string` | Container image. | `localai/localai` |
| `image.tag` | `string` | Image tag. See *Image tag* below. | `master` |
| `image.pullPolicy` | `string` | Image pull policy. | `IfNotPresent` |
| `distributed.enabled` | `bool` | Topology switch: `false` standalone, `true` distributed. | `false` |
| `distributed.frontend.replicaCount` | `int` | API frontends. See *Scaling frontends*. | `1` |
| `distributed.frontend.existingClaim` | `string` | Existing ReadWriteMany claim to mount as the models directory on every frontend. | `""` |
| `distributed.worker.replicaCount` | `int` | Inference workers. | `2` |
| `distributed.worker.diskSize` | `string` | Models disk per worker. | `"10Gi"` |
| `distributed.worker.existingClaim` | `string` | Existing ReadWriteMany claim to mount as the models directory on every worker, instead of a disk each. | `""` |
| `distributed.worker.resources` | `object` | CPU and memory per worker. | 500m/2Gi – 2000m/4Gi |
| `distributed.autoApproveNodes` | `bool` | Admit workers on registration instead of holding them for admin approval. | `true` |
| `distributed.adminEmail` | `string` | Account that gets the admin role. Empty means the first to register wins it. | `""` |
| `distributed.registrationMode` | `string` | `open`, `approval`, or `invite`. | `"open"` |
| `distributed.registrationToken` | `string` | Token authenticating worker registration. Generated when empty. | `""` |
| `distributed.sharedModels` | `bool` | Skip staging model files to workers. See *Shared models volume*. | `false` |
| `service.type` | `string` | Service type for the API. | `ClusterIP` |
| `service.port` | `int` | Service port for the API. | `8080` |
| `diskSize` | `string` | Models disk for the standalone pod / each frontend. | `"10Gi"` |
| `resources` | `object` | CPU and memory for the standalone pod / each frontend. | 500m/2Gi – 2000m/4Gi |
| `env` | `object` | Extra environment variables for every LocalAI pod. | `{}` |
| `ingress.enabled` | `bool` | Create an Ingress for the API. | `false` |
| `ingress.className` | `string` | IngressClass name. | `""` |
| `ingress.host` | `string` | Hostname. Required when the ingress is enabled. | `""` |
| `ingress.annotations` | `object` | Ingress annotations. | `{}` |
| `ingress.tlsSecretName` | `string` | Existing TLS secret for the host. | `""` |
| `postgres.enabled` | `bool` | Install PostgreSQL with the release (distributed only). | `false` |
| `externalDatabase.url` | `string` | Use an existing PostgreSQL instead. | `""` |
| `nats.enabled` | `bool` | Install NATS with the release (distributed only). | `false` |
| `metrics.enabled` | `bool` | Render a ServiceMonitor scraping `/metrics`. Needs the Prometheus Operator CRDs. | `true` |
| `metrics.scrapeInterval` | `string` | Scrape interval. | `"30s"` |
| `alerts.enabled` | `bool` | Render the `LocalAIDown` PrometheusRule. Needs the Prometheus Operator CRDs. | `true` |
| `externalNats.url` | `string` | Use an existing NATS instead. | `""` |

### Image tag

The default tag is `master`, not a release. Distributed mode relies on
the `worker` subcommand and the `--distributed` flag, which no tagged
release ships yet (latest is `v3.12.1`). Pin a released tag if you only
ever run standalone:

```bash
helm install my-localai zopdev/localai --set image.tag=v3.12.1
```

### Scaling frontends

Frontends share their state through PostgreSQL, so any of them can serve
any request — with one exception. Model *files* live on the frontend's
own disk, and the router stages them from there to the workers. With the
per-replica disks this chart creates by default, a model installed
through one frontend is invisible to the others.

So `distributed.frontend.replicaCount` defaults to `1`. To run more,
give them one shared models volume:

```bash
helm install my-localai zopdev/localai \
  --set distributed.enabled=true \
  --set postgres.enabled=true --set nats.enabled=true \
  --set distributed.frontend.replicaCount=3 \
  --set distributed.frontend.existingClaim=localai-models-rwx
```

Worker count carries the inference capacity and has no such constraint.

### Sizing worker disks

`distributed.worker.diskSize` is not only capacity. Model weights are
staged onto a worker's disk before its backend loads them, and the
router **drops any worker whose models filesystem cannot hold the
model** — its on-disk size plus 5%, at least 1 GiB — before it places
anything. A worker sized below your largest model is never scheduled for
it, and if no worker clears the bar the request fails immediately naming
the shortfall:

```
scheduling <model>: no node has enough free disk for the model:
need 73.5 GB free on the models filesystem, but worker-0 has 4.1 GB free of 10.0 GB
```

The default `10Gi` suits small quantised models. Raise it to your
largest model plus headroom.

Note that this will not show up on minikube or any other hostPath
provisioner: those do not enforce a claim's size, so `df` inside the pod
reports the whole node disk and every model looks placeable. Storage
that provisions a real device — EBS, PD, most CSI drivers — enforces it.

### A reporting quirk on memory-limited pods

Where a pod has a memory limit, a worker's `total_ram` follows the
cgroup limit while `available_ram` is read from `/proc/meminfo`, which
is not namespaced. The Nodes page can therefore show a worker with more
memory *available* than it has in *total*. It is confusing rather than
harmful: placement is decided by free VRAM, disk headroom and how many
models a node already holds, none of which read that field.

### Shared models volume

By default each worker keeps its own disk, and the router copies a
model's files to a worker over HTTP before loading it. If every pod
instead mounts one ReadWriteMany volume, those files are already on the
worker at the path the frontend would stage them to, and the copy is
wasted work that reads as a re-download of a model you already have.

`distributed.sharedModels` tells the router to skip it. It is an
assertion about your storage, so the chart only accepts it when the
frontends and workers really do share one claim:

```bash
helm install my-localai zopdev/localai \
  --set distributed.enabled=true \
  --set postgres.enabled=true --set nats.enabled=true \
  --set distributed.frontend.existingClaim=localai-models-rwx \
  --set distributed.worker.existingClaim=localai-models-rwx \
  --set distributed.sharedModels=true
```

Setting it with per-pod disks, or with two different claims, is rejected
at template time rather than silently failing every model load.

### Switching topology on an existing release

`distributed.enabled` can be flipped either way with `helm upgrade`, in
place. Going distributed converts the existing pod into a frontend and
adds the workers; going back removes the workers, their headless
service, and the registration token. The API service keeps its name and
the models volume is preserved across both.

One caveat, and it is about PostgreSQL rather than the topology. Do not
turn `postgres.enabled` off and on again:

```bash
# Fine — leaves PostgreSQL installed and idle.
helm upgrade my-localai zopdev/localai --reuse-values \
  --set distributed.enabled=false

# Wedges the database.
helm upgrade my-localai zopdev/localai --reuse-values \
  --set distributed.enabled=false --set postgres.enabled=false
```

Disabling it deletes the Secret holding the generated password but not
the PersistentVolumeClaim holding the data. Re-enabling generates a new
password, which does not open the existing volume, and the database
never comes up: the `postgres-*-init-job` pod fails repeatedly and the
frontend waits on credentials that will never work. Leave PostgreSQL
enabled for the life of the release.

Recovering means re-provisioning the database from scratch, which is
four steps rather than one — the volume, the pod that seeds the user,
and the wedged frontend pod all have to go:

```bash
kubectl delete statefulset <release>-postgres
kubectl delete pvc ai-persistent-storage-<release>-postgres-0
kubectl delete pod postgres-<release>-localai-init-job
helm upgrade <release> zopdev/localai --reuse-values
kubectl delete pod <release>-localai-0
```

The last step is not redundant. A StatefulSet rolling update will not
replace a pod that has never become Ready, so the wedged frontend keeps
running its old spec until it is deleted by hand.

### Observability

**Metrics.** LocalAI serves Prometheus metrics on `/metrics` on the API
port, on by default. The application family is `api_call`, a request
latency histogram labelled by method and path, alongside Go runtime
metrics. `metrics.enabled` renders a ServiceMonitor for the API tier.
Workers are not scraped: their HTTP port serves file transfer and the
health probes, not metrics.

In distributed mode authentication covers every endpoint, `/metrics`
included, so an unauthenticated scrape would be a permanently failing
target rather than a missing one. The chart generates an API key into a
Secret, gives it to the frontends, and points the ServiceMonitor's
bearer credential at that same Secret, so scraping works without
configuration. Be aware what that key is: **LocalAI has no metrics-only
credential, so the scrape key is a full API key**. It is generated per
release and preserved across upgrades, but anyone who can read the
Secret can call the inference API. Set `metrics.enabled=false` if that
trade is not acceptable.

**Alerts.** `alerts.enabled` renders a PrometheusRule with one rule,
`LocalAIDown`. That is deliberate: the only application metric is a
latency histogram with no status-code label, and latency on an inference
API is legitimately long and model-dependent, so alerting on it would
fire against a healthy server generating a long completion.

**Traces.** Nothing to wire. `LOCALAI_ENABLE_TRACING` keeps a bounded
in-memory buffer of recent API calls for LocalAI's own UI — it is not an
OpenTelemetry exporter and there is no OTLP endpoint to point at a
collector. (Metrics are OTel-instrumented internally but exposed through
the Prometheus endpoint above.)

**Logs.** Written to stdout for whatever collects container logs. Set
the level through `env`, e.g. `--set env.LOCALAI_LOG_LEVEL=debug`.

Both options create `monitoring.coreos.com` objects, so on a cluster
without the Prometheus Operator CRDs the API server rejects them and the
install fails. Turn them off there:

```bash
helm install my-localai zopdev/localai \
  --set metrics.enabled=false --set alerts.enabled=false
```

### Using an existing PostgreSQL or NATS

```bash
helm install my-localai zopdev/localai \
  --set distributed.enabled=true \
  --set externalDatabase.url="postgresql://user:pass@db:5432/localai?sslmode=disable" \
  --set externalNats.url="nats://nats.infra:4222"
```

The database must be PostgreSQL. LocalAI keeps its node registry, job
store and auth tables there, and does not support SQLite in distributed
mode.

### Security

`distributed.registrationToken` authenticates both worker registration
and the HTTP file-transfer server each worker runs. Left empty, the
chart generates one into a Secret and preserves it across upgrades — it
is never left unset, because a worker whose token is empty serves its
models, staging and data directories to anyone who can reach the port.

`distributed.autoApproveNodes` defaults to `true` so a fresh install
works without manual steps. Set it to `false` on an untrusted network
and approve nodes from the Nodes page, so that a pod which can reach the
frontend cannot join the cluster on its own.

**Set `distributed.adminEmail` on any cluster more than one person can
reach.** Distributed mode forces user authentication on, and the first
account created becomes the admin — the only role that can reach the
Nodes page, the approval queue and the scheduling API. Left unset, that
is simply whoever signs up first, which is a race rather than a
decision. Naming the address makes it deterministic, and pairs well with
closing sign-ups:

```bash
helm install my-localai zopdev/localai \
  --set distributed.enabled=true \
  --set postgres.enabled=true --set nats.enabled=true \
  --set distributed.adminEmail=platform@example.com \
  --set distributed.registrationMode=invite
```

Two limits worth knowing, neither of which this chart can close on its
own:

- **NATS runs without JWT credentials.** Anything that can reach port
  4222 in the cluster can publish control-plane subjects such as
  `backend.install`. LocalAI logs this at startup. Restrict it with a
  NetworkPolicy, or configure `LOCALAI_NATS_ACCOUNT_SEED` and
  `LOCALAI_NATS_SERVICE_JWT` through `env` using credentials generated
  with upstream's `scripts/nats-auth-setup.sh`.
- **The worker file-transfer port (gRPC base − 1) is reachable from
  anywhere in the cluster.** It is authenticated by the registration
  token, which this chart always sets, so it does not fail open — but a
  NetworkPolicy limiting it to the frontends is the stronger control.

---

## Example `values.yaml`

```yaml
distributed:
  enabled: true
  worker:
    replicaCount: 4
    diskSize: "50Gi"
    resources:
      requests:
        cpu: "2000m"
        memory: "8Gi"
      limits:
        cpu: "8000m"
        memory: "16Gi"

postgres:
  enabled: true
nats:
  enabled: true

ingress:
  enabled: true
  className: nginx
  host: ai.example.com
```

```bash
helm install my-localai zopdev/localai -f values.yaml
```

---

## Features

- Two topologies from a single value: one all-in-one pod, or API frontends in front of a pool of inference workers
- Workers install whatever backend a model needs on demand, so they take no per-model configuration and capacity grows by raising a replica count
- PostgreSQL and NATS installed with the release, or an existing server used instead
- Worker registration token generated into a Secret and preserved across upgrades
- Deterministic admin account, closable sign-ups, and optional manual approval of new nodes
- Prometheus ServiceMonitor for the API tier and a `LocalAIDown` alerting rule
- Ingress with optional TLS
- Per-pod model volumes by default, or one shared ReadWriteMany claim
- OpenAI-compatible API, so existing OpenAI clients work unchanged
- Configurations that cannot work are rejected when the chart renders, naming the cause, rather than installing and crash-looping

---

## Architecture

|                      | Standalone                       | Distributed                                        |
|----------------------|----------------------------------|----------------------------------------------------|
| Pods                 | 1                                | frontends + workers + PostgreSQL + NATS            |
| Inference runs on    | the same pod that serves the API | worker pods                                        |
| Scales by            | pod size                         | worker count                                       |
| Extra infrastructure | none                             | PostgreSQL, NATS                                   |
| Good for             | a single model, dev, small loads | many models, many GPUs, capacity that must grow    |

In distributed mode a worker starts with no backend installed. When a
request arrives for a model, the frontend's router picks a worker,
tells it over NATS which backend to install, stages the model files to
it, and loads the model. Workers therefore need no per-model
configuration, and adding capacity is only a matter of raising the
replica count.

---

The distributed topology deploys:
- LocalAI API frontends (StatefulSet) terminating the API and routing inference
- LocalAI workers (StatefulSet), each with its own models volume
- PostgreSQL for the node registry, job store and auth tables (dependency)
- NATS for backend-install and file-staging events (dependency)
- A headless Service governing the worker StatefulSet
- A ServiceMonitor and PrometheusRule for the API tier
- Ingress configuration for external access

The standalone topology deploys a single StatefulSet, its models volume,
and the API Service.

---

## Security Features

- Worker registration token generated into a Secret and never left empty, because an empty token makes each worker's file-transfer server serve its models and data directories to anyone who can reach the port
- Database credentials read from the Secret the `postgres` chart generates and interpolated by kubelet, so they never appear in a rendered manifest
- Deterministic admin account via `distributed.adminEmail`, instead of the role falling to whoever registers first
- Sign-ups closable with `distributed.registrationMode` (`approval` or `invite`)
- New nodes held for admin approval with `distributed.autoApproveNodes=false`
- Ingress TLS via an existing certificate secret

Two residual risks are documented rather than solved, because the chart
cannot close them on its own: NATS runs without JWT credentials unless
you supply them, and the metrics scrape credential is a full API key
because LocalAI has no metrics-only credential. Both are covered under
*Security* and *Observability* above.

---

## Connection Config

The API is OpenAI-compatible and served on `service.port` (8080) of the
`<release>-localai` service.

```bash
kubectl port-forward svc/my-localai-localai 8080:8080
curl http://localhost:8080/v1/models
```

- **`/v1/chat/completions`**, **`/v1/completions`**, **`/v1/embeddings`** :
  OpenAI-compatible inference endpoints.
- **`/models/apply`** : install a model from the gallery.
- **`/api/nodes/`** : worker node registry (distributed mode).
- **`/readyz`**, **`/healthz`** : readiness and liveness.

Distributed mode runs with authentication enabled, because LocalAI only
opens its PostgreSQL-backed state that way. API calls therefore need a
key.

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
