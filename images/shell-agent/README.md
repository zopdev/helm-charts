# shell-agent Docker Image

The shell-agent Docker image packages the ZopDay **VM shell agent** — the process that gives a browser an interactive terminal on a deployment VM.

> **Why an agent at all.** A ZopDay VM lives in the customer's own cloud account, behind their security groups. There is no inbound path the platform can rely on, so a terminal cannot be served by connecting *to* the machine. The agent inverts it: it runs on the VM, dials *out* to the platform's relay, and holds a long poll. Keystrokes travel down that connection and output comes back up it. This is the same shape AWS SSM, Teleport and Coder use, and for the same reason.

> **This image is a RUNTIME, not a carrier.** Unlike [`scale-to-zero`](../scale-to-zero/README.md), which exists only so a binary can be copied out of it, this container actually runs for the life of the VM — with the host PID namespace, `CAP_SYS_ADMIN` and the Docker socket, because a host shell has to escape the container and a container shell is `docker exec` against the host's daemon.

Docker Hub is used rather than a private registry for the same reason `scale-to-zero` uses it: Docker is already a baseline component on every pool VM and those VMs already pull public images — no new registry auth or network path.

---

## Components & Versions

| Component   | Version | Description                                                      |
|-------------|---------|------------------------------------------------------------------|
| Go          | 1.26.0  | Build toolchain. Must satisfy the `go` directive in `go.mod`     |
| Alpine      | 3.22    | Final base image                                                  |
| docker-cli  | alpine  | A container shell is `docker exec` against the host's socket      |
| tmux        | alpine  | Makes a dropped connection reattach instead of losing the work    |
| util-linux  | alpine  | `nsenter` — how a host shell gets out of the container            |
| bash        | alpine  | The login shell both scopes run                                   |

> **Source lockstep (critical).** The Go sources under `shell-agent/` are a verbatim copy of `backend/shell-agent/` in the ZopDay deployer repo. They are the same program, and the relay protocol — `shell-v1` tokens, the poll and events paths, the command shapes — is implemented **independently** on the platform side. A change to either half that is not mirrored here ships an agent that cannot talk to the relay, which from the UI looks exactly like a VM with no agent installed. Re-copy the whole directory rather than hand-patching it, so a drift shows up as a diff.

---

## Prerequisites

- Docker 20.10+

---

## Build Image

From the repository root:

```bash
docker build -f images/shell-agent/Dockerfile -t shell-agent:latest images/
```

Override the pinned versions at build time if needed:

```bash
docker build -f images/shell-agent/Dockerfile \
  --build-arg GO_VERSION=1.26.0 \
  --build-arg ALPINE_VERSION=3.22 \
  -t shell-agent:latest images/
```

The build fails fast if the binary it produced cannot start, and again on the published image if a required tool is missing.

---

## Verify

```bash
docker run --rm shell-agent:latest
# shell-agent: required configuration is missing: ZOP_SHELL_AGENT_TOKEN, ZOP_SHELL_RELAY_URL, ZOP_SHELL_SPACE_ID

docker run --rm --entrypoint sh shell-agent:latest -c 'command -v nsenter docker tmux bash'
# /usr/bin/nsenter
# /usr/bin/docker
# /usr/bin/tmux
# /bin/bash
```

Refusing an empty configuration **is** the smoke test: it proves the binary runs on this base image and that the error path names every variable an operator has to set, rather than the first one it happened to check.

---

## Usage

The consumer is the ZopDay deployer's `shell-agent` VM component, which **runs** the container:

```bash
docker run -d --name zop-shell-agent \
  --restart unless-stopped \
  --pid=host \
  --cap-add=SYS_ADMIN \
  --cap-add=SYS_PTRACE \
  --security-opt apparmor=unconfined \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e ZOP_SHELL_RELAY_URL \
  -e ZOP_SHELL_AGENT_TOKEN \
  -e ZOP_SHELL_SPACE_ID \
  zopdev/shell-agent:v0.0.1
```

