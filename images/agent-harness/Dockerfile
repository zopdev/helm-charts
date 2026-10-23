# The real agent harness image: the Claude Code CLI, and the three programs
# that make it satisfy zopday-harness's contract.
#
# Built from the files beside this Dockerfile, so the harness in the image is
# BYTE-FOR-BYTE the contract the runner host expects rather than a fork of it.
# Their source of truth is zopnight's
# backend/deployer/internal/installer/testdata/agent-harness/, and the three
# are copied here unedited:
#
#   zopday-harness       the contract itself (copied, never edited)
#   zopday-agent-cli     $ZOPDAY_AGENT_CLI — Claude Code shaped to the contract
#   zopday-agent-record  the transcript/session-id half of that wrapper
#
# WHAT THE HARNESS SHELLS OUT TO, and therefore what has to be installed:
# sh, git, curl, python3 (it opens the pull request with curl and parses the
# answer with python3), sed, tail and cp from coreutils, and
# update-ca-certificates to trust the sandbox's egress filter. It does NOT use
# `gh` - the two pull-request calls are plain curl against the REST API - so gh
# is deliberately absent.
#
#   docker build -f images/agent-harness/Dockerfile -t agent-harness:latest images/
#
# NO SECRETS ARE BAKED IN. The model key and the git token reach the agent as
# environment on one exec, from the runner host, and the runner host gives it
# placeholders that the sandbox's egress filter substitutes outside the
# sandbox. There is nothing credential-shaped in this image.
FROM node:22-bookworm-slim

# PINNED, not `latest`: a profile pins the image by digest precisely so that the
# toolchain a task starts with is the toolchain it finishes with, and a floating
# npm tag inside a pinned digest would make that pin a half-truth. This is the
# npm `stable` tag as of the build.
ARG CLAUDE_CODE_VERSION=2.1.292

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		git \
		python3 \
	&& rm -rf /var/lib/apt/lists/*

RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
	&& npm cache clean --force \
	&& claude --version

# Paths are relative to the BUILD CONTEXT, which the Image Deployment workflow
# sets to images/ for every image in this repository — not to this directory.
COPY agent-harness/zopday-harness /usr/local/bin/zopday-harness
COPY agent-harness/zopday-agent-cli /usr/local/bin/zopday-agent-cli
COPY agent-harness/zopday-agent-record /usr/local/libexec/zopday-agent-record

# /workspace and /zopday, pre-made and OWNED BY THE AGENT USER.
#
# Both are fixed paths at the filesystem root, chosen by the runner host
# (WORKSPACE=/workspace, AGENT_DIR=/zopday in agentTaskRunScript): the host
# clones into the first and mkdir -p's the second. A non-root user cannot
# create either, so the image creates them instead of the image having to run
# as root for the clone to land.
RUN chmod 0755 /usr/local/bin/zopday-harness \
		/usr/local/bin/zopday-agent-cli \
		/usr/local/libexec/zopday-agent-record \
	&& mkdir -p /workspace /zopday \
	&& chown node:node /workspace /zopday

# The one variable the IMAGE owes the harness: zopday-harness refuses to start
# without it, and it is the image - not the host - that knows which agent it
# ships.
ENV ZOPDAY_AGENT_CLI=/usr/local/bin/zopday-agent-cli

# Claude Code's auto-updater would reach npm, which this sandbox's egress policy
# denies (it allows the model host and the git hosts, nothing else), and if it
# ever did succeed it would run a version this image was not pinned to. Off, so
# the digest means what it says.
ENV DISABLE_AUTOUPDATER=1 \
	CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Claude Code refuses --dangerously-skip-permissions when it is running as
# root, and nothing in this image chooses the user the runner's exec arrives
# as: USER below is the image's default, and an execd that ran the turn as root
# would make every attempt fail with "cannot be used with root/sudo
# privileges" before the agent did anything. Measured, not guessed - as root
# without this the wrapper exits 1 on that message, and with it the turn
# proceeds.
#
# IT IS A TRUE STATEMENT ABOUT THIS IMAGE and not a way round a safety check:
# the only thing that ever runs it is an sbx sandbox, with deny-by-default
# egress, a per-task credential and a throwaway clone.
ENV IS_SANDBOX=1

# NON-ROOT, which is what it runs as unless something overrides it. `node` is
# the base image's own uid 1000, reused rather than a second user invented
# beside it.
USER node
ENV HOME=/home/node
WORKDIR /workspace

# No ENTRYPOINT and no CMD on purpose. The sandbox is created with
# entrypoint ["sleep","infinity"] and everything that matters arrives as an
# exec, so an entrypoint here would only be a second answer to a question the
# create already answers.
