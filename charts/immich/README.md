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
release. Delete them separately to reclaim the disks:

```bash
kubectl delete pvc library-my-immich-immich-server-0 \
  cache-my-immich-immich-ml-0 \
  data-my-immich-immich-postgres-0
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
| `postgres.diskSize` | `string` | Size of the database volume. | `"10Gi"` |
| `postgres.resources` | `object` | CPU and memory for the database pod. | 500m/1Gi – 2000m/2Gi |
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
