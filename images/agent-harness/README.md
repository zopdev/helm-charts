# agent-harness Docker Image

The agent-harness image is the container a ZopDay agent task runs inside: the [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI, plus the three programs that make it satisfy the runner host's harness contract.

> **What this image is — and is not.** It is the *harness*, not the agent. The harness runs the agent, then checks whether the agent committed anything and **pushes the branch**. **The agent writes the commits**, and the harness refuses to push a tree the agent left dirty — uncommitted work is not work the agent has said it means.
>
> That separation is deliberate, and it is narrower than "the agent cannot decline". An agent that commits nothing completes as *changed nothing*, and one that leaves a dirty tree fails; both are outcomes it can choose. What it cannot choose is **where** the work goes — it cannot widen the one ref this attempt may write, push a second ref, or claim a push it did not earn.
>
> **The pull request is not opened in here.** It used to be, and an agent told to open one opened its own instead — not a draft, worded by the agent, in a customer's repository. So the runner host opens the draft from *outside* the sandbox, after this image's push, and `api.github.com` is no longer in the sandbox's egress policy or its credential vault at all. `zopday-harness` says so at its own end; this image carries nothing that could call that API.

The image exists for the reason `scale-to-zero` does — upstream ships nothing that fits. There is no prebuilt "Claude Code plus our contract" image, and the contract is ours, so it is built here and published to Docker Hub. Docker is a baseline component on every ZopDay pool VM and those VMs already pull `zopdev/*` images, so this needs no new registry auth and no new network path.

---

## Components & Versions

| Component             | Version        | Description                                                          |
|-----------------------|----------------|----------------------------------------------------------------------|
| Claude Code CLI       | 2.1.292        | The agent. Pinned, never `latest` — see below                        |
| node                  | 22-bookworm-slim | Base image; supplies the npm the CLI installs through              |
| zopday-harness        | from zopnight  | The contract itself: one agent turn, then the branch push            |
| zopday-agent-cli      | from zopnight  | `$ZOPDAY_AGENT_CLI` — Claude Code shaped to that contract            |
| zopday-agent-record   | from zopnight  | The transcript / session-id half of that wrapper                     |

> **Pinned, not `latest` (critical).** A placement profile pins this image **by digest**, precisely so the toolchain a task starts with is the toolchain it finishes with. A floating npm tag inside a pinned digest would make that pin a half-truth, so `CLAUDE_CODE_VERSION` is an explicit build arg and the CLI's auto-updater is switched off in the image.

> **The three programs are copies — the build is not.** Their source of truth is zopnight's `backend/deployer/internal/installer/testdata/agent-harness/`. They are copied here unedited so the harness in the image is byte-for-byte the contract the runner host expects. Change them there, then re-copy and cut a new tag.
>
> **The Dockerfile lives only here.** zopnight used to carry a near-copy of it beside those three programs; nothing built it and it had already drifted, so it was removed rather than left to drift further. zopnight's `agentharness` test `TestHarnessProgramsMatchThePublishedImage` pins the three digests on that side, so an edit there fails that suite with instructions to re-copy here and cut a new tag — which is what keeps "byte-for-byte" true between two repositories that are otherwise kept in step by hand.

---

## Prerequisites

- Docker 20.10+

---

## Platform

**`linux/amd64` only.** The `Image Deployment` workflow runs `build-push-action` on an `ubuntu-latest` runner with no QEMU and no `platforms:`, so what reaches Docker Hub is a single amd64 manifest — the same as `zopdev/scale-to-zero` and `zopdev/db-init`, which are published by that same workflow.

This matters because it is narrower than the components around it. zopnight's `sbx` and `gvisor` components both install on `aarch64`, so an arm64 runner host can pass every other install step. The `agent-harness` component refuses on a non-amd64 host rather than letting the first task be the thing that discovers it.

Making this multi-arch means adding QEMU and `platforms:` to the shared workflow, which changes the build for every image in this repository — a deliberate decision, not a side effect of this one.

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

The three programs shell out to `sh`, `git`, `python3`, `sed`, `tail`, `cp` and `update-ca-certificates`; all are present.

Neither `curl` nor `gh` is called by any of them — the harness stops at the push, so there is no pull-request call to make. `gh` is deliberately **absent**. `curl` *is* installed, but for the agent: it is a tool a coding agent reaches for, and it is one of the clients the harness's CA-trust step exists to serve.

---

## Security

**No secrets are baked in.** The model key and the git token reach the agent as environment on one `exec`, from the runner host, and the host passes *placeholders* that the sandbox's egress filter substitutes outside the sandbox. Nothing credential-shaped is in any layer.

**It runs as a non-root user.** `node` (uid 1000) is the base image's own user, reused rather than a second one invented beside it. `/workspace` and `/zopday` are created and chowned at build time because a non-root user cannot create them at the filesystem root, and the runner clones into the first and writes the second.

**Running non-root means the sandbox CA lands in environment variables, not the system trust store.** `zopday-harness` does two things with the credential vault's authority: it tries to add it to the image's own trust store, and it writes a merged bundle (the image's roots *plus* that authority) and points `GIT_SSL_CAINFO`, `SSL_CERT_FILE` and `REQUESTS_CA_BUNDLE` at it. As `node`, only the second half succeeds — the harness says so on its own line (`image store: no, merged bundle: …`). That still covers the agent's normal toolchain: git, curl and python read those three, and node reads `NODE_EXTRA_CA_CERTS`, which sbx sets itself. A tool that honours none of them fails TLS against the egress filter. That is the cost of not running as root, and it is the right trade.

> **Which user the turn actually runs as.** The `node` half of that paragraph depends on sbx, not on this image, so it is worth saying where it comes from. ZopDay runs sbx with `--provider.name=docker`. That provider builds its `docker run` argument list with no `--user`, so the container keeps this image's `USER node`; `execd` is the container's PID 1 and therefore runs as `node`; and an exec that names no uid gets a nil credential and runs as whoever execd already is. So the real path is `node`, and the trust-store half genuinely does fail. sbx's *firecracker* provider never reaches this image: it refuses a non-root `USER` outright, because every process in that VM runs as root and it will not silently drop the boundary the image asked for.

**`IS_SANDBOX` is *not* set in this image — the runner host exports it per task.** It is what lets Claude Code accept `--dangerously-skip-permissions`, and it used to be an `ENV` here. An `ENV` travels with a **public** image, so anyone pulling this one and running it as root outside any sandbox would have that flag accepted. The claim "this really is a sandbox" is true of an *invocation*, not of a layer, so the invocation makes it: zopnight's `agentTaskRunScript` exports it in the same one-command list as the placeholder credentials, where an [sbx](https://github.com/aryanmehrotra/sbx) sandbox with deny-by-default egress, a per-task credential and a throwaway clone is the thing it is describing.

Nothing regresses by moving it: as shown above the turn runs as `node`, and a non-root agent never needed the flag. It is the belt for an execd that ever runs the turn as root.

---

## File Structure

```
images/agent-harness/
├── Dockerfile             # the image: CLI + the three contract programs
├── README.md
├── zopday-harness         # the contract: one agent turn, then the branch push
├── zopday-agent-cli       # $ZOPDAY_AGENT_CLI — Claude Code shaped to it
└── zopday-agent-record    # transcript and session id
```

---

## Features

- Claude Code CLI pinned to an exact version, auto-updater off
- The harness contract copied byte-for-byte from zopnight
- No credentials in any layer — they arrive per task, as placeholders
- Non-root by default, with the two workspace paths pre-owned
- No `IS_SANDBOX` baked in — the permission-skip claim is the invocation's to make, not a public image's
- No `ENTRYPOINT` and no `CMD` — the base image's are cleared: the sandbox is created with `sleep infinity` and everything that matters arrives as an `exec`
- `linux/amd64` only — see Platform above

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

---

## Contributing

We welcome contributions to improve this Docker image. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

**The build files in this directory are covered by the repository [LICENSE](../../LICENSE). The image published from them is not wholly covered by it, and is not open source.**

The image installs [`@anthropic-ai/claude-code`](https://www.npmjs.com/package/@anthropic-ai/claude-code), whose own `LICENSE.md` reads "© Anthropic PBC. All rights reserved. Use is subject to the Legal Agreements outlined here: https://code.claude.com/docs/en/legal-and-compliance". `npm view @anthropic-ai/claude-code license` reports `SEE LICENSE IN README.md` rather than an SPDX identifier. Anyone pulling `zopdev/agent-harness` receives that CLI and uses it under Anthropic's terms, not under this repository's.

This is the same shape as `scale-to-zero`, whose published image is AGPL-3.0 rather than the repository's licence — the difference is that AGPL-3.0 grants redistribution and these terms are not an open-source grant.

> **Open before the first tag is pushed.** Whether those terms permit redistributing the CLI inside a **public** image on Docker Hub has not been confirmed with Anthropic. Until it is, treat the publication decision as unmade. The alternative, if redistribution is not permitted, is a private Docker Hub repository — which costs pull credentials on every runner VM, the thing a public image was chosen to avoid.
