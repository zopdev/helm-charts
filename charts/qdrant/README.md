# Qdrant Helm Chart

The Qdrant Helm chart provides an easy way to deploy and manage a [Qdrant](https://qdrant.tech/) vector database in your Kubernetes environment. Qdrant is a high-performance vector search engine for AI applications — semantic search, recommendations, and retrieval-augmented generation (RAG). This chart includes persistence, resource management, built-in Prometheus metrics, and API-key authentication.

> **Single node.** This chart deploys one Qdrant node (`replicas: 1`, distributed mode off) — there is no high-availability or clustering. It is intended as an application datastore rather than a multi-node Qdrant cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3+
- **Prometheus Operator CRDs** (`ServiceMonitor`, `PrometheusRule`) — required, not optional: the chart renders both unconditionally, so `helm install` fails on a cluster without them (`no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"`).
- [Stakater Reloader](https://github.com/stakater/Reloader) (optional, recommended) — required only for the pod to restart automatically when `customConfig` changes.

## Add Helm Repository

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

## Install Helm Chart

```bash
helm install [RELEASE_NAME] zopdev/qdrant
```

For example:

```bash
helm install my-qdrant zopdev/qdrant
```

You can customize the installation by providing a custom `values.yaml` file or overriding values via the command line.

---

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `version` | Qdrant image tag (`qdrant/qdrant:<version>`) | `v1.19.0` |
| `diskSize` | Size of the PVC backing `/qdrant/storage` | `10Gi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `customConfig` | Extra Qdrant config (YAML), mounted at `/qdrant/config/local.yaml` | `""` |

---

## Ports

| Port | Purpose |
|------|---------|
| `6333` | REST / HTTP API (also serves `/metrics` and the health endpoints) |
| `6334` | gRPC API |

---

## Authentication

The chart generates a strong API key on install and stores it in a Kubernetes Secret named `<release-name>-qdrant-apikey-secret` under the key `api-key`. Qdrant is started with `QDRANT__SERVICE__API_KEY` set to this value, so all data requests must be authenticated — **including `/metrics`** (401 without the key). Only the health endpoints (`/livez`, `/readyz`, `/healthz`) remain open, so the probes work without the key; the ServiceMonitor authenticates with a Bearer token (see [Monitoring](#monitoring)).

The API key is **preserved across upgrades** — it is only generated once and re-used on subsequent `helm upgrade` runs.

### Retrieving the API key

```bash
kubectl get secret <release-name>-qdrant-apikey-secret \
  -o jsonpath='{.data.api-key}' | base64 --decode
```

### Connecting from an application

Applications need three things, published in the ConfigMap `<release-name>-qdrant-configmap`:

| Key | Value |
|-----|-------|
| `QDRANT_HOST` | `<release-name>-qdrant` |
| `QDRANT_HTTP_PORT` | `6333` |
| `QDRANT_GRPC_PORT` | `6334` |

Pass the API key in the `api-key` request header (or `Authorization: Bearer <key>`):

```bash
curl -H "api-key: <key>" http://<release-name>-qdrant:6333/collections
```

Qdrant has no databases or users — applications create **collections** at runtime through the REST or gRPC API, so no per-database provisioning is required.

---

## Custom configuration

Provide extra Qdrant settings as a YAML document via `customConfig`. It is mounted at `/qdrant/config/local.yaml`, which Qdrant layers on top of its defaults:

```yaml
customConfig: |
  log_level: INFO
  storage:
    optimizers:
      default_segment_number: 4
```

> Settings injected by the chart through `QDRANT__*` environment variables (such as the API key) always take precedence over `customConfig`.

---

## Monitoring

Qdrant exposes a built-in Prometheus endpoint on the HTTP port (`6333`) at `/metrics` — no exporter sidecar is required. When the API key is enabled, `/metrics` requires authentication (only the health endpoints stay open), so the shipped `ServiceMonitor` scrapes it with the key as a Bearer token, read from the generated Secret. The chart also ships a `PrometheusRule` with two alerts:

- **`QdrantDown`** (critical) — no metric scrapes succeed (`up == 0`).
- **`QdrantInRecoveryMode`** (critical) — the node booted into recovery mode, typically after an OOM. This is a **silent-degradation** state worth understanding before you meet it in an incident: the pod reports `Ready` and stays in the Service (so `QdrantDown` does **not** fire), but every read and write against existing collections fails. Recovery mode is Qdrant's designed remedy — with the pod reachable, drop a collection to get back under the memory limit, or raise `resources.limits.memory`.

---

## Uninstall

```bash
helm uninstall [RELEASE_NAME]
```

`helm uninstall` **deletes the API-key Secret but keeps the PersistentVolumeClaim** created by the StatefulSet. Two consequences:

- Reinstalling against the retained volume comes up with a **new** API key (the old data is intact, but any client still using the old key must be updated).
- If you want to reclaim the storage, delete the PVC manually:

```bash
kubectl delete pvc -l app=<release-name>-qdrant -n <namespace>
```
