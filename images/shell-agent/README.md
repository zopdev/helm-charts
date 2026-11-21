# shell-agent

The ZopDay VM shell agent — the process that makes an interactive terminal
possible on a deployment VM.

## What this image is

A **carrier**, not a runtime. Nothing runs this container.

It exists for one reason: the agent is a shell script, and the script still
has to reach the VM. Every ZopDay pool VM already pulls public Docker Hub
images, so an image is a delivery path that costs no new registry auth and no
new network route — the same reasoning, and the same shape, as
[`scale-to-zero`](../scale-to-zero), which carries an xcaddy-built `caddy`
binary the same way.

The VM's shell-access component copies the script out and throws the container
away:

```bash
CID=$(docker create zopdev/shell-agent:v0.0.1)
docker cp "$CID:/usr/local/bin/zop-shell-agent" /tmp/agent && docker rm "$CID"
```

It then runs as a **host systemd service**.

## Why a host process, not a container

Because the terminal has to be on the host, and the shortest way to be on the
host is to be on the host.

An earlier version ran the agent as a container and climbed back out with
`nsenter`. Doing that needs `--pid=host`, `CAP_SYS_ADMIN`, `CAP_SYS_PTRACE`,
`--security-opt apparmor=unconfined` and the Docker socket — every one of them
measured as necessary, on a customer's machine, to undo a containerisation
that bought nothing. Running on the host needs none of them.

A container shell is still `docker exec`, which needs no socket mount either:
it is the host's own Docker.

## Why a script, not a binary

`tmux` already owns the pseudo-terminal, survives a dropped connection, and
`pipe-pane -O` yields the raw byte stream the browser's terminal emulator
wants. `curl` does the long poll; `jq` parses the protocol. What remains is
small enough to read in one sitting.

It also matters that **this repository is public**. The agent's own source can
live here. A service's cannot — and an earlier revision of this directory
vendored ~1,900 lines of the private `zopnight` repository, which is the
reason the source here is now a script and nothing more.

## Publishing

Tag `shell-agent-image-v<N>`; `.github/workflows/image-deployment.yaml` builds
`images/shell-agent/Dockerfile` with `images/` as the context and pushes
`zopdev/shell-agent:v<N>`.

Pin the resulting **digest** in the deployer's `configs/vm-components.yaml`,
as every sibling component there does. A tag can be moved; this script runs as
root on a customer's machine.

## What the build asserts

The Dockerfile fails the BUILD rather than a VM install six steps later:

1. the script is at the exact path the copy-out step reads,
2. it is valid bash — a typo here is an agent that exits instantly on every VM
   it reaches, and
3. it refuses to start with its three required variables empty, so a
   half-configured install cannot look healthy.

## Contract with the platform

| | |
|---|---|
| `ZOP_SHELL_RELAY_URL` | the relay to dial — outbound only |
| `ZOP_SHELL_AGENT_TOKEN` | the per-VM HMAC token the deployer minted at install |
| `ZOP_SHELL_SPACE_ID` | the space this VM belongs to |

The agent polls `GET /agent/shell/poll` and reports with
`POST /agent/shell/events`. Both carry terminal bytes as **raw JSON strings**,
not base64 — the browser writes what arrives straight into its emulator.

Session names are `zopday-<sessionId>`, matching the deployer's own
`tmuxSessionName`, so `tmux ls` on the box shows the names the platform uses.

## Tests

The agent is exercised against the real relay from the zopnight repository:

```bash
cd backend/deployer
ZOP_SHELL_AGENT_SCRIPT=<path to zop-shell-agent.sh> \
  go test -tags=integration ./internal/shellrelay/ -run BashAgent -v
```

That test opens a host terminal, runs a command and asserts on its RESULT
(never on the echo of the input — a pty echoes what is typed, so matching the
typed string passes over a terminal that executed nothing), checks state
carries across commands, resizes the pty and asserts the shell sees it, and
confirms `tmux` is torn down on close.
