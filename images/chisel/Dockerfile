# -------------------------------
# Chisel tunnel server
# -------------------------------
# WHY THIS IMAGE EXISTS:
# Built for the chisel chart (charts/chisel). We build chisel from its
# pinned release with our own Go toolchain, so a Go security fix needs only
# a rebuild here. We do not wait for an upstream release.
#
# https://github.com/jpillora/chisel


# -------------------------------
# Version pinning
# -------------------------------
# CHISEL_VERSION must be 1.11.7 or later: older servers do not enforce
# per-user ACLs. The image tag is a separate version (see README.md), so
# record each new pair in the README table.
#
# GO_VERSION must satisfy the `go` line in chisel's go.mod.
ARG CHISEL_VERSION=1.12.1
ARG GO_VERSION=1.27.3


# -------------------------------
# Build stage
# -------------------------------
FROM golang:${GO_VERSION}-alpine AS builder

ARG CHISEL_VERSION

# `go install module@version` gets the source through the Go module proxy
# and checks it against the checksum database. GOTOOLCHAIN=local keeps the
# build on this image's Go and stops a silent toolchain download.
# BuildVersion is what `chisel --version` prints; a plain source build
# prints 0.0.0-src.
RUN CGO_ENABLED=0 GOTOOLCHAIN=local GOBIN=/out go install -trimpath \
      -ldflags "-s -w -X github.com/jpillora/chisel/share.BuildVersion=${CHISEL_VERSION}" \
      "github.com/jpillora/chisel@v${CHISEL_VERSION}"

# Fail the build if the binary reports a different version.
RUN test "$(/out/chisel --version)" = "${CHISEL_VERSION}" \
      || { echo "version mismatch: $(/out/chisel --version)" >&2; exit 1; }


# -------------------------------
# Final image
# -------------------------------
# distroless static: CA certificates and a nonroot user (65532), with no
# shell and no package manager. The chart sets its own uid at pod level.
FROM gcr.io/distroless/static-debian13:nonroot

COPY --from=builder /out/chisel /usr/local/bin/chisel

# Same as jpillora/chisel: arguments go straight to chisel
# (e.g. `server --port 8080`).
ENTRYPOINT ["/usr/local/bin/chisel"]
