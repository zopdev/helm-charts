# chisel Docker Image

The chisel Docker image packages the [chisel](https://github.com/jpillora/chisel) tunnel server, built from a pinned release with our own Go toolchain. The [chisel chart](../../charts/chisel) runs it.

We build it ourselves so that a Go security fix needs only a rebuild here. We do not wait for an upstream release.

> **amd64 only.** The `Image Deployment` workflow builds for the runner's architecture only. On arm64 clusters, use `jpillora/chisel`, which is multi-arch, with a chisel version tag (`1.11.7` or later).

---

## Components & Versions

| Component                        | Version  | Description                                        |
|----------------------------------|----------|----------------------------------------------------|
| chisel                           | 1.12.1   | Tunnel server. Must be 1.11.7 or later for ACLs    |
| Go                               | 1.27.3   | Build toolchain                                    |
| distroless `static-debian13`     | nonroot  | Runtime base: CA certificates, no shell            |

---

## Prerequisites

- Docker 20.10+

---

## Build Image

To build the Docker image, run the following command from the repository root:

```bash
docker build -f images/chisel/Dockerfile -t chisel:latest images/
```

Override the pinned versions at build time if needed:

```bash
docker build -f images/chisel/Dockerfile \
  --build-arg CHISEL_VERSION=1.12.1 \
  --build-arg GO_VERSION=1.27.3 \
  -t chisel:latest images/
```

The build fails if the binary does not report `CHISEL_VERSION`.

---

## Verify

```bash
docker run --rm chisel:latest --version
# 1.12.1
```

---

## Usage

The entrypoint is the chisel binary, as in `jpillora/chisel`:

```bash
docker run --rm -p 8080:8080 zopdev/chisel:v0.0.1 server --port 8080 --reverse
```

Make a server key:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/out" \
  zopdev/chisel:v0.0.1 server --keygen /out/server.key
```

---

## File Structure

```
images/chisel/
├── Dockerfile   # two-stage: go install + version check, then distroless runtime
└── README.md
```

---

## Publish

The image is published via the `Image Deployment` GitHub Actions workflow. Push a tag in the form `chisel-image-v<N>` to trigger the build:

```bash
git tag chisel-image-v0.0.1
git push origin chisel-image-v0.0.1
```

This produces:

- `zopdev/chisel:v0.0.1`
- `zopdev/chisel:latest`

The image tag is its own version, not the chisel version, so a rebuild with a newer Go gets a new tag. Record each tag here:

| Image tag | chisel | Go     |
|-----------|--------|--------|
| `v0.0.1`  | 1.12.1 | 1.27.3 |

Consumers pin the full tag, never `latest`. When you publish a new tag, also update `image.tag` in the chart, and `appVersion` if chisel changed.

---

## Contributing

We welcome contributions to improve this Docker image. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This Dockerfile is under the repository [LICENSE](../../LICENSE). chisel itself is MIT licensed.
