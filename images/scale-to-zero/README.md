# scale-to-zero Docker Image

The scale-to-zero Docker image packages the [Caddy](https://caddyserver.com) web server with the [Sablier](https://sablierapp.dev) scale-to-zero plugin compiled in.

> **What this image is — and is not.** It is named for the capability it enables, but it contains *only the Caddy half*: the request-interception plugin. The scale-to-zero orchestrator itself is upstream's own `sablierapp/sablier` image, pulled separately at runtime and not rebuilt here. So this image alone does not provide scale-to-zero — it provides the Caddy binary that can talk to the thing that does. Sablier's wake-on-request plugin is a Caddy **module**: it must be built into the binary with `xcaddy` and cannot be loaded into a stock Caddy at runtime, and upstream ships no prebuilt "Caddy + Sablier" binary — hence this image.

The image is a **carrier, not a runtime**. ZopDay VM pools run Caddy as a host systemd service (binding `:80`/`:443` and reading `/etc/caddy`), so nothing runs this container in production: the VM's `scale-to-zero` component pulls it and copies the binary out. Docker Hub is used rather than a release asset because Docker is already a baseline component on every pool VM and those VMs already pull public images — no new registry auth or network path.

---

## Components & Versions

| Component              | Version   | Description                                                            |
|------------------------|-----------|------------------------------------------------------------------------|
| Caddy                  | 2.11.3    | Base web server / reverse proxy. Must match the deployer's baseline    |
| sablier-caddy-plugin   | v1.0.2    | Wake-on-request middleware, compiled in via xcaddy                     |
| xcaddy                 | bundled   | Supplied by the official `caddy:<version>-builder` image               |

> **Version lockstep (critical).** `CADDY_VERSION` must match the version the ZopDay deployer's baseline `caddy` component installs (`backend/deployer/configs/vm-components.yaml`). Both variants report the *same* version string and differ only by the extra dormant module — that is precisely what lets the component's skip-download gate treat them as interchangeable. Bumping one without the other makes every prep re-download the binary forever.

---

## Prerequisites

- Docker 20.10+

---

## Build Image

To build the Docker image, run the following command from the repository root:

```bash
docker build -f images/scale-to-zero/Dockerfile -t scale-to-zero:latest images/
```

Override the pinned versions at build time if needed:

```bash
docker build -f images/scale-to-zero/Dockerfile \
  --build-arg CADDY_VERSION=2.11.3 \
  --build-arg SABLIER_PLUGIN_VERSION=v1.0.2 \
  -t scale-to-zero:latest images/
```

The build fails fast if either invariant the deployer relies on is broken — the exact version string, or the presence of the `http.handlers.sablier` module.

---

## Verify

```bash
docker run --rm scale-to-zero:latest caddy version
# v2.11.3 h1:...

docker run --rm scale-to-zero:latest caddy list-modules | grep sablier
# http.handlers.sablier
```

The plugin is **inert** unless a `sablier` directive appears in the Caddyfile, so this binary is a drop-in replacement for stock Caddy of the same version.

---

## Usage

The consumer is the ZopDay deployer's `scale-to-zero` VM component, which copies the binary onto the VM rather than running the container:

```bash
docker pull zopdev/scale-to-zero:v2.11.3
CID=$(docker create zopdev/scale-to-zero:v2.11.3)
docker cp "$CID:/usr/bin/caddy" /tmp/caddy
docker rm "$CID"
# validated against the live Caddyfile, then installed to /usr/local/bin/caddy
```

The component validates the downloaded binary with `caddy validate --config /etc/caddy/Caddyfile` **before** replacing the live one (Caddy is the VM's only ingress) and keeps the previous binary at `/usr/local/bin/caddy.prev` for rollback.

---

## File Structure

```
images/scale-to-zero/
├── Dockerfile   # two-stage: xcaddy build + assertions, then the final carrier image
└── README.md
```

---

## Features

- Caddy with the Sablier wake-on-request module compiled in
- Version-pinned Caddy and plugin for reproducible builds
- Build-time assertions on both invariants the deployer depends on
- Plugin inert without a `sablier` directive — safe drop-in for stock Caddy
- Binary at the conventional `/usr/bin/caddy` path

---

## Publish

The image is published via the `Image Deployment` GitHub Actions workflow. Push a tag in the form `scale-to-zero-image-v<N>` to trigger the build:

```bash
git tag scale-to-zero-image-v2.11.3
git push origin scale-to-zero-image-v2.11.3
```

This produces:

- `zopdev/scale-to-zero:v2.11.3`
- `zopdev/scale-to-zero:latest`

> **The tag is the Caddy version, not a version of this image.** `v2.11.3` means "Caddy 2.11.3" — it is not an incrementing counter like `db-init`'s. This is forced by the lockstep rule above: the deployer's component derives the tag it pulls from its own `CADDY_VERSION`, so the two must agree exactly. Bump this tag when Caddy is bumped, and re-tag with the same scheme if only the plugin changes (e.g. append a suffix) so the Caddy version stays readable.

Consumers should pin the versioned tag, never `latest`.

---

## Contributing

We welcome contributions to improve this Docker image. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.

---
