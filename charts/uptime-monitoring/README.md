# Uptime Monitoring Helm Chart

This Helm chart deploys HTTPS uptime and TLS certificate monitoring: a
[Blackbox Exporter](https://github.com/prometheus/blackbox_exporter) that probes
the URLs you list, and a Prometheus that scrapes it and holds the results.

It answers two questions about anything reachable over HTTP(S) — is it up, and
how long until its certificate expires — without needing an agent on the target.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Outbound network access from the cluster to whatever you want to probe

---

## Install

```bash
helm repo add zop https://helm.zop.dev
helm repo update
helm install uptime zop/uptime-monitoring --set 'targets[0]=https://example.com'
```

Nothing is probed until you list targets — `targets` defaults to an empty list,
so an install with no values produces a running but idle pair of pods.

A values file is easier once you have more than one:

```yaml
targets:
  - https://example.com
  - https://api.example.com/health
  - https://zop.dev
```

```bash
helm install uptime zop/uptime-monitoring -f targets.yaml
```

---

## Verify

```bash
kubectl get pods -l app=blackbox-exporter
kubectl get pods -l app.kubernetes.io/name=prometheus

# Prometheus UI (the Service is release-prefixed; the exporter's is not)
kubectl port-forward svc/<release>-prometheus 9090:9090
open http://localhost:9090/targets
```

Every configured target should appear under the `blackbox` job and report `UP`.

Note that the Blackbox objects (`blackbox-exporter`, `blackbox-config`,
`prometheus-config`) are not release-prefixed, so two releases of this chart in
one namespace will collide. Install it once per namespace.

---

## What to query

| Question | Query |
|---|---|
| Is the target up? | `probe_success` |
| Days until the certificate expires | `(probe_ssl_earliest_cert_expiry - time()) / 86400` |
| How slow is the probe? | `probe_duration_seconds` |
| Which HTTP status came back? | `probe_http_status_code` |

A certificate-expiry alert is the usual reason to run this — 30 days of warning
is enough to renew without hurry:

```promql
(probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
```

---

## Configuration

| Key | Description | Default |
|---|---|---|
| `targets` | HTTP/HTTPS URLs to probe; each must start with `http://` or `https://` | `[]` |
| `blackbox.image` | Blackbox Exporter image | `prom/blackbox-exporter:v0.25.0` |
| `blackbox.servicePort` | Port the exporter is served on | `9115` |
| `prometheus.image` | Prometheus image | `prom/prometheus:v2.49.0` |
| `prometheus.scrapeInterval` | How often each target is probed | `30s` |
| `prometheus.servicePort` | Port Prometheus is served on | `9090` |

Probing is not free for the target: a 30s interval means 2,880 requests per day
per URL. Raise `scrapeInterval` for endpoints that are expensive to serve or
rate limited.

This chart runs its own Prometheus rather than emitting a ServiceMonitor, so it
is self-contained and needs no Prometheus Operator — but its data is also
separate from a cluster-wide Prometheus, and is not retained across pod restarts.

---

## Upgrading & Uninstalling

```bash
helm upgrade uptime zop/uptime-monitoring -f targets.yaml
helm uninstall uptime
```

Both pods are stateless, so nothing is left behind — and equally, probe history
does not survive an upgrade. Ship the metrics elsewhere if you need to keep them.
