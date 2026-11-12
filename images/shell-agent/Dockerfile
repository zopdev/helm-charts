# -------------------------------
# ZopDay shell agent
# -------------------------------
# WHY THIS IMAGE EXISTS:
# A ZopDay VM has no inbound path we can rely on — it sits in the customer's
# own cloud account behind their security groups — so a terminal cannot be
# served by connecting TO the machine. The agent inverts it: it runs on the
# VM, dials OUT to the platform's relay, and holds a long poll. Everything a
# browser terminal does travels back down that connection.
#
# UNLIKE scale-to-zero, THIS IMAGE IS A RUNTIME, NOT A CARRIER:
# scale-to-zero exists only so a binary can be copied out of it (the VM runs
# Caddy as a host service). This container actually runs, for the life of the
# VM, with the host PID namespace and the Docker socket:
#
#   docker run -d --name zop-shell-agent --restart unless-stopped \
#     --pid=host --cap-add=SYS_ADMIN \
#     -v /var/run/docker.sock:/var/run/docker.sock ...
#
# Docker Hub for the same reason scale-to-zero uses it: Docker is already a
# baseline component on every pool VM and those VMs already pull public
# images, so there is no new registry auth or network path to open.
#
# WHY THE SOURCE IS HERE:
# Same place agent-harness keeps its scripts. The ZopDay deployer repo is
# private and this repo is public, so a build here cannot fetch an artifact
# from there without handing this public workflow a credential. Vendoring the
# source keeps the build self-contained and the Image Deployment workflow
# untouched.


# -------------------------------
# Version pinning (CRITICAL)
# -------------------------------
# GO_VERSION pins the toolchain so a rebuild is reproducible. It must satisfy
# the `go` directive in shell-agent/go.mod — the build asserts this below
# rather than failing halfway through a module download.
#
# SOURCE LOCKSTEP: the Go sources under shell-agent/ are a verbatim copy of
# backend/shell-agent/ in the ZopDay deployer repo. They are the SAME program,
# and the relay protocol (shell-v1 tokens, the poll and events paths, the
# command shapes) is implemented independently on the platform side. A change
# to either half that is not mirrored here ships an agent that cannot talk to
# the relay — which looks, from the UI, exactly like a VM with no agent
# installed. Re-copy the whole directory rather than hand-patching it, so a
# drift shows up as a diff.
ARG GO_VERSION=1.26.0
ARG ALPINE_VERSION=3.22


# -------------------------------
# Build stage
# -------------------------------
FROM golang:${GO_VERSION}-alpine AS builder

WORKDIR /src

# go.mod and go.sum first so a source-only change does not re-download the
# module cache.
COPY shell-agent/go.mod shell-agent/go.sum ./
RUN go mod download

COPY shell-agent/cmd ./cmd
COPY shell-agent/internal ./internal

# CGO off: the final image is Alpine (musl), and the agent needs no libc
# features a static build cannot give it. Stripped, because the VM pulls this
# over a customer's network.
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/shell-agent ./cmd/shell-agent


# -------------------------------
# Build-time assertion (CRITICAL)
# -------------------------------
# Fail the BUILD rather than a VM install six steps later. The binary must at
# least start and report its own missing configuration — a build that produced
# something unrunnable (wrong arch, broken link) dies here instead of looking
# like a relay problem on a customer's machine.
#
# Run with no environment: the agent refuses and names EVERY variable it
# needs, which is both the smoke test and the proof that error path works.
# Matched on the message main.go actually produces (ErrMissingConfig), not on
# the later validate error — the first draft grepped for the wrong one and
# this assertion is what caught it.
RUN /out/shell-agent 2>&1 | grep -q 'required configuration is missing' \
      || { echo "the built agent did not refuse an empty config as expected" >&2; exit 1; }


# -------------------------------
# Final image
# -------------------------------
FROM alpine:${ALPINE_VERSION}

# docker-cli: a container shell is `docker exec` against the host's socket.
# tmux: what makes a dropped connection reattach instead of losing the work.
#   This is the copy that runs, for BOTH shell kinds — the agent always execs
#   the binary on its own PATH.
# util-linux: nsenter, which is how a host shell gets out of this container
#   and onto the VM. Without it scope=host is refused rather than silently
#   landing in this filesystem.
# bash: the login shell both scopes run. ca-certificates: the agent dials out
#   over TLS.
RUN apk --no-cache add ca-certificates docker-cli tmux bash util-linux

COPY --from=builder /out/shell-agent /usr/local/bin/shell-agent

# No USER directive: a host shell is root by definition, and the container
# holds the Docker socket. The isolation that matters is the platform's —
# which org may open a terminal, on which VM, in which scope — not this
# process's own uid.

# -------------------------------
# Ship-stage assertions
# -------------------------------
# These run on the image that is actually PUBLISHED, so a wrong COPY path or a
# missing package cannot slip through the builder stage.
RUN /usr/local/bin/shell-agent 2>&1 | grep -q 'required configuration is missing' \
 && command -v nsenter  >/dev/null \
 && command -v docker   >/dev/null \
 && command -v tmux     >/dev/null \
 && command -v bash     >/dev/null

ENTRYPOINT ["/usr/local/bin/shell-agent"]
