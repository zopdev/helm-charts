# db-init Docker Image

The db-init Docker image packages MySQL and PostgreSQL command-line clients with a small entrypoint that runs a multi-statement SQL file (`CREATE DATABASE` / `CREATE USER` / `GRANT` / teardown) against a managed datastore. Built on Debian Bookworm slim for broad MySQL 8 (`caching_sha2_password`) and PostgreSQL 15 compatibility, this image is intended to be scheduled by the ZopDay provisioner as a one-shot Kubernetes Job inside the customer's cluster (namespace `zop-system`).

---

## Components & Versions

| Component               | Version        | Description                                                |
|-------------------------|----------------|------------------------------------------------------------|
| Debian (bookworm-slim)  | 12             | Base OS                                                    |
| default-mysql-client    | 10.11 (MariaDB) | MySQL CLI; speaks MySQL 8's `caching_sha2_password`       |
| postgresql-client       | 15             | PostgreSQL CLI                                             |
| Bash                    | 5.x            | Required runtime for the entrypoint                        |

---

## Prerequisites

- Docker 20.10+

---

## Build Image

To build the Docker image, run the following command from the repository root:

```bash
docker build -f images/db-init/Dockerfile -t db-init:latest images/
```

---

## Run Container

To exercise the container locally against a reachable datastore:

```bash
docker run --rm \
  -e ENGINE=mysql \
  -e DB_HOST=127.0.0.1 \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=secret \
  -v $(pwd)/db-init.sql:/etc/db-init/db-init.sql:ro \
  db-init:latest
```

In production the image is invoked by the provisioner as a Kubernetes Job; the SQL file is mounted from a ConfigMap and the connection details come from a Secret.

---

## Volumes

| Path                       | Description                                                                       |
|----------------------------|-----------------------------------------------------------------------------------|
| `/etc/db-init/db-init.sql` | SQL file rendered by the provisioner (mounted from a ConfigMap, read-only).       |

---

## Environment Variables

| Variable      | Description                                                              | Default                       |
|---------------|--------------------------------------------------------------------------|-------------------------------|
| `ENGINE`      | Datastore engine. **Required.** One of `mysql`, `postgres`.              | —                             |
| `DB_HOST`     | Datastore endpoint reachable from the pod (private IP / DNS). **Required.** | —                          |
| `DB_PORT`     | Datastore port. **Required.**                                            | —                             |
| `DB_USER`     | Admin username. **Required.**                                            | —                             |
| `DB_PASSWORD` | Admin password. **Required.**                                            | —                             |
| `OPERATION`   | Informational label (`create`, `drop`, `provision`, `teardown`).         | `run`                         |
| `SQL_FILE`    | Path to the SQL file inside the container.                               | `/etc/db-init/db-init.sql`    |

---

## File Structure

```
images/db-init/
├── Dockerfile
├── README.md
└── entrypoint.sh   # Container entrypoint script
```

---

## Execution Flow

1. The entrypoint validates that all required environment variables are set.
2. It verifies that the SQL file exists at `SQL_FILE`.
3. Based on `ENGINE`:
   - **mysql:** pipes the SQL file into `mysql --protocol=TCP` via stdin (avoids the `source` builtin, which silently ignores statement errors).
   - **postgres:** runs the SQL file via `psql --set=ON_ERROR_STOP=1`, aborting on the first error.
4. On success the entrypoint exits `0`. On failure it exits non-zero, the pod fails, and the provisioner reads the pod logs to surface the error in the step's `errorMessage`.

---

## Features

- **Cloud-agnostic:** Runs from inside the customer's cluster, so private-endpoint MySQL / Postgres datastores stay reachable without public exposure.
- **Fail-fast:** `set -eu -o pipefail` plus engine-specific abort flags ensure a half-applied SQL script never reports success.
- **Minimal surface:** Single binary entrypoint, no daemon, no persistent state. Runs as `nobody`.
- **Engine parity:** Same image handles both MySQL and PostgreSQL so the provisioner only pins one tag.

---

## Publish

The image is published via the `Image Deployment` GitHub Actions workflow. Push a tag in the form `db-init-image-v<N>` to trigger the build:

```bash
git tag db-init-image-v1
git push origin db-init-image-v1
```

This produces:

- `zopdev/db-init:v<N>`
- `zopdev/db-init:latest`

Bump the version on every breaking change to the entrypoint contract; the provisioner pins the image via the `DB_INIT_IMAGE` config value.

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
