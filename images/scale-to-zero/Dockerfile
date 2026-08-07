# -------------------------------
# Caddy + Sablier scale-to-zero plugin
# -------------------------------
# WHY THIS IMAGE EXISTS:
# The Sablier wake-on-request plugin is a Caddy MODULE. Caddy modules are
# compiled INTO the binary with xcaddy — they cannot be dropped into a
# stock Caddy at runtime — and upstream publishes no prebuilt
# "Caddy + Sablier" binary. So we build our own.
#
# WHY THIS LINK:
# https://github.com/sablierapp/sablier-caddy-plugin
# https://github.com/caddyserver/xcaddy
#
# THIS IMAGE IS A CARRIER, NOT A RUNTIME:
# ZopDay VM pools run Caddy as a host systemd service (it binds :80/:443
# and reads /etc/caddy), so nothing runs this container. The VM's
# scale-to-zero component pulls the image and copies the binary out:
#
#   CID=$(docker create zopdev/scale-to-zero:v0.0.1)
#   docker cp "$CID:/usr/bin/caddy" /tmp/caddy && docker rm "$CID"
#
# Docker Hub is used rather than a release asset because Docker is already
# a baseline component on every pool VM and those VMs already pull public
# images — no new registry auth or network path.


# -------------------------------
# Version pinning (CRITICAL)
# -------------------------------
# CADDY_VERSION MUST stay in lockstep with the version the ZopDay deployer's
# baseline `caddy` component installs (backend/deployer/configs/
# vm-components.yaml). Both variants report the SAME version string and
# differ only by the extra dormant module, which is exactly what lets the
# component's skip-download gate treat them as interchangeable. Bumping
# this without bumping the deployer (or vice versa) makes every prep
# re-download the binary forever.
#
# SABLIER_PLUGIN_VERSION is pinned so a rebuild is reproducible; the plugin
# is inert until a `sablier` directive appears in the Caddyfile, so this
# binary is a safe drop-in replacement for stock Caddy.
ARG CADDY_VERSION=2.11.3
ARG SABLIER_PLUGIN_VERSION=v1.0.2


# -------------------------------
# Build stage
# -------------------------------
# The official caddy:<version>-builder image ships xcaddy and the Go
# toolchain, so the build needs no extra dependencies.
FROM caddy:${CADDY_VERSION}-builder AS builder

ARG CADDY_VERSION
ARG SABLIER_PLUGIN_VERSION

# The Caddy version is passed EXPLICITLY rather than inherited. The builder
# image sets `ENV CADDY_VERSION=v2.11.3` (with a "v") and a bare `xcaddy build`
# would silently use it — while the assertion below needs the un-prefixed ARG
# for its `^v${CADDY_VERSION}` grep. Relying on that difference would make the
# build depend on where the ARG line sits relative to this one, so both values
# are derived from one source here instead.
RUN xcaddy build "v${CADDY_VERSION}" \
    --with github.com/sablierapp/sablier-caddy-plugin@${SABLIER_PLUGIN_VERSION}


# -------------------------------
# Build-time assertions (CRITICAL)
# -------------------------------
# Fail the BUILD rather than a VM install six steps later. Two invariants
# the deployer depends on:
#
#   1. the exact version string its skip-download gate matches
#      (`caddy version | grep "^v<version> "`), and
#   2. the module id its precondition check greps for
#      (`caddy list-modules | grep '^http.handlers.sablier'`).
#
# Both were verified against a real build before this image was written; a
# plugin or Caddy bump that breaks either one stops here.
RUN /usr/bin/caddy version | grep -q "^v${CADDY_VERSION} " \
      || { echo "version mismatch: $(/usr/bin/caddy version)" >&2; exit 1; } \
 && /usr/bin/caddy list-modules | grep -q '^http.handlers.sablier' \
      || { echo "sablier module missing from build" >&2; /usr/bin/caddy list-modules >&2; exit 1; }


# -------------------------------
# Final image
# -------------------------------
# Based on the official caddy:<version> image so the binary sits at the
# conventional /usr/bin/caddy path the copy-out step above expects, and so
# the image is still a usable Caddy if anyone does run it directly.
FROM caddy:${CADDY_VERSION}

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# -------------------------------
# Ship-stage assertion
# -------------------------------
# The checks above run in the builder; this one runs on the image that is
# actually published, so a wrong COPY path or a base-tag/builder-tag mismatch
# cannot slip through.
ARG CADDY_VERSION
RUN caddy version | grep -q "^v${CADDY_VERSION} " \
 && caddy list-modules | grep -q '^http.handlers.sablier'
