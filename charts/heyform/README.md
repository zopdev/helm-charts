# HeyForm Helm Chart

Deploys [HeyForm](https://heyform.net/), an open-source form builder for surveys, quizzes and polls, on Kubernetes, together with the MongoDB and Redis it needs.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- **Prometheus Operator CRDs** (`ServiceMonitor`, `PrometheusRule`). The bundled charts render both unconditionally.

## Dependencies

| Chart | Version | Purpose |
|-------|---------|---------|
| `mongodb` | `0.0.1` | Forms, submissions, users and workspaces. Supplies `MONGO_URI` |
| `redis` | `0.0.6` | Sessions and background job queues. Supplies `REDIS_HOST` / `REDIS_PORT` |
| `service` | `0.0.34` | The HeyForm Deployment, Service, Ingress, PVC and alerts |

All three come from `https://helm.zop.dev`. When installing from a checkout, fetch them first:

```bash
helm dependency build charts/heyform
```

---

## Install Helm Chart

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
helm install heyform zopdev/heyform \
  --set service.env.SESSION_KEY=$(openssl rand -hex 32) \
  --set service.env.FORM_ENCRYPTION_KEY=$(openssl rand -hex 32)
```

**The release name must be `heyform`.** The service chart finds the MongoDB and Redis ConfigMaps/Secrets by names built from the release name and the `datastore` entries in `values.yaml`, which are set to `heyform`.

Then open it:

```bash
kubectl port-forward svc/heyform-app 9157:80
# http://localhost:9157
```

The first pod can restart once on a fresh install: Redis's headless Service publishes no DNS record until Redis is ready, and HeyForm exits if it cannot resolve it. The restarted pod connects normally.

## Uninstall Helm Chart

```bash
helm uninstall heyform
```

The MongoDB and Redis volumes are kept, as with any StatefulSet. Delete their PVCs to drop the data.

---

## Configuration

| Input | Description | Default |
|-------|-------------|---------|
| `service.env.APP_HOMEPAGE_URL` | Public address HeyForm is reached at. The login cookie is scoped to its hostname, so it must match what users type into the browser | `http://localhost:9157` |
| `service.env.SESSION_KEY` | Signs session cookies. **Replace the shipped placeholder** | placeholder |
| `service.env.FORM_ENCRYPTION_KEY` | Encrypts stored form data. **Replace the shipped placeholder before collecting real data**; changing it later makes existing data unreadable | placeholder |
| `service.image` | HeyForm image | `heyform/community-edition:v3.0.3` |
| `service.nginx.host` | Hostname for the Ingress. Empty means no Ingress | `""` |
| `service.nginx.tlsSecretName` | TLS secret for that host | `""` |
| `service.minCPU` / `service.maxCPU` | CPU request / limit | `250m` / `1000m` |
| `service.minMemory` / `service.maxMemory` | Memory request / limit | `512Mi` / `1Gi` |
| `service.volumeMounts.pvc[0].storage` | Size of the uploads volume (`/app/packages/server/static/upload`) | `10Gi` |
| `mongodb.diskSize` | MongoDB volume size | `10Gi` |
| `redis.diskSize` | Redis volume size | `10Gi` |

Any other [HeyForm environment variable](https://docs.heyform.net/configuration), such as SMTP or social login, can be added under `service.env`.

HeyForm runs as a single replica: uploads live on a ReadWriteOnce volume, which several pods cannot share.

---

## Contributing

Please refer to [CONTRIBUTING.md](../../CONTRIBUTING.md).

## License

This project is licensed under the [LICENSE](../../LICENSE).
