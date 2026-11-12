# -------------------------------
# ZopDay VM shell agent
# -------------------------------
# WHY THIS IMAGE EXISTS:
# The agent is a shell script, and a script still has to REACH the VM. Every
# ZopDay pool VM already pulls public Docker Hub images, so an image is a
# delivery path that needs no new registry auth and no new network route.
# Embedding the script in the deployer's vm-components.yaml instead would send
# it through YAML, a bash heredoc and the cloud run-command channel, where one
# mangled quote is a silently broken agent.
#
# THIS IMAGE IS A CARRIER, NOT A RUNTIME:
# Nothing runs this container. The VM's shell-access component pulls it and
# copies the script out, exactly as the scale-to-zero component does with its
# caddy binary:
#
#   CID=$(docker create zopdev/shell-agent:v0.0.1)
#   docker cp "$CID:/usr/local/bin/zop-shell-agent" /tmp/agent && docker rm "$CID"
#
# The script then runs as a HOST systemd service. That is the whole point: a
# host process needs no --pid=host, no CAP_SYS_ADMIN, no CAP_SYS_PTRACE, no
# apparmor=unconfined, no docker.sock mount and no nsenter. It is already
# where the shell has to run.
#
# WHY A SCRIPT AND NOT A BINARY:
# tmux owns the pseudo-terminal, survives a dropped connection, and
# `pipe-pane -O` yields the raw byte stream the browser's terminal emulator
# wants. curl does the long poll and jq parses the protocol. What is left is
# small enough to read in one sitting, and this repository is PUBLIC — the
# agent's own source may live here, a service's may not.


# -------------------------------
# Base
# -------------------------------
# alpine because the image is only ever a container to `docker cp` out of;
# nothing in it executes. Pinned so a rebuild is reproducible.
FROM alpine:3.22

# The tools the agent calls. Installed here so the BUILD fails if a package
# disappears upstream, rather than the agent failing its tool check on a VM
# weeks later. They are also what the component verifies on the host before
# it starts the service — the VM needs its own copies, since the script runs
# there, not in here.
RUN apk add --no-cache bash curl jq tmux

COPY shell-agent/zop-shell-agent.sh /usr/local/bin/zop-shell-agent
RUN chmod 0755 /usr/local/bin/zop-shell-agent


# -------------------------------
# Build-time assertions (CRITICAL)
# -------------------------------
# Fail the BUILD rather than a VM install six steps later, the same contract
# the scale-to-zero image holds itself to. Three invariants the component
# depends on:
#
#   1. the script is at the exact path the copy-out step reads,
#   2. it is syntactically valid bash — a typo here becomes an agent that
#      exits instantly on every VM it is installed on, and
#   3. it refuses to start without its three required variables, which is what
#      stops a half-configured install from looking healthy.
RUN test -x /usr/local/bin/zop-shell-agent \
      || { echo "agent missing from the published path" >&2; exit 1; } \
 && bash -n /usr/local/bin/zop-shell-agent \
      || { echo "agent is not valid bash" >&2; exit 1; } \
 && ! ZOP_SHELL_RELAY_URL= ZOP_SHELL_AGENT_TOKEN= ZOP_SHELL_SPACE_ID= \
      bash /usr/local/bin/zop-shell-agent 2>/dev/null \
      || { echo "agent started with no configuration" >&2; exit 1; }

# Never executed — see the header. Present so a person who does run the
# container gets an explanation instead of silence.
ENTRYPOINT ["/bin/sh", "-c", "echo 'carrier image: docker cp /usr/local/bin/zop-shell-agent out; see the ZopDay shell-access VM component' >&2; exit 64"]
