# n8n Helm Chart

This Helm chart deploys [n8n](https://n8n.io) on Kubernetes. n8n is a workflow
automation platform: workflows are built in a browser-based editor and triggered
on a schedule, by a webhook call, or by hand.

The chart is self-contained. It ships its own Deployment, Service and config
templates and pulls in the zopdev `postgres` chart as a subchart for the backing
database.

One pod serves the editor, the REST API and the webhook endpoints, and runs the
executions in the same process (`EXECUTIONS_MODE=regular`). Queue mode — which
spreads executions across dedicated worker pods and needs Redis — is not part of
this chart.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- A default StorageClass, for the data volume
- PostgreSQL (installed automatically as a subchart dependency)
- Prometheus Operator CRDs (`servicemonitors` and `prometheusrules`)

The CRDs are required even with `metrics.enabled=false` and `alerts.enabled=false`.
Those flags govern this chart's own objects; the postgres subchart renders a
ServiceMonitor and a PrometheusRule unconditionally, and without the CRDs the
install fails with `no matches for kind "PrometheusRule"`. On a cluster without
the Prometheus Operator, install just the two CRDs:

```bash
BASE=https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd
kubectl apply --server-side -f $BASE/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f $BASE/monitoring.coreos.com_prometheusrules.yaml
```

---

## Dependencies

| Chart      | Version  | Repository             | Purpose                                              |
|------------|----------|------------------------|------------------------------------------------------|
| `postgres` | `0.0.13` | `https://helm.zop.dev` | Stores workflows, credentials and execution history  |

Build the dependencies before installing from a local checkout:

```bash
helm dependency update charts/n8n
```

---

## Install

```bash
helm repo add zop https://helm.zop.dev
helm repo update
helm install n8n zop/n8n
```

To skip this chart's own monitoring objects (the CRDs are still needed, see
above):

```bash
helm install n8n zop/n8n --set metrics.enabled=false --set alerts.enabled=false
```

---

## Verify

```bash
# The pod waits on the database, then runs migrations, then becomes Ready
kubectl get pods -l app=n8n

kubectl port-forward svc/n8n-n8n 5678:5678
open http://localhost:5678
```

The first page asks you to create an owner account. That account lives in the
database rather than in the release, so it survives upgrades — and it cannot be
recovered from the chart, so keep the password.

---

## Two things worth getting right before building workflows

### The public URL

n8n writes its own address into every webhook it registers and into OAuth
callback URLs. With no public URL configured it uses `http://localhost:5678/`,
which leaves a perfectly working editor whose webhooks nothing outside the
cluster can call.

Enabling the ingress is what fixes this — `WEBHOOK_URL`, `N8N_HOST` and
`N8N_PROTOCOL` are all derived from `ingress.host`, and `tlsSecretName` decides
whether that is `https`:

```yaml
ingress:
  enabled: true
  host: n8n.example.com
  tlsSecretName: n8n-tls
```

If something else terminates traffic — a tunnel, or a proxy on another hostname —
set the URL directly instead. It overrides the derivation, and host and protocol
follow from it:

```yaml
webhookUrl: https://hooks.example.com/
```

### The encryption key

Every credential stored in n8n is encrypted with `N8N_ENCRYPTION_KEY`. The chart
generates one on install and reads it back on upgrade, so it is stable for as
long as the secret exists. **It cannot be recovered from the database.** If it is
lost, workflows survive but every credential has to be entered again.

Back it up after installing:

```bash
kubectl get secret n8n-n8n-encryption \
  -o jsonpath='{.data.N8N_ENCRYPTION_KEY}' | base64 -d
```

To manage it yourself instead, create the secret first and point the chart at it:

```bash
kubectl create secret generic n8n-encryption \
  --from-literal=N8N_ENCRYPTION_KEY="$(openssl rand -base64 24)"
```

```yaml
encryptionKey:
  existingSecret: n8n-encryption
```

---

## Configuration

### Image

| Key                | Description                                            | Default      |
|--------------------|--------------------------------------------------------|--------------|
| `image.repository` | Image repository                                       | `n8nio/n8n`  |
| `image.tag`        | Image tag; falls back to `.Chart.AppVersion` when empty | `""`         |
| `image.pullPolicy` | Image pull policy                                      | `IfNotPresent` |

`appVersion` pins an immutable release tag. `latest` and `stable` both move, so
setting either would make two installs of the same chart version run different
code.

### Service and ingress

| Key                     | Description                                                     | Default     |
|-------------------------|-----------------------------------------------------------------|-------------|
| `service.type`          | Service type                                                    | `ClusterIP` |
| `service.port`          | Port for the editor, API, webhooks and `/metrics`               | `5678`      |
| `ingress.enabled`       | Render the Ingress                                              | `false`     |
| `ingress.className`     | IngressClass name                                               | `""`        |
| `ingress.host`          | Hostname to serve; required when enabled                        | `""`        |
| `ingress.annotations`   | Annotations applied to the Ingress                              | `{}`        |
| `ingress.tlsSecretName` | Existing TLS certificate secret                                 | `""`        |
| `webhookUrl`            | Overrides the public URL derived from `ingress.host`            | `""`        |

### Persistence

