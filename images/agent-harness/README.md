# agent-harness Docker Image

The agent-harness image is the container a ZopDay agent task runs inside: the [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI, plus the three programs that make it satisfy the runner host's harness contract.

> **What this image is — and is not.** It is the *harness*, not the agent. The harness runs the agent and is then the thing that pushes the branch and opens the pull request. That separation is deliberate: the agent is assumed hostile, so "it opened a pull request" must not be something it can decline, duplicate or redirect, and a crash must not be able to produce two pull requests.

The image exists for the reason `scale-to-zero` does — upstream ships nothing that fits. There is no prebuilt "Claude Code plus our contract" image, and the contract is ours, so it is built here and published to Docker Hub. Docker is a baseline component on every ZopDay pool VM and those VMs already pull `zopdev/*` images, so this needs no new registry auth and no new network path.

---

## Components & Versions

| Component             | Version        | Description                                                          |
|-----------------------|----------------|----------------------------------------------------------------------|
| Claude Code CLI       | 2.1.292        | The agent. Pinned, never `latest` — see below                        |
| node                  | 22-bookworm-slim | Base image; supplies the npm the CLI installs through              |
| zopday-harness        | from zopnight  | The contract itself: one agent turn, then the pull request           |
| zopday-agent-cli      | from zopnight  | `$ZOPDAY_AGENT_CLI` — Claude Code shaped to that contract            |
| zopday-agent-record   | from zopnight  | The transcript / session-id half of that wrapper                     |

> **Pinned, not `latest` (critical).** A placement profile pins this image **by digest**, precisely so the toolchain a task starts with is the toolchain it finishes with. A floating npm tag inside a pinned digest would make that pin a half-truth, so `CLAUDE_CODE_VERSION` is an explicit build arg and the CLI's auto-updater is switched off in the image.

> **The three programs are copies.** Their source of truth is zopnight's `backend/deployer/internal/installer/testdata/agent-harness/`. They are copied here unedited so the harness in the image is byte-for-byte the contract the runner host expects. Change them there, then re-copy and cut a new tag.

---

## Prerequisites

- Docker 20.10+

---

## Build Image

From the repository root:

```bash
docker build -f images/agent-harness/Dockerfile -t agent-harness:latest images/
```

Override the pinned CLI version at build time if needed:

```bash
docker build -f images/agent-harness/Dockerfile \
  --build-arg CLAUDE_CODE_VERSION=2.1.292 \
  -t agent-harness:latest images/
```

The build fails fast if the CLI does not install — `claude --version` runs as the last step of that layer.

---

## Verify

```bash
docker run --rm agent-harness:latest claude --version
# 2.1.292 (Claude Code)

docker run --rm agent-harness:latest sh -c 'ls /usr/local/bin/zopday-harness /usr/local/bin/zopday-agent-cli'
# both present and executable

docker run --rm agent-harness:latest sh -c 'id -un; echo $ZOPDAY_AGENT_CLI'
# node
# /usr/local/bin/zopday-agent-cli
```

The harness shells out to `sh`, `git`, `curl`, `python3`, `sed`, `tail` and `cp`; all seven are present. `gh` is deliberately **absent** — the two pull-request calls are plain `curl` against the REST API.

---

## Security

**No secrets are baked in.** The model key and the git token reach the agent as environment on one `exec`, from the runner host, and the host passes *placeholders* that the sandbox's egress filter substitutes outside the sandbox. Nothing credential-shaped is in any layer.

**It runs as a non-root user.** `node` (uid 1000) is the base image's own user, reused rather than a second one invented beside it. `/workspace` and `/zopday` are created and chowned at build time because a non-root user cannot create them at the filesystem root, and the runner clones into the first and writes the second.

**`IS_SANDBOX=1` is set**, which is what lets Claude Code accept `--dangerously-skip-permissions`. It is a true statement about this image rather than a way round a safety check: the only thing that ever runs it is an [sbx](https://github.com/aryanmehrotra/sbx) sandbox, with deny-by-default egress, a per-task credential and a throwaway clone.

---

## File Structure

```
images/agent-harness/
├── Dockerfile             # the image: CLI + the three contract programs
├── README.md
├── zopday-harness         # the contract: one agent turn, then the pull request
├── zopday-agent-cli       # $ZOPDAY_AGENT_CLI — Claude Code shaped to it
└── zopday-agent-record    # transcript and session id
```

---

## Features

- Claude Code CLI pinned to an exact version, auto-updater off
- The harness contract copied byte-for-byte from zopnight
- No credentials in any layer — they arrive per task, as placeholders
- Non-root by default, with the two workspace paths pre-owned
- No `ENTRYPOINT` and no `CMD`: the sandbox is created with `sleep infinity` and everything that matters arrives as an `exec`

---

## Usage

The consumer is the ZopDay deployer's `agent-harness` VM component, which pulls the image so it is already on the host when a task starts:

```bash
docker pull zopdev/agent-harness:v0.0.1
```

The deployer pins it **by digest** in `backend/deployer/configs/vm-components.yaml` (`HARNESS_IMAGE`), and a placement profile may override it per target.

---

## Publish

The image is published via the `Image Deployment` GitHub Actions workflow. Push a tag in the form `agent-harness-image-v<N>` to trigger the build:

```bash
git tag agent-harness-image-v0.0.1
git push origin agent-harness-image-v0.0.1
```

This produces:

- `zopdev/agent-harness:v0.0.1`
- `zopdev/agent-harness:latest`

Take the digest the push prints and paste it into `HARNESS_IMAGE` in zopnight's `vm-components.yaml`, so the component installs exactly the build that was tagged.
