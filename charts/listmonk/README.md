<a href="https://zop.dev/zopday/app/deploy?install=listmonk"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" align="right" height="36"></a>

# listmonk Helm Chart

Deploys [listmonk](https://listmonk.app/), a self-hosted newsletter and mailing list manager, on Kubernetes, together with the PostgreSQL database it needs.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- **Prometheus Operator CRDs** (`ServiceMonitor`, `PrometheusRule`). The bundled charts render both unconditionally.

## Dependencies

| Chart | Version | Purpose |
|-------|---------|---------|
| `postgres` | `0.0.15` | Subscribers, lists, campaigns, templates and settings. Supplies `DB_*` |
| `service` | `0.0.36` | The listmonk Deployment, Service, Ingress, uploads PVC and alerts |

Both come from `https://helm.zop.dev`. When installing from a checkout, fetch them first:

```bash
helm dependency build charts/listmonk
```

---

## Install Helm Chart

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
helm install listmonk zopdev/listmonk --set admin.password='<8+ characters>'
```

Any release name works except `listmonk-app` (its PrometheusRule would clash with the service one); Postgres is wired in by `<release>-…` names. Install **one listmonk per namespace**: the Deployment (`listmonk-app`) and uploads PVC (`listmonk-uploads`) have fixed names.

### Admin account

The first admin is created from `admin.username` and `admin.password`, stored in the `<release>-admin` Secret:

- Set `admin.password` (8+ characters) and sign in with it.
- Leave it empty and a random 24-character password is generated, kept across upgrades. Read it with:

  ```bash
  kubectl get secret <release>-admin -o jsonpath='{.data.LISTMONK_ADMIN_PASSWORD}' | base64 -d; echo
  ```

listmonk reads these **only on the first install**, into an empty database. After that the account lives in Postgres, so change the password from **Admin → Users** in listmonk. Changing `admin.*` later has no effect.

### Open it

```bash
kubectl port-forward svc/listmonk-app 9000:80
# http://localhost:9000/admin
```

Or set `service.nginx.host` for an Ingress. Either way, set **Settings → General → Root URL** in listmonk to the public address: it goes into every unsubscribe, view-in-browser and tracking link, and listmonk keeps it in its database, not in an environment variable. Configure SMTP under **Settings → SMTP** before sending.

## How it starts

listmonk reads its database settings only as `LISTMONK_db__*`, while the postgres subchart provides `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` and `DB_PASSWORD`. The container commands map one onto the other.

An **init container** prepares the database before listmonk starts:

1. `./listmonk --install --idempotent --yes`: creates the schema and the admin account on an empty database, and is a no-op afterwards. On a fresh install it is retried every 5 s until the postgres init Job has created listmonk's user, giving up after 10 minutes.
2. `./listmonk --upgrade --yes`: applies the migrations of a newer image. listmonk refuses to start while migrations are pending. **Back up Postgres before raising the image.**

Then the main container just runs `./listmonk`. Doing the install and migrations in an init container keeps them out of reach of the liveness probe, which would otherwise restart the pod during a slow first install or part way through a long migration.

**Upgrading listmonk:** set `service.image` and `service.initContainer.image` to the same new tag. The init container's binary runs the migrations, so the install fails at render time if the two differ.

The chart runs exactly one replica (`minReplicas`/`maxReplicas` 1, `Recreate` strategy): migrations must not run in two pods at once, and uploads sit on a ReadWriteOnce volume.

The pod runs as uid 1000, non-root, with all capabilities dropped. The admin Secret is mounted only into the init container.

**Health checks:** both probes use `/health`, which listmonk answers without touching Postgres. A Postgres outage therefore does not restart or un-ready the pod. listmonk reconnects on its own once Postgres is back, but the Service keeps routing to it while the database is down.

## Uninstall Helm Chart

```bash
helm uninstall listmonk
```

Uninstall **keeps your data**: the Postgres volume (as with any StatefulSet), the `listmonk-uploads` volume and the `<release>-admin` Secret (`helm.sh/resource-policy: keep`).

The postgres subchart's own credential Secrets are **not** kept, so a reinstall onto the retained Postgres volume fails with `password authentication failed for user "postgres"` in the `postgres-<release>-listmonk-init-*` Job. To start from scratch, delete the PVCs and the `<release>-admin` Secret before reinstalling.

---

## Configuration

| Key | Default | Description |
|-----|---------|-------------|
| `admin.username` | `admin` | First admin's login name, 3+ characters. First install only |
| `admin.password` | `""` | First admin's password, 8+ characters. Empty generates one. First install only |
| `service.image` | `listmonk/listmonk:v6.2.0` | listmonk image. Raising it migrates the database |
| `service.initContainer.image` | `listmonk/listmonk:v6.2.0` | Image that installs and migrates the database. Must equal `service.image` |
| `service.nginx.host` | `""` | Ingress hostname. Empty means no Ingress |
| `service.nginx.tlsHost` | `""` | Hostname in the TLS certificate |
| `service.nginx.tlsSecretName` | `""` | Existing TLS Secret for the host |
| `service.minCPU` / `service.maxCPU` | `100m` / `500m` | CPU request / limit |
| `service.minMemory` / `service.maxMemory` | `128Mi` / `512Mi` | Memory request / limit |
| `service.volumeMounts.pvc[0].storage` | `5Gi` | Uploads volume size. Install time only |
| `postgres.diskSize` | `10Gi` | Postgres volume size. Install time only |

Any other listmonk config key can be set as an environment variable under `service.env`, named `LISTMONK_<section>__<key>` (see the [listmonk configuration docs](https://listmonk.app/docs/configuration/)).
