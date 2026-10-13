<a href="https://zop.dev/zopday/app/deploy?install=heyform"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" align="right" height="36"></a>

# HeyForm Helm Chart

[HeyForm](https://github.com/heyform/heyform) is an open-source form builder for surveys, quizzes, polls and conversational forms.

HeyForm cannot start on its own: it needs MongoDB and a Redis-compatible store, and exits about 30 seconds after start without them.
This chart runs all three and wires them together, so a default install comes up ready.

| Pod | Image | Volume |
|---|---|---|
| HeyForm | `heyform/community-edition:v3.0.3` | uploads, 5Gi |
| MongoDB | `percona/percona-server-mongodb:4.4.29-28-multi` | data, 10Gi |
| Redis | `redis:7.2.16-alpine` | append-only file, 1Gi |

All three run as non-root. MongoDB and Redis each require a password, generated on install.

---

## Prerequisites

- Kubernetes 1.26+
- Helm 3+
- A default StorageClass (or `storageClassName`)
- About 250m CPU and 1Gi of memory free in requests
- The Prometheus Operator CRDs, only with `alerts.enabled=true`

---

## Install

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
helm install heyform zopdev/heyform
```

The first start pulls three images; HeyForm itself is ready within about a minute of its image reaching the node.

Open it with a port-forward:

```bash
kubectl port-forward svc/heyform 9157:80
```

Then go to http://localhost:9157 and create the first account from the sign-up page.
There is no default login.

Use port 9157 exactly. HeyForm is configured with one public URL, and sign-in only works at that URL (see below).

---

## Serving it on a hostname

HeyForm builds its links, its CORS allow-list and its cookie domain from one URL, `publicUrl`.
The browser must use exactly that URL, and it must be `https`: the image runs with `NODE_ENV=production`, which marks the session cookie `Secure`, and a browser drops that cookie over plain http on any host but localhost.

With the chart's ingress:

```yaml
ingress:
  enabled: true
  className: nginx
  host: forms.example.com
  tlsSecretName: forms-example-com-tls
```

`publicUrl` then defaults to `https://forms.example.com` and `trustProxy` to `1`.

With an ingress or load balancer the chart did not create (for example a hostname added from the ZopDay console), set both yourself:

```yaml
publicUrl: https://forms.example.com
trustProxy: "1"
```

`trustProxy` is Express's trust-proxy setting: the number of proxies in front of HeyForm that may set `X-Forwarded-For`.
HeyForm rate-limits by client address. Left at `false` behind a proxy, every visitor shares one limit; set higher than the real number of proxies, a client can forge its address.
Use `1` for one ingress controller and `2` for a load balancer in front of one.

---

## Secrets

On install the chart generates a Secret named after the release with four keys, and reads it back on every upgrade:

| Key | Used for |
|---|---|
| `SESSION_KEY` | Sealing session cookies. A new value signs everyone out. |
| `FORM_ENCRYPTION_KEY` | Sealing form access tokens. A new value voids issued ones. |
| `MONGO_PASSWORD` | The bundled MongoDB's `heyform` user. |
| `REDIS_PASSWORD` | The bundled Redis. |

HeyForm derives its AES key from each of the first two with an HMAC, so any string works; there is no length or format to meet.

To supply your own, create a Secret with those keys and set `secrets.existingSecret`.
Do this at install time: MongoDB stores its password on the volume at first start and does not read it again.

The Secret and all three volumes are kept on `helm uninstall`, because the MongoDB volume only opens with that password.
Reinstalling under the same release name and namespace picks them up again.
To remove everything:

```bash
helm uninstall heyform
kubectl delete secret heyform
kubectl delete pvc heyform-uploads data-heyform-mongodb-0 data-heyform-redis-0
```

---

## Mail

Without SMTP HeyForm still works, but cannot send password resets, team invites or submission notifications.

```yaml
env:
  SMTP_FROM: "HeyForm <noreply@example.com>"
  SMTP_HOST: smtp.example.com
  SMTP_PORT: "465"
  SMTP_SECURE: "true"
  SMTP_USER: noreply@example.com
extraEnvFrom:
  - secretName: heyform-smtp   # holds SMTP_PASSWORD
```

Any other HeyForm variable goes the same way: plain ones in `env`, secret ones in a Secret listed under `extraEnvFrom`.
Variables the chart sets itself (`APP_HOMEPAGE_URL`, `TRUST_PROXY`, `MONGO_URI`, `REDIS_HOST`, the keys above) are rejected in `env`.

---

## Using your own MongoDB or Redis

```yaml
mongodb:
  enabled: false
externalMongodb:
  uri: mongodb://mongo.example.com:27017/heyform
redis:
  enabled: false
externalRedis:
  host: redis.example.com
extraEnvFrom:
  - secretName: heyform-stores   # MONGO_USER, MONGO_PASSWORD, REDIS_PASSWORD
```

The chart refuses to render when a bundled store is off and no external one is given, when both are given, or when the MongoDB URI carries a password.

---

## Values

| Value | Default | |
|---|---|---|
| `version` | `v3.0.3` | HeyForm image tag |
| `publicUrl` | `""` | URL HeyForm is opened at; see above |
| `trustProxy` | `""` | Express trust-proxy value; see above |
| `service.type` / `service.port` | `ClusterIP` / `80` | |
| `ingress.enabled` / `className` / `host` / `annotations` / `tlsSecretName` | off | |
| `secrets.existingSecret` | `""` | Use your own Secret instead of a generated one |
| `diskSize` | `5Gi` | Uploads volume |
| `storageClassName` | `""` | For all three volumes; empty uses the cluster default |
| `resources` | 100m / 384Mi, limit 1Gi | HeyForm pod |
| `mongodb.enabled` / `version` / `diskSize` / `resources` | on, `4.4.29-28-multi`, `10Gi`, 100m / 512Mi, limit 1Gi | |
| `externalMongodb.uri` | `""` | |
| `redis.enabled` / `version` / `diskSize` / `resources` | on, `7.2.16-alpine`, `1Gi`, 50m / 64Mi, limit 256Mi | |
| `externalRedis.host` / `port` | `""` / `6379` | |
| `alerts.enabled` | `false` | PrometheusRule on kube-state-metrics |
| `env` | `{}` | Plain environment variables |
| `extraEnvFrom` | `[]` | Secrets loaded as environment variables |
| `nodeSelector` / `tolerations` / `affinity` | empty | Applied to all three pods |

---

## Limits to know about

- **One HeyForm pod.** Uploads are on a ReadWriteOnce volume, so the Deployment uses `Recreate` and an upgrade has a short outage.
- **MongoDB is a single standalone server**, not a replica set, and 4.4 is past its upstream end of life. It is what HeyForm's own compose file runs. Back the volume up.
- **Redis instead of KeyDB.** HeyForm's compose file uses KeyDB, which only publishes per-architecture version tags. The official Redis image speaks the same protocol and has one tag for amd64 and arm64.
- **No `/metrics`.** HeyForm does not expose Prometheus metrics, so there is no ServiceMonitor; the alerts read kube-state-metrics.
