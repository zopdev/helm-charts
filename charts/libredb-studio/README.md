<a href="https://zop.dev/zopday/app/deploy?install=libredb-studio"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" align="right" height="36"></a>

# LibreDB Studio Helm Chart

[LibreDB Studio](https://github.com/libredb/libredb-studio) is an open-source, web-based SQL IDE.
It connects to PostgreSQL, MySQL, SQL Server, Oracle, MongoDB, Redis, ClickHouse, Elasticsearch, Kafka and more from one workspace, with an optional AI query assistant.

This chart runs one instance.
Its own data (saved connections, queries, history, agent runs) lives in SQLite on a volume.
The databases you connect to are not part of this chart.

---

## Prerequisites

- Kubernetes 1.26+
- Helm 3+
- A default StorageClass
- The Prometheus Operator CRDs, only with `alerts.enabled=true`

---

## Install

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
helm install studio zopdev/libredb-studio
```

Open it with a port-forward:

```bash
kubectl port-forward svc/studio-libredb-studio 3000:80
```

Then go to http://localhost:3000 and sign in as `admin@libredb.org`.
The password is generated on install:

```bash
kubectl get secret studio-libredb-studio -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d; echo
```

---

## Configuration

| Key | Default | Description |
|---|---|---|
| `version` | `""` | LibreDB Studio release, the tag of `ghcr.io/libredb/libredb-studio`. Empty uses the chart's `appVersion`. |
| `service.type` | `ClusterIP` | Kubernetes Service type: `ClusterIP`, `NodePort` or `LoadBalancer`. |
| `service.port` | `80` | Service port. |
| `auth.adminEmail` | `admin@libredb.org` | Email the admin signs in with. |
| `auth.existingSecret` | `""` | Secret with `JWT_SECRET` (32+ characters) and `ADMIN_PASSWORD`. Empty generates one. |
| `auth.insecureCookie` | `false` | Session cookie without the Secure flag. See below. |
| `diskSize` | `1Gi` | Volume for the SQLite store and agent runs, on the default StorageClass. Fixed after install. |
| `ingress.enabled` | `false` | Create an Ingress. Needs `ingress.host`. |
| `ingress.className` | `""` | IngressClass. |
| `ingress.host` | `""` | Hostname. |
| `ingress.annotations` | `{}` | Ingress annotations. |
| `ingress.tlsSecretName` | `""` | TLS Secret for the host. |
| `alerts.enabled` | `false` | PrometheusRule on kube-state-metrics. |
| `resources` | 100m / 256Mi, limit 512Mi | Pod resources. |
| `env` | `{}` | Plain environment variables. |
| `extraEnvFrom` | `[]` | Existing Secrets loaded as environment variables. |
| `nodeSelector`, `tolerations`, `affinity` | empty | Pod scheduling. |

Variables the chart sets itself (storage, auth, port, bind address) are refused in `env`, so a typo cannot quietly switch the storage off.

### Secrets

The generated Secret holds `JWT_SECRET` and `ADMIN_PASSWORD`.
`JWT_SECRET` also seals the passwords of saved connections, so it is read back on every upgrade.
To choose your own values, create a Secret with those two keys and set `auth.existingSecret`.

### AI assistant

Off until a model is configured.
Put the key in a Secret and the rest in `env`:

```bash
kubectl create secret generic studio-llm --from-literal=LLM_API_KEY=sk-...
```

```yaml
env:
  LLM_PROVIDER: openai
  LLM_MODEL: gpt-4o
extraEnvFrom:
  - secretName: studio-llm
```

Providers and every other variable: [.env.example](https://github.com/libredb/libredb-studio/blob/main/.env.example).

### Ingress and the session cookie

The session cookie is marked Secure.
Over https, including TLS terminated at a load balancer, nothing needs changing.
If the browser reaches Studio over plain http on a host other than localhost, the browser drops that cookie and login loops back to `/login`.
Serve TLS, or on a trusted network set `auth.insecureCookie=true`.

---

## Upgrade

Chart v0.0.1 ran LibreDB Studio 0.17.0 and v0.0.2 runs 1.2.0, so one `helm upgrade` crosses several releases. What a default install sees:

- Everyone signs in again, and for two separate reasons. 0.18.0 moves local accounts into the server-side store, and 1.2.0 renames the session cookie to `__Host-auth-token` on HTTPS, so a script that sends a saved session cookie over HTTPS has to use the new name.
- Editor tabs left open before the upgrade are not kept, because from 0.18.1 the first sign-in starts from the account's server data.
- `ADMIN_PASSWORD` only seeds the account on first start, from 0.18.0 on, so changing it afterwards in the generated Secret or in `auth.existingSecret` does not change the stored password. To change it, set the new value, add `ADMIN_PASSWORD_RESET: "true"` to `env` for one start, then remove that variable again, because every start applies it while it is set. The reset also ends that account's sessions and removes its passkeys.
- An install that enabled MCP through `env` loses the tokens issued before the upgrade, and they have to be created again.

Two notes about the chart rather than the release:

- `version` now defaults to empty, so the image tag follows the chart's `appVersion` and a later chart upgrade moves LibreDB Studio with it. Set `version` to a tag to pin it instead.
- The generated Secret is read back from the cluster on upgrade, so a hand-edited password survives. Under `helm template`, a client `--dry-run`, or a renderer with no cluster access it cannot be read back and both `JWT_SECRET` and `ADMIN_PASSWORD` render fresh, taking the saved connection passwords with them. Use `auth.existingSecret` in those workflows.

---

## Uninstall

```bash
helm uninstall studio
```

The volume and the generated Secret are kept, so a later install with the same release name picks up the same data and the same passwords.
Delete both by hand to remove everything:

```bash
kubectl delete pvc,secret studio-libredb-studio
```

---

## Notes

- One replica, by design: SQLite on a ReadWriteOnce volume and the agent's on-disk run ledger both need a single pod. Updates use the `Recreate` strategy.
- The pod runs as uid 1001 with a read-only root filesystem and no service account token.
- `/api/db/health` backs all three probes. It answers without touching any database.

---

## License

This project is licensed under the [LICENSE](../../LICENSE).
LibreDB Studio itself is MIT licensed.
