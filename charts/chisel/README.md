<a href="https://zop.dev/zopday/app/deploy?install=chisel"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" align="right" height="36"></a>

# Chisel Helm Chart

[Chisel](https://github.com/jpillora/chisel) is a tunnel server for TCP and reverse SOCKS tunnels over a websocket, secured with SSH.
Clients dial the server over a websocket and open tunnels through it.
With reverse remotes, a client opens a listener on the server, for example a SOCKS proxy into the client's own network.

This chart runs one chisel server.
Its users come from a Secret, or from a sidecar that polls a gRPC method and keeps the users file in sync.

---

## Prerequisites

- Kubernetes 1.26+
- Helm 3+
- An ingress controller, only with `ingress.enabled=true`. The default annotations suit ingress-nginx.
- A CNI that enforces NetworkPolicy, only with `networkPolicy.enabled=true`
- The Prometheus Operator CRDs, only with `alerts.enabled=true`

---

## Install

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
helm install tunnel zopdev/chisel
```

The chart generates a server key and one user.
Read the user and the fingerprint:

```bash
kubectl get secret tunnel-chisel-auth -o jsonpath='{.data.users\.json}' | base64 -d
kubectl logs deploy/tunnel-chisel -c chisel | grep Fingerprint
```

Connect a client:

```bash
chisel client --fingerprint <fingerprint> --auth chisel:<password> \
  http://tunnel-chisel:8080 R:0.0.0.0:11001:socks
```

Give `--fingerprint` in full, all 44 characters with the trailing `=`.
chisel 1.12 clients reject a shortened fingerprint.

---

## Configuration

| Key | Default | Description |
|---|---|---|
| `image.repository` | `zopdev/chisel` | Built from [`images/chisel`](../../images/chisel), amd64 only. On arm64 nodes, use `jpillora/chisel` with a chisel version tag. |
| `image.tag` | `v0.0.1` | `v0.0.1` holds chisel 1.12.1. With `jpillora/chisel`, the tag is the chisel version and must be `1.11.7` or later for per-user ACLs. |
| `keepalive` | `25s` | Websocket keepalive. `0s` turns it off. |
| `key.existingSecret` | `""` | Secret with `server.key`. Empty generates one. Fixed after install. |
| `auth.existingSecret` | `""` | Secret with `users.json`. Empty (and feed off) generates one user. |
| `feed.enabled` | `false` | Keep `users.json` in sync from a gRPC method. |
| `feed.address` | `""` | `host:port` of the gRPC server. Called without TLS. |
| `feed.method` | `""` | Full method name, e.g. `pkg.Service/GetAuthFile`. |
| `feed.proto` | `""` | The `.proto` that defines the method, as text. |
| `feed.responseField` | `""` | Response field with the users file, e.g. `authFileJson`. |
| `feed.interval` | `5` | Seconds between polls. |
| `reversePorts.start`, `reversePorts.end` | `0`, `0` | Reverse ports, on their own ClusterIP Service `<release>-chisel-reverse`. At most 101, from 1024 up. `0` means none. |
| `service.type` | `ClusterIP` | Type of the websocket Service: `ClusterIP`, `NodePort` or `LoadBalancer`. The reverse ports Service is always `ClusterIP`. |
| `ingress.enabled` | `false` | Create an Ingress. Needs `ingress.host`. |
| `ingress.className` | `""` | IngressClass. |
| `ingress.host` | `""` | Hostname. |
| `ingress.path`, `ingress.pathType` | `/`, `Prefix` | Path clients dial. |
| `ingress.annotations` | ingress-nginx websocket settings | No buffering, 3600 s timeouts. |
| `ingress.tlsSecretName` | `""` | TLS Secret for the host. |
| `networkPolicy.enabled` | `false` | Create a NetworkPolicy. |
| `networkPolicy.reversePortsFrom` | `[]` | Peers that may reach the reverse ports. |
| `alerts.enabled` | `false` | PrometheusRule on kube-state-metrics. |
| `resources` | 50m / 64Mi, limit 512Mi | chisel container resources. |
| `nodeSelector`, `tolerations`, `affinity` | empty | Pod scheduling. |

The websocket port is always `8080`, on the pod and on the Service `<release>-chisel`.

### Server key

Clients pin the server's fingerprint, so the key must not change.
The generated key is read back on every upgrade and kept on `helm uninstall`.
Tools that render with `helm template`, such as Argo CD, cannot read it back and would make a new key on every sync.
With them, make the key once and set `key.existingSecret`:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/out" zopdev/chisel:v0.0.1 server --keygen /out/server.key
kubectl create secret generic chisel-key --from-file=server.key
```

### Users

chisel lets everyone in when the users file is empty.
The chart never starts chisel without at least one user.

- **Generated** (default): one user `chisel` that may open only reverse listeners on all interfaces (`^R:0\.0\.0\.0:[0-9]+$`), with a random password, kept across upgrades and on uninstall. It cannot open forward remotes, so it cannot reach what the pod can reach.
- **Static**: `auth.existingSecret` names a Secret with a `users.json` entry, in chisel's format: `{"user:pass": ["<remote-regex>", ...]}`. It must hold at least one user. chisel reloads it when the kubelet updates the mounted Secret, so no restart is needed.
- **Feed**: `feed.enabled=true`. See below.

### Feed

The feed sidecar calls `feed.method` on `feed.address` every `feed.interval` seconds with an empty request, without TLS.
It reads `feed.responseField` from the response, a string that holds the whole `users.json`, and writes it when it changed.
chisel reloads the file on its own.

- Before the first good answer, chisel has only a placeholder user that can open nothing.
- An empty or invalid answer, or a failed call, keeps the last good file. Open tunnels keep working.
- The file is written in place in an in-memory volume, because Secret and ConfigMap volumes are read-only. chisel 1.12 watches the file's directory and reloads about 100 ms after a write.

A subset of the `.proto` with the service, the method and its two messages is enough:

```yaml
feed:
  enabled: true
  address: users.apps.svc.cluster.local:9000
  method: users.UserService/GetTunnelUsers
  responseField: authFileJson
  proto: |
    syntax = "proto3";
    package users;
    service UserService {
      rpc GetTunnelUsers(GetTunnelUsersRequest) returns (GetTunnelUsersResponse);
    }
    message GetTunnelUsersRequest {}
    message GetTunnelUsersResponse {
      string auth_file_json = 1;
    }
```

### Reverse ports

A client's reverse listener lives on the server pod.
To reach it from other pods, put its port in `reversePorts.start`..`reversePorts.end`.
The chart puts these ports on a separate Service, `<release>-chisel-reverse`, which is always `ClusterIP`, so `service.type` never exposes them.
The client must bind it on all interfaces, `R:0.0.0.0:<port>:socks`; a bare `R:<port>:socks` binds to `127.0.0.1` inside the pod.

Point the SOCKS consumers at the reverse Service, not the websocket one.
For a release named `tunnel`, a SOCKS consumer in another namespace uses `socks5://tunnel-chisel-reverse.<namespace>.svc.cluster.local:<port>`.

A reverse port has no login of its own: whoever reaches it uses the tunnel.
Turn on `networkPolicy.enabled` and list the allowed peers in `networkPolicy.reversePortsFrom`.

### Ingress

Clients do not follow redirects.
For a path other than `/`, set `ingress.pathType=Exact`: ingress-nginx answers `/tunnel` with a redirect for a `Prefix` of `/tunnel/`.
chisel ignores the path, so no rewrite is needed.
Clients dial `https://<host><path>` exactly as written, with no trailing slash.

### NetworkPolicy

- Ingress: the websocket port from anywhere (it has its own login), the reverse ports from `reversePortsFrom` only.
- Egress: with the feed on, DNS (ports 53 and 5353) and the port of `feed.address`. With the feed off, none.
- NetworkPolicy matches the destination pod's port, after Service translation. So `feed.address` must name a Service whose `port` equals its `targetPort`, for example a gRPC Service that maps 9000 to 9000.
- chisel needs no egress for reverse tunnels. Forward remotes, where the server dials out, do not work with the policy on.

---

## Uninstall

```bash
helm uninstall tunnel
```

The generated Secrets are kept, so a reinstall with the same release name keeps the fingerprint and the password.
Delete them by hand to remove everything:

```bash
kubectl delete secret tunnel-chisel-key tunnel-chisel-auth
```

---

## Notes

- `zopdev/chisel` is built for amd64 only. On arm64 nodes, the pod fails with `exec format error`. There, set `image.repository: jpillora/chisel` and `image.tag` to a chisel version (`1.11.7` or later), for example `1.12.1`.
- One replica, by design: reverse ports live on the pod the client is connected to. Updates use the `Recreate` strategy, so two pods never share the Service.
- The pod runs as uid 100 (the grpcurl image's user) with a read-only root filesystem and no service account token.
- `/health` backs both probes.
- The server must be chisel 1.11.7 or later. Older servers do not enforce the per-user ACLs in `users.json`.

---

## License

This project is licensed under the [LICENSE](../../LICENSE).
Chisel itself is MIT licensed.
