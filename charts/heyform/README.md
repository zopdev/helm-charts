<a href="https://zop.dev/zopday/app/deploy?install=heyform"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" align="right" height="36"></a>

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
helm install heyform zopdev/heyform
```

Any release name works; MongoDB and Redis are wired in by `<release>-…` names. Install **one HeyForm per namespace**: the Deployment (`heyform-app`) and uploads PVC (`heyform-uploads`) have fixed names, and don't name the release `heyform-app` (its PrometheusRule would clash with the redis one).

`SESSION_KEY` and `FORM_ENCRYPTION_KEY` are generated for each install into the `<release>-app-secret` Secret and kept across upgrades, so there is nothing to set.

Then open it:

```bash
kubectl port-forward svc/heyform-app 9157:80
# http://localhost:9157
```

On a fresh install the HeyForm pod waits in an init container until Redis accepts connections and MongoDB accepts HeyForm's own credentials (the user is created by the mongodb init Job). HeyForm exits at boot if either is missing, so starting it any earlier would cost a restart. If they are not ready within 10 minutes the init container fails with the last error in its log (`kubectl logs deploy/heyform-app -c heyform-app-init`).

## Uninstall Helm Chart

```bash
helm uninstall heyform
```

Uninstall **keeps your data**: the MongoDB and Redis volumes (as with any StatefulSet), the `heyform-uploads` volume, the MongoDB root Secret and `<release>-app-secret` (`helm.sh/resource-policy: keep`). `FORM_ENCRYPTION_KEY` and the MongoDB password must match the retained data, so reinstall with the **same release name in the same namespace** and it picks them up again. To start from scratch, delete those PVCs and Secrets as well.

---

## Configuration

| Input | Description | Default |
|-------|-------------|---------|
| `service.env.APP_HOMEPAGE_URL` | Public address HeyForm is reached at. The login cookie is scoped to its hostname, so it must match what users type into the browser | `http://localhost:9157` |
| `autoVerifyEmail` | Mark every account's email as verified automatically, so signup works without SMTP (see below) | `true` |
| `service.image` | HeyForm image | `heyform/community-edition:v3.0.3` |
| `service.nginx.host` | Hostname for the Ingress. Empty means no Ingress | `""` |
| `service.nginx.tlsSecretName` | TLS secret for that host | `""` |
| `service.minCPU` / `service.maxCPU` | CPU request / limit | `250m` / `1000m` |
| `service.minMemory` / `service.maxMemory` | Memory request / limit | `512Mi` / `1Gi` |
| `service.volumeMounts.pvc[0].storage` | Size of the uploads volume (`/app/packages/server/static/upload`) | `10Gi` |
| `mongodb.diskSize` | MongoDB volume size | `10Gi` |
| `redis.diskSize` | Redis volume size | `10Gi` |

Any other [HeyForm environment variable](https://docs.heyform.net/configuration), such as SMTP or social login, can be added under `service.env`.

When you set `service.nginx.host`, also set `service.env.APP_HOMEPAGE_URL` to that public address (e.g. `https://forms.example.com`): HeyForm scopes its login cookie to that host, and the chart refuses to render if the host is set while the URL still points at localhost. Behind the ingress, `service.env.TRUST_PROXY: "1"` makes HeyForm use the client address from `X-Forwarded-For`.

Sessions live in the bundled Redis, which has no persistence: restarting the Redis pod signs every user out (forms and submissions are in MongoDB and are unaffected).

HeyForm runs as a single replica with the `Recreate` update strategy: uploads live on a ReadWriteOnce volume, which several pods cannot share, and a rolling update's surge pod on another node would wait forever for it.

---

## Email verification and SMTP

HeyForm makes every password signup confirm a 6-digit code sent by email, and v3.0.3 has no setting to turn that off (its `VERIFY_USER_EMAIL` variables exist but are never read). Without SMTP, nobody could get past the verify screen.

So, **by default (`autoVerifyEmail: true`) the chart auto-verifies accounts.** A small `heyform-email-autoverify` Deployment marks every account's email as verified in MongoDB within about 2 seconds of signup. HeyForm's web app still shows the "Verify email address" screen right after signup; click the HeyForm logo (or reload `/`) and you are in, no code needed.

This is a workaround, not a HeyForm feature: it relies on HeyForm's internal field names and is re-checked on every image bump.

**What it means:** anyone who can reach the sign-up page can create an account with any email address, and nothing checks that they own it. If HeyForm is reachable from outside, create the accounts you need and then close public sign-up with `service.env.APP_DISABLE_REGISTRATION: "true"`; invited users can still join a workspace.

**SMTP is optional.** Without it, signup and login work, but nothing that sends mail does: password reset, workspace invites and submission notifications. To use it, and have users verify their address for real:

```bash
# service.env ends up in a ConfigMap, so keep the password in a Secret
kubectl create secret generic heyform-smtp --from-literal=SMTP_PASSWORD='...'
```

```yaml
autoVerifyEmail: false
service:
  env:
    SMTP_FROM: "HeyForm <noreply@example.com>"
    SMTP_HOST: "smtp.example.com"
    SMTP_PORT: "465"
    SMTP_USER: "..."
    SMTP_SECURE: "true"
  envFrom:
    secrets:
      - "{{ .Release.Name }}-app-secret"   # keep: generated session/encryption keys
      - heyform-smtp
```

---

## Contributing

Please refer to [CONTRIBUTING.md](../../CONTRIBUTING.md).

## License

This project is licensed under the [LICENSE](../../LICENSE).
