# MongoDB Helm Chart

Deploys a single-node [MongoDB](https://www.mongodb.com/) server on Kubernetes, with persistence, a Prometheus exporter, alerts, and one database + user per application listed in `services`.

> **Single node.** One `mongod` (`replicas: 1`), no replica set. It is meant as an application datastore, not a highly available MongoDB cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3+
- **Prometheus Operator CRDs** (`ServiceMonitor`, `PrometheusRule`). The chart renders both unconditionally, so `helm install` fails on a cluster without them.

## Add Helm Repository

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

## Install Helm Chart

```bash
helm install my-mongo zopdev/mongodb \
  --set 'services[0].name=myapp' \
  --set 'services[0].database=myapp'
```

## Uninstall Helm Chart

```bash
helm uninstall my-mongo
```

The data volume (`<release>-mongodb-persistent-storage-<release>-mongodb-0`) is kept after uninstall, as with any StatefulSet. Delete the PVC to drop the data.

---

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `version` | MongoDB image tag (`mongo:<version>`), pinned to a patch release | `7.0.45` |
| `diskSize` | Size of the PVC backing `/data/db`. Fixed at install time | `10Gi` |
| `wiredTigerCacheSizeGB` | WiredTiger cache size, minimum `0.25`. Keep it at about half of the memory limit or less | `0.25` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `500Mi` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `services` | Databases to create: a list of `{name, database}` | `[]` |
| `name` | Service the alerts are attributed to | release name |
| `nodeSelector` / `tolerations` / `affinity` | Pod scheduling | empty |

---

## What each `services` entry gets

For every entry `{name: <svc>, database: <db>}` the chart creates a user scoped to `<db>` (roles `readWrite` and `dbAdmin` on that database only) through a one-shot Job, plus:

**ConfigMap** `<release>-<db>-<svc>-mongodb-configmap`

| Key | Value |
|-----|-------|
| `MONGO_HOST` | `<release>-mongodb` |
| `MONGO_PORT` | `27017` |
| `MONGO_DB` | `<db>` |

**Secret** `<release>-<db>-<svc>-mongodb-database-secret`

| Key | Value |
|-----|-------|
| `MONGO_USER` | generated username |
| `MONGO_PASSWORD` | generated password |
| `MONGO_URI` / `MONGODB_URI` | `mongodb://<user>:<password>@<release>-mongodb:27017/<db>?authSource=<db>` |

Underscores in `<db>` become hyphens in the object names. Credentials are generated on install and read back from the live Secret on every upgrade, so they stay stable.

Attach them to an app built on the `service` chart (0.0.34+) with:

```yaml
datastores:
  mongodb:
    - datastore: <release>
      database: <db>
```

The `service` chart looks for `<datastore>-<db>-<its release>-mongodb-*`, so this matches when the mongodb release, the `services[].name` and the app release share one name, which is the case when mongodb is bundled as a subchart.

The root password lives in `<release>-mongodb-root-secret`.

### Credential caveats

- **Uninstall keeps the data and the root password.** `helm uninstall` leaves the data PVC (as with any StatefulSet) and, through `helm.sh/resource-policy: keep`, the `<release>-mongodb-root-secret`. The root password is written into the volume on first boot only, so a reinstall with the **same release name in the same namespace** adopts the kept Secret and can still log in. To start from scratch, delete both: `kubectl delete pvc <release>-mongodb-persistent-storage-<release>-mongodb-0 secret <release>-mongodb-root-secret`.

- **Render with a cluster connection.** Credentials are kept stable by reading the live Secrets with `lookup`. Under `helm template`, or a GitOps tool that renders without cluster access (for example Argo CD), `lookup` returns nothing, so every render generates a new username and password. The postgres chart behaves the same way. Install and upgrade with `helm install` / `helm upgrade`.
- **Don't hand-edit `MONGO_PASSWORD`.** The init Job's name hashes the username but deliberately not the password, so changing only the password in the Secret does not re-run the Job, and mongod keeps the old password. If the Secret is deleted instead, the next upgrade generates a new username as well, which changes the Job name and re-runs it.

---

## Monitoring

A `percona/mongodb_exporter` sidecar serves metrics on port `2121`, scraped through the `<release>-mongodb` ServiceMonitor. The `<release>-mongodb` PrometheusRule raises:

| Alert | Fires when |
|-------|------------|
| `MongodbDown` | `mongod` is unreachable, or the exporter has stopped reporting (pod or exporter gone) for 1 minute |
| `MongodbRestarted` | `mongod` has been up for less than a minute |
| `MongodbTooManyConnections` | more than 80% of available connections are in use for 2 minutes |

Every alert carries a `service` label set to `name` (the owning service), or to the release name when `name` is empty, so alerts can be routed to whoever owns the app.

The rule is named `<release>-mongodb`, not after the bare release name, so an application chart can bundle mongodb next to redis or postgres without a PrometheusRule name collision.

---

## Contributing

Please refer to [CONTRIBUTING.md](../../CONTRIBUTING.md).

## License

This project is licensed under the [LICENSE](../../LICENSE).
