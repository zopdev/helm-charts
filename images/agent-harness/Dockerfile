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
# THIS IS THE ONLY DOCKERFILE FOR THIS IMAGE. zopnight used to carry a near-
# copy beside those three programs; nothing built it, it had already drifted
# (it still claimed the harness opens the pull request with curl), and it was
# removed rather than left to drift further. THE PROGRAMS ARE COPIED, THE
# BUILD IS NOT. zopnight's agentharness test
# TestHarnessProgramsMatchThePublishedImage pins the three digests on that
# side, so an edit there cannot be made without someone being told to re-copy
# here and cut a new tag.
#
# WHAT THE THREE PROGRAMS SHELL OUT TO, and therefore what has to be
# installed: sh, git, sed, tail and cp from coreutils, update-ca-certificates
# to trust the sandbox's egress filter, and python3 - zopday-agent-record is
# a python3 program, and zopday-agent-cli pipes the agent's event stream
# through it.
#
# NOT curl and NOT `gh`. zopday-harness stops at the push; the host opens the
# draft pull request from OUTSIDE the sandbox, and api.github.com is not in
# this sandbox's egress policy at all (the note at the end of zopday-harness
# says why). curl is installed anyway, but for the AGENT - it is a tool a
# coding agent reaches for, and it is one of the clients the trust block
# inside the harness exists to serve.
#
#   docker build -f images/agent-harness/Dockerfile -t agent-harness:latest images/
#
# LINUX/AMD64 ONLY. The Image Deployment workflow builds this on an amd64
# runner with no QEMU and no platforms:, so the published manifest carries one
# architecture. zopnight's agent-harness VM component refuses to install on a
# non-x86_64 host for that reason - a single-platform image pulls and inspects
# happily on arm64, so without that refusal the first `docker run` of a real
# task would be what discovers it.
#
# NO SECRETS ARE BAKED IN. The model key and the git token reach the agent as
# environment on one exec, from the runner host, and the runner host gives it
# placeholders that the sandbox's egress filter substitutes outside the
# sandbox. There is nothing credential-shaped in this image.
FROM node:22-bookworm-slim

# node:22-bookworm-slim ships ENTRYPOINT docker-entrypoint.sh / CMD node, which
# this image has no use for and which the comment at the bottom claims it does
# not carry. Cleared so that claim is true of the IMAGE and not only of our
# intent. Setting ENTRYPOINT resets the inherited CMD too, so both read null.
#
# `docker run <image>` with no command therefore fails with "no command
# specified" instead of dropping into a node REPL. That is the correct shape
# here and nothing regresses on it: the sandbox is created with its own
# entrypoint, the task arrives as an exec, and the agent-harness VM component
# only ever runs `docker pull` and `docker image inspect`.
ENTRYPOINT []

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

# IS_SANDBOX IS DELIBERATELY NOT SET HERE. It is what lets Claude Code accept
# --dangerously-skip-permissions when the turn runs as root, and it used to be
# an ENV on this line.
#
# This image is published PUBLICLY, and an ENV travels with it: anyone who
# pulled it and ran it as root, outside any sandbox, would get that flag
# accepted. The claim "this really is a sandbox" is true of an INVOCATION, not
# of a layer, so the invocation is what makes it - zopnight's
# agentTaskRunScript exports it in the same one-command list as the
# placeholder credentials, and TestAgentTaskRunScript_ExportsIsSandboxFromThe-
# Host pins it there.
#
# Nothing regresses. sbx's docker provider passes no --user, so the container
# keeps the USER below, execd runs as that user, and an exec naming no uid
# runs as it too - a non-root agent never needed the flag. It is the belt for
# an execd that ever runs the turn as root, and the host is where that belt
# belongs. (sbx's firecracker provider refuses a non-root USER outright, so it
# never reaches this image at all.)

# NON-ROOT, which is what it runs as unless something overrides it. `node` is
# the base image's own uid 1000, reused rather than a second user invented
# beside it.
USER node
ENV HOME=/home/node
WORKDIR /workspace

# No ENTRYPOINT and no CMD on purpose - the base image's are cleared near the
# top. The sandbox is created with entrypoint ["sleep","infinity"] and
# everything that matters arrives as an exec, so an entrypoint here would only
# be a second answer to a question the create already answers.
