# LiteLLM Helm Chart

<p align="center">
  <a href="https://zop.dev/zopday/app/deploy?install=litellm"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday"></a>
</p>

This Helm chart deploys the [LiteLLM](https://github.com/BerriAI/litellm) proxy on
Kubernetes. LiteLLM exposes a unified, OpenAI-compatible API in front of 100+ LLM
providers, with a built-in admin UI, virtual API keys, and spend tracking.

The chart is self-contained: it ships its own Deployment/Service/config templates and
pulls in the zopdev `postgres` chart as a subchart for the backing database.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- PostgreSQL (installed automatically as a subchart dependency)

---

## Dependencies

| Chart      | Version   | Repository               | Purpose                                            |
|------------|-----------|--------------------------|----------------------------------------------------|
| `postgres` | `0.0.14`  | `https://helm.zop.dev`   | Stores virtual keys, spend, and UI/API-added models |

The `ghcr.io/berriai/litellm-database` image bundles Prisma and runs the database
migrations automatically on container start, so no separate migration Job is needed.

Build the dependencies before installing from a local checkout:

```bash
helm dependency update charts/litellm
```

---

## Install

```bash
helm repo add zop https://helm.zop.dev
helm repo update
helm install litellm zop/litellm
```

The proxy takes roughly 3–7 minutes to become Ready — it loads litellm, runs
`prisma migrate deploy`, then initialises the app. If you install or upgrade
with `--wait`, raise the timeout past helm's 5-minute default, e.g.
`--wait --timeout 15m`, or the client gives up on a boot that is still healthy.

The release name `litellm` is recommended: the chart wires the proxy to the postgres
subchart's per-database secret (`<release>-litellm-litellm-postgres-database-secret`),
and using `litellm` keeps names predictable.

Override defaults with your own values file:

```bash
helm install litellm zop/litellm -f my-values.yaml
```

---

## Verify

```bash
# Proxy pod becomes Ready (DB init Job completes first, then Prisma migrate runs on boot)
kubectl get pods -l app=litellm

# Health endpoints
kubectl port-forward svc/litellm-litellm 4000:4000
curl localhost:4000/health/liveliness      # -> {"status":"..."}

# List configured models (master key required)
MASTER_KEY=$(kubectl get secret litellm-litellm-masterkey \
  -o jsonpath='{.data.PROXY_MASTER_KEY}' | base64 -d)
curl -H "Authorization: Bearer $MASTER_KEY" localhost:4000/v1/models
```

With `storeModelInDB: true` (the default), models added through the admin UI or API are
persisted to Postgres and survive pod restarts.

---

## Add a provider

1. Create a secret with the provider API key:

   ```bash
   kubectl create secret generic litellm-provider-keys \
     --from-literal=OPENAI_API_KEY=sk-...
   ```

2. Reference it and add the model in your values file:

   ```yaml
   extraEnvFrom:
     - secretName: litellm-provider-keys

   proxy_config:
     model_list:
       - model_name: gpt-4o
         litellm_params:
           model: openai/gpt-4o
           api_key: os.environ/OPENAI_API_KEY
   ```

3. `helm upgrade litellm zop/litellm -f my-values.yaml`

Provider keys are referenced as `os.environ/<VAR>` in `proxy_config` and resolved from the
environment mounted via `extraEnvFrom`.

---

## Uninstall

```bash
helm uninstall litellm
```

The postgres PersistentVolumeClaim and the auto-generated master-key secret are retained by
Kubernetes; delete them manually if you want a clean slate.

---

## Configuration

| **Input**                    | **Type**  | **Description**                                                       | **Default**                          |
|------------------------------|-----------|-----------------------------------------------------------------------|--------------------------------------|
| `image.repository`           | `string`  | LiteLLM image (must be the `-database` variant for migrations).       | `ghcr.io/berriai/litellm-database`   |
| `image.tag`                  | `string`  | Image tag; falls back to `.Chart.AppVersion` when empty.              | `main-v1.83.14-stable`               |
| `service.type`               | `string`  | Kubernetes Service type.                                              | `ClusterIP`                          |
| `service.port`               | `integer` | Proxy port (also serves `/metrics`).                                  | `4000`                               |
| `storeModelInDB`             | `boolean` | Persist UI/API-added models to Postgres.                              | `true`                               |
| `logLevel`                   | `string`  | `LITELLM_LOG` level.                                                  | `INFO`                               |
| `masterkey.existingSecret`   | `string`  | Use a pre-created master-key secret instead of auto-generating one.   | `""`                                 |
| `masterkey.secretKey`        | `string`  | Key within the master-key secret.                                     | `PROXY_MASTER_KEY`                   |
| `metrics.enabled`            | `boolean` | Render a ServiceMonitor scraping `/metrics` on the proxy port.        | `true`                               |
| `metrics.scrapeInterval`     | `string`  | ServiceMonitor scrape interval.                                       | `30s`                                |
| `extraEnvFrom`               | `array`   | Existing secrets (by `secretName`) mounted via `envFrom`.             | `[]`                                 |
| `extraEnv`                   | `object`  | Extra plain environment variables.                                    | `{}`                                 |
| `proxy_config.model_list`    | `array`   | Models exposed by the proxy (≥1 required to boot).                    | one `placeholder` model              |
| `resources`                  | `object`  | CPU/memory requests and limits.                                       | `250m`/`512Mi` … `1`/`1Gi`           |
| `probes.startup.periodSeconds` | `integer` | Seconds between startup checks.                                     | `10`                                 |
| `probes.startup.failureThreshold` | `integer` | Failed startup checks before the container is killed; x period is the whole boot budget (600s). | `60`            |
| `probes.readiness.periodSeconds` | `integer` | Seconds between readiness checks.                                   | `10`                                 |
| `probes.readiness.failureThreshold` | `integer` | Failed checks before the pod leaves the Service.                 | `3`                                  |
| `probes.liveness.periodSeconds` | `integer` | Seconds between liveness checks.                                     | `15`                                 |
| `probes.liveness.failureThreshold` | `integer` | Failed checks before the container is restarted.                  | `5`                                  |
| `autoscaling.enabled`        | `boolean` | Enable a HorizontalPodAutoscaler.                                     | `false`                              |
| `postgres.enabled`           | `boolean` | Deploy the postgres subchart. When `false`, supply `DATABASE_URL` yourself via `extraEnvFrom`. | `true`              |
| `postgres.services`          | `array`   | Databases to create (`name`/`database`).                              | `[{name: litellm, database: litellm}]` |

### Example `my-values.yaml`

```yaml
image:
  tag: main-v1.83.14-stable

storeModelInDB: true

extraEnvFrom:
  - secretName: litellm-provider-keys

proxy_config:
  model_list:
    - model_name: gpt-4o
      litellm_params:
        model: openai/gpt-4o
        api_key: os.environ/OPENAI_API_KEY
  general_settings:
    master_key: os.environ/PROXY_MASTER_KEY

postgres:
  services:
    - name: litellm
      database: litellm
```

---

## Notes

- **Metrics:** LiteLLM serves Prometheus `litellm_*` metrics at `/metrics` on the proxy port
  (:4000), so the ServiceMonitor points there rather than at a separate 2121 port. The
  postgres subchart still exposes its own exporter on 2121.
- **Redis:** not deployed in this version. LiteLLM only needs Redis for multi-pod
  rate-limit/spend coordination; the chart runs a single proxy replica.
- **Master key:** auto-generated and preserved across upgrades via `lookup`. Set
  `masterkey.existingSecret` to manage it yourself.
- **GitOps (ArgoCD/Flux):** the `lookup`-based master-key preservation needs cluster read
  access during rendering, which server-side GitOps rendering may lack — it can rotate the
  key on each sync. For GitOps, pre-create the secret and set `masterkey.existingSecret`.
- **Bring your own database:** set `postgres.enabled=false` to skip the subchart, and provide
  a `DATABASE_URL` (Prisma-compatible `postgres://…`) through a secret listed in `extraEnvFrom`.
- **Exposure:** the default `service.type: ClusterIP` keeps the proxy internal. Switching to
  `LoadBalancer`/`NodePort` exposes the admin UI and key-management API publicly — front it
  with auth/ingress before doing so.

---

## Contributing

We welcome contributions. Please refer to [CONTRIBUTING.md](../../CONTRIBUTING.md).

---

## License

This project is licensed under the [Apache 2.0 License](../../LICENSE).