| Key                        | Description                                        | Default  |
|----------------------------|----------------------------------------------------|----------|
| `persistence.enabled`      | Provision a volume for `/home/node/.n8n`           | `true`   |
| `persistence.size`         | Requested volume size                              | `10Gi`   |
| `persistence.storageClass` | StorageClass name; empty uses the cluster default  | `""`     |
| `persistence.existingClaim`| Bind an existing claim instead of creating one     | `""`     |

The volume holds the config file n8n writes on first boot, any custom nodes, and
binary payloads. With it enabled the chart sets
`N8N_DEFAULT_BINARY_DATA_MODE=filesystem`, keeping uploaded files and HTTP
response bodies out of the execution rows in Postgres — which is what stops the
`execution_data` table growing without bound. Disabling it switches binary
storage into Postgres rather than writing to a container filesystem that is lost
on restart.

The claim carries `helm.sh/resource-policy: keep`, so `helm uninstall` leaves the
data behind.

### Database

| Key                 | Description                                                    | Default |
|---------------------|----------------------------------------------------------------|---------|
| `postgres.enabled`  | Install PostgreSQL with this release                           | `true`  |
| `postgres.name`     | Owning service name, used as the `service` label on its alerts | `n8n`   |
| `postgres.services` | Databases to provision (`name`/`database`)                     | `[{name: n8n, database: n8n}]` |

To use a server this release does not manage, turn the subchart off and describe
the existing one. The password is only ever read from a secret — this chart will
not take it as a plain value, because everything in `values.yaml` ends up
readable in the release manifest:

```yaml
postgres:
  enabled: false
externalDatabase:
  host: postgres.example.com
  port: 5432
  database: n8n
  user: n8n
  existingSecret: n8n-db
  passwordKey: password
```

Setting both `postgres.enabled` and `externalDatabase.host` fails the render
rather than silently picking one.

| Key                             | Description                                     | Default   |
|---------------------------------|-------------------------------------------------|-----------|
| `waitForDatabase.enabled`       | Block startup until the database authenticates  | `true`    |
| `waitForDatabase.image.*`       | Image providing `psql` for the wait loop        | `docker.io/bitnamilegacy/postgresql:17.4.0` |

The postgres chart creates the role from a Pod that sleeps before it runs, so
without this init container n8n crash-loops through the first minute of a fresh
install.

### Observability

| Key                      | Description                                      | Default |
|--------------------------|--------------------------------------------------|---------|
| `metrics.enabled`        | Serve `/metrics` and render the ServiceMonitor    | `true`  |
| `metrics.scrapeInterval` | ServiceMonitor scrape interval                    | `30s`   |
| `alerts.enabled`         | Render the PrometheusRule                         | `true`  |

`metrics.enabled` sets `N8N_METRICS`, which is what makes n8n serve the endpoint
at all, so the scrape target and the endpoint cannot disagree. Both options
render `monitoring.coreos.com` objects and need the Prometheus Operator CRDs.

### Compute and environment

| Key                    | Description                                              | Default |
|------------------------|----------------------------------------------------------|---------|
| `resources.requests`   | CPU/memory requests                                      | `500m` / `1Gi` |
| `resources.limits`     | CPU/memory limits                                        | `1` / `2Gi`    |
| `timezone`             | Timezone cron triggers are scheduled against             | `UTC`   |
| `env`                  | Extra plain environment variables                        | `{}`    |
| `extraEnvFrom`         | Existing secrets mounted via `envFrom`                   | `[]`    |

`timezone` is applied as both `GENERIC_TIMEZONE` and `TZ`; a wrong value silently
shifts when scheduled workflows run.

`env` ships four defaults, all settings n8n warns it is about to change. Pinning
them means an image bump cannot quietly alter how the release behaves:

| Variable | Default | Why |
|---|---|---|
| `N8N_UNVERIFIED_PACKAGES_ENABLED` | `"false"` | Blocks unvetted community nodes; also where n8n's own default is heading |
| `N8N_RUNNERS_TASK_TIMEOUT` | `"300"` | Today's value, kept so a future reduction to 60s cannot start killing long-running Code nodes |
| `N8N_COMPRESSION_NODE_MAX_DECOMPRESSED_SIZE_BYTES` | `"268435456"` | 256 MiB rather than today's 2 GiB; unbounded decompression of an untrusted archive is a memory-exhaustion risk |
| `N8N_COMPRESSION_NODE_MAX_ZIP_ENTRIES` | `"1000"` | Same reasoning, on entry count |

Override or remove any of them freely — they are ordinary `env` entries.

Put anything sensitive in a secret and reference it rather than using `env`:

```yaml
extraEnvFrom:
  - secretName: n8n-smtp
```

Variables the chart derives from other values — `DB_TYPE`, the `DB_POSTGRESDB_*`
set, `N8N_ENCRYPTION_KEY`, `N8N_DEFAULT_BINARY_DATA_MODE` — are rejected at
render time rather than silently overridden.

---

## Upgrading

```bash
helm upgrade n8n zop/n8n
```

The encryption key is read back from the existing secret, and the database
credentials belong to the postgres subchart, which preserves them the same way.
Because the data volume is ReadWriteOnce the Deployment uses `strategy: Recreate`
— the old pod is torn down before the new one starts, so an upgrade is a brief
outage rather than a rolling handover.

---

## Uninstalling

```bash
helm uninstall n8n
```

The data volume is retained by policy. Remove it deliberately:

```bash
kubectl delete pvc n8n-n8n
```
