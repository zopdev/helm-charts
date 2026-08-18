# Immich Helm Chart

[Immich](https://github.com/immich-app/immich) is a self-hosted photo
and video backup solution, a drop-in alternative to Google
Photos/iCloud with a matching mobile app. This chart deploys all four
pieces Immich's own reference deployment runs: the server, machine
learning, its own Postgres (with the vector extension its search
needs), and Redis.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3+
- Prometheus Operator CRDs (`monitoring.coreos.com`) installed on the
  cluster. The redis dependency renders a `PrometheusRule` and a
  `ServiceMonitor` unconditionally — there's no flag to opt out — so
  `helm install` fails outright without them.

---

## Add Helm Repository

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

---

## Install Helm Chart

```bash
helm install my-immich zopdev/immich
```

Deploys all four components. First run: open the server's URL and
create the admin account — Immich has no default login.

---

## Uninstall Helm Chart

```bash
helm uninstall my-immich
```

PersistentVolumeClaims created from volume templates outlive the
release. Delete **all four** separately to reclaim the disks:

```bash
kubectl delete pvc library-my-immich-immich-server-0 \
  cache-my-immich-immich-ml-0 \
  data-my-immich-immich-postgres-0 \
  my-immich-redis-persistent-storage-my-immich-redis-0
```

**If you're keeping the volumes to reinstall later, leave the postgres
password Secret alone too.** It's annotated `helm.sh/resource-policy:
keep` specifically so `helm uninstall` doesn't remove it — the
database volume is initialized with that password baked in, and a
reinstall that generates a *new* random password (because the old
Secret was deleted along with the volume being kept) can never
authenticate against it again. Delete the Secret and the postgres PVC
together, or keep both together — never split them. To reclaim
*everything*, including that Secret:

```bash
kubectl delete secret my-immich-immich-postgres-secret
```

---

## Configuration

| **Input** | **Type** | **Description** | **Default** |
|---|---|---|---|
| `server.image.tag` | `string` | Server image tag. | `v3.1.0` |
| `server.service.type` | `string` | Service type for the web UI/API. | `ClusterIP` |
| `server.service.port` | `int` | Service port for the web UI/API. | `2283` |
| `server.diskSize` | `string` | Size of the photo/video library volume. | `"20Gi"` |
| `server.resources` | `object` | CPU and memory for the server pod. | 500m/1Gi – 2000m/4Gi |
| `server.env` | `object` | Extra environment variables for the server. | `{}` |
| `machineLearning.image.tag` | `string` | Machine-learning image tag. | `v3.1.0` |
| `machineLearning.diskSize` | `string` | Size of the ML model cache volume. | `"5Gi"` |
| `machineLearning.resources` | `object` | CPU and memory for the ML pod. | 1000m/2Gi – 4000m/4Gi |
| `postgres.database` | `string` | Database name. | `"immich"` |
| `postgres.username` | `string` | Database user. | `"immich"` |
| `postgres.password` | `string` | Pin a known database password instead of generating one. See *Database password* below. | `""` |
| `postgres.existingSecret` | `string` | Name of an existing Secret carrying `POSTGRES_PASSWORD`, used instead of one this chart manages. | `""` |
| `postgres.diskSize` | `string` | Size of the database volume. | `"10Gi"` |
| `postgres.resources` | `object` | CPU and memory for the database pod. | 500m/1Gi – 2000m/2Gi |
| `redis.name` | `string` | Service name labelled on the redis subchart's alerts. Required — see *Redis* below. | `"immich"` |
| `ingress.enabled` | `bool` | Create an Ingress for the web UI/API. | `false` |
| `ingress.className` | `string` | IngressClass name. | `""` |
| `ingress.host` | `string` | Hostname. Required when the ingress is enabled. | `""` |
| `ingress.annotations` | `object` | Ingress annotations. | `{}` |
| `ingress.tlsSecretName` | `string` | Existing TLS secret for the host. | `""` |

### Why a separate Postgres, not the zopdev postgres chart

Immich's search features (`smart search`, duplicate detection) need a
vector extension. Upstream ships their own Postgres image with it
built in (`ghcr.io/immich-app/postgres`) — the zopdev `postgres` chart
runs plain bitnami Postgres, which doesn't have it, so this chart
brings its own Postgres StatefulSet instead of depending on that one.

### Machine learning is always deployed

There's no toggle to turn it off. Upstream's own reference
docker-compose always runs it too — the server calls it internally
for face detection and smart search, and it needs no configuration of
its own.

### Redis

Reuses the zopdev `redis` chart as the job queue backing Immich's
background workers (thumbnail generation, metadata extraction, etc.).

`redis.name` labels the subchart's own `PrometheusRule` — it has no
default of its own, and an unset value renders a null label the CRD
rejects, failing the whole install. This chart sets it for you; there
should be no need to change it.

### Database password

Left unset, `postgres.password` is auto-generated and stored in a
Secret annotated `helm.sh/resource-policy: keep`, so it survives
`helm uninstall` alongside the postgres PVC (see *Uninstall* above) —
a reinstall against that same retained volume still authenticates.

Set `postgres.password` to pin a known password instead — e.g. to
restore into a fresh volume from a backup taken under a specific
password. Set `postgres.existingSecret` (name of a Secret you manage,
carrying a `POSTGRES_PASSWORD` key) to skip this chart's own Secret
entirely; it takes precedence over `postgres.password`.

### Minimum node size

Summed across all four components, the defaults request **2.5 CPU /
4.3Gi** and allow bursting to **9.5 CPU / 11.1Gi** — machine learning
alone requests 1 CPU / 2Gi. A 2-CPU node cannot schedule this
release. Size accordingly, or lower `machineLearning.resources` if
inference latency isn't a concern.

---

## Example `values.yaml`

```yaml
server:
  diskSize: "200Gi"
  resources:
    requests:
      cpu: "1000m"
      memory: "2Gi"
    limits:
      cpu: "4000m"
      memory: "8Gi"

ingress:
  enabled: true
  className: nginx
  host: photos.example.com
```

```bash
helm install my-immich zopdev/immich -f values.yaml
```

---

## Features

- All four components from Immich's own reference deployment: server, machine learning, vector-extension Postgres, Redis
- Persistent volumes for the photo/video library, the database, and the ML model cache
- Ingress with optional TLS — point the Immich mobile app at that URL for auto-backup
- Configurations that cannot work (a bad ingress setup) are rejected when the chart renders, naming the cause, rather than installing and crash-looping

---

## Connection Config

The web UI, REST API, and mobile app all talk to `server.service.port`
(2283) of the `<release>-immich-server` service.

```bash
kubectl port-forward svc/my-immich-immich-server 2283:2283
open http://localhost:2283
```

- **`/`** — the web UI.
- **`/api/...`** — the REST API the mobile app and web UI both use.
- **`/api/server/ping`** — readiness and liveness.

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
