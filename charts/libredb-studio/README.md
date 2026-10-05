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
| `version` | `0.17.0` | LibreDB Studio release, the tag of `ghcr.io/libredb/libredb-studio`. |
| `auth.adminEmail` | `admin@libredb.org` | Email the admin signs in with. |
| `auth.existingSecret` | `""` | Secret with `JWT_SECRET` (32+ characters) and `ADMIN_PASSWORD`. Empty generates one. |
| `auth.insecureCookie` | `false` | Session cookie without the Secure flag. See below. |
| `diskSize` | `1Gi` | Volume for the SQLite store and agent runs, on the default StorageClass. Fixed after install. |
| `ingress.enabled` | `false` | Create an Ingress. Needs `ingress.host`. |
| `ingress.className` | `""` | IngressClass. |
| `ingress.host` | `""` | Hostname. |
| `ingress.tlsSecretName` | `""` | TLS Secret for the host. |
| `alerts.enabled` | `false` | PrometheusRule on kube-state-metrics. |
| `resources` | 100m / 256Mi, limit 512Mi | Pod resources. |
| `env` | `{}` | Plain environment variables. |
| `extraEnvFrom` | `[]` | Existing Secrets loaded as environment variables. |
| `nodeSelector`, `tolerations`, `affinity` | empty | Pod scheduling. |

Variables the chart sets itself (storage, auth, port, bind address) are refused in `env`, so a typo cannot quietly switch the storage off.

### Secrets

The generated Secret holds `JWT_SECRET` and `ADMIN_PASSWORD`.
`JWT_SECRET` also seals the passwords of saved connections, so it never changes on upgrade.
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
