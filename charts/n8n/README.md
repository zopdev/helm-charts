<a href="https://zop.dev/zopday/app/deploy?install=n8n"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" align="right" height="36"></a>

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
| `postgres` | `0.0.14` | `https://helm.zop.dev` | Stores workflows, credentials and execution history  |

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

Enabling the ingress is what fixes this — `N8N_WEBHOOK_URL`, `N8N_HOST` and
`N8N_PROTOCOL` are all derived from `ingress.host`, and `tlsSecretName` decides
whether that is `https`:

```yaml
ingress:
  enabled: true
  host: n8n.example.com
  tlsSecretName: n8n-tls
```

**If TLS is terminated upstream, say so — the chart cannot tell.** `tlsSecretName`
is only one way a site becomes HTTPS. An ALB with an ACM certificate, a GKE
managed certificate and a `cert-manager.io/cluster-issuer` annotation all serve
HTTPS while rendering no `tls:` block at all, and the chart would otherwise
advertise `http://` for a site that only answers on `https://`. Point
`webhookUrl` at the real address in that case:

```yaml
ingress:
  enabled: true
  className: alb
  host: n8n.example.com
  annotations:
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
webhookUrl: https://n8n.example.com/    # the scheme the world actually sees
```

**Serving the host over genuinely plain http needs one concession.** n8n marks
its auth cookie `Secure` by default and browsers will not return a `Secure`
cookie over http, so the editor loads and every login fails. Set
`insecureCookie: true` to accept that, and NOTES will remind you it is on.

The chart does **not** infer this from a missing `tlsSecretName`. Guessing
"insecure" from an absent field would silently drop `Secure` on the
annotation-terminated HTTPS deployments above — a security downgrade nobody
asked for is worse than an instance that refuses to log in and tells you why. A
port-forward to `localhost` needs none of this: browsers treat localhost as a
secure context.

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

`values.schema.json` deliberately describes only the handful of fields the
zop.dev configuration form should offer — image, ingress, persistence, timezone
and resources. Everything else documented below is still settable in a values
file or with `--set`; it simply is not rendered as a form field, because it is
either plumbing or only relevant to a specific topology. The chart's own
`templates/validate.yaml` guards those values at render time regardless of
whether the schema describes them.


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
| `webhookUrl`            | Overrides the public URL derived from `ingress.host`; must include the scheme | `""`        |
| `insecureCookie`        | Send the auth cookie without `Secure`; needed for plain http     | `false`     |

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
storage into Postgres (`N8N_DEFAULT_BINARY_DATA_MODE=database`) rather than
writing to a container filesystem that is lost on restart. The chart never
selects n8n's `default` mode, which despite the name keeps payloads in the
process heap — that would be an OOMKill against the memory limit, and it is
removed in n8n 3.x.

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

Three things deliberately survive an uninstall, because together they are the
instance:

| Object | Why it stays |
|---|---|
| `pvc/n8n-n8n` | `helm.sh/resource-policy: keep` — binary data and custom nodes |
| `pvc/n8n-persistent-storage-n8n-postgres-0` | a `volumeClaimTemplates` claim; Kubernetes never deletes these |
| `secret/n8n-n8n-encryption` | `helm.sh/resource-policy: keep` — the only key that can decrypt the credentials in that database |

The encryption secret is kept for the same reason as the volumes: deleting it
while the database survives would leave workflows intact and every stored
credential undecryptable.

**Uninstall is not reversible, though — verified, not assumed.** Reinstalling the
same release over those retained volumes fails, and not because of anything this
chart does. The postgres subchart's `<release>-postgres-root-secret` is *not*
retained, so a reinstall generates a new superuser password while the retained
data directory still expects the old one. Postgres then refuses its own init Job
(`password authentication failed for user "postgres"`), the n8n role is never
created, and this chart's `wait-for-db` init container blocks — which is the
correct outcome, since the alternative is n8n starting against a database it
cannot read.

So: to keep an instance alive, use `helm upgrade`, never uninstall-and-reinstall.
If you must uninstall and later restore, back up **both** secrets first:

```bash
kubectl get secret n8n-n8n-encryption -o yaml > n8n-encryption.backup.yaml
kubectl get secret n8n-postgres-root-secret -o yaml > n8n-postgres-root.backup.yaml
```

Restoring both before reinstalling is what makes the retained volumes usable
again.

To remove the instance completely, delete all three deliberately:

```bash
kubectl delete pvc n8n-n8n n8n-persistent-storage-n8n-postgres-0
kubectl delete secret n8n-n8n-encryption
```