**All four flags are required.** A host shell runs `nsenter -t 1 -m -u -i -n -p` to enter PID 1's namespaces:

| Flag | Why |
|---|---|
| `--pid=host` | makes PID 1 the host's init rather than this container's |
| `--cap-add=SYS_ADMIN` | permits `setns()` at all |
| `--cap-add=SYS_PTRACE` | permits reaching PID 1's namespace files |
| `--security-opt apparmor=unconfined` | Docker's default profile denies the mount-namespace transition on Ubuntu |

Measured on a real Ubuntu 24.04 VM with every combination: dropping any one gives `reassociate to namespaces failed: Operation not permitted`. `SYS_ADMIN` alone is not enough, `SYS_PTRACE` alone is not either, seccomp is irrelevant, and `SYS_CHROOT` is not needed.

The apparmor line is the one a Docker-Desktop-only test will miss. Desktop's VM ships no AppArmor, so three flags look sufficient there and then fail on every Ubuntu host. On a host without AppArmor the option is simply ignored, so it is safe to pass unconditionally.

Dropping any of the three does not silently give a container shell. The agent probes whether PID 1 lives in a different mount namespace and **refuses** the host scope when it does not, so a wrong run line surfaces as *"a shell on the VM itself is not available on this agent"* rather than a shell on the wrong machine.

`--privileged` also works and is deliberately not used: it grants every capability on a customer's machine to buy one we can name.

No port is published: the agent listens on nothing and only ever dials out.

### Environment

| Variable | Required | Description |
|---|---|---|
| `ZOP_SHELL_RELAY_URL`   | yes | Where the agent dials out to. **https only**, except a loopback host for local development — the token is a bearer credential sent on every poll |
| `ZOP_SHELL_AGENT_TOKEN` | yes | This VM's `shell-v1` token, minted by the deployer at install time and selected on the VM from the per-space blob |
| `ZOP_SHELL_SPACE_ID`    | yes | The VM child space this agent speaks for |

---

## File Structure

```
images/shell-agent/
├── Dockerfile                     # two-stage: Go build + assertions, then the runtime image
├── README.md
├── go.mod / go.sum
├── cmd/shell-agent/main.go        # config, signals
└── internal/
    ├── relay/relay.go             # dial out, poll, report
    └── session/session.go         # the PTY, tmux, nsenter
```

---

## Features

- Outbound-only: no inbound port, no listener, nothing to expose on the VM
- Host and container shells from one agent (`nsenter` and the Docker socket)
- tmux-backed sessions, so a dropped connection reattaches instead of losing the work
- Idle terminals reaped on the agent's own side, so a shell cannot outlive the platform
- https-only relay URL, loopback excepted for development
- Static CGO-free binary, stripped — ~19 MB image

---

## Publish

The image is published via the `Image Deployment` GitHub Actions workflow. Push a tag in the form `shell-agent-image-v<N>` to trigger the build:

```bash
git tag shell-agent-image-v0.0.1
git push origin shell-agent-image-v0.0.1
```

This produces:

- `zopdev/shell-agent:v0.0.1`
- `zopdev/shell-agent:latest`

The image tag is an **independent, incrementing version** — deliberately *not* the Go version or the deployer's release. Decoupling them means a dependency bump or a CVE rebuild of the same agent is just the next image tag.

| Image tag | Go     | Alpine |
|---|--------|---|
| `v0.0.1`  | 1.26.0 | 3.22 |

Consumers pin the **full tag and digest** (`zopdev/shell-agent:v0.0.1@sha256:…`), never `latest`. The digest is what makes an install reproducible: a tag can be moved, and this container runs as root with the Docker socket on a customer's machine.

After publishing, update the pin in the deployer's `backend/deployer/configs/vm-components.yaml`:

```bash
docker buildx imagetools inspect zopdev/shell-agent:v0.0.1 --format '{{.Manifest.Digest}}'
```

---

## Contributing

We welcome contributions to improve this Docker image. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.
