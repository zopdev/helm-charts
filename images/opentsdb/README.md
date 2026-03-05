# OpenTSDB Docker Image

The OpenTSDB Docker image packages OpenTSDB, a scalable time-series database, along with a standalone HBase instance and gnuplot for graph rendering. Built on Alpine Linux for a minimal footprint, this image is intended for use with the [OpenTSDB Helm chart](../../charts/opentsdb/).

---

## Components & Versions

| Component   | Version | Description                              |
|-------------|---------|------------------------------------------|
| OpenTSDB    | 2.3.1   | Scalable time-series database            |
| HBase       | 1.4.4   | Distributed storage backend for OpenTSDB |
| Java (JDK)  | 8       | Required runtime for OpenTSDB and HBase  |
| gnuplot     | 5.2.4   | Graph rendering for OpenTSDB             |
| Tini        | 0.18.0  | Init system for proper signal handling   |

---

## Prerequisites

- Docker 20.10+

---

## Build Image

To build the Docker image, run the following command from the repository root:

```bash
docker build -f images/opentsdb/Dockerfile -t opentsdb:latest images/
```

---

## Run Container

To run the OpenTSDB container:

```bash
docker run -d \
  -p 4242:4242 \
  -p 16010:16010 \
  -p 16070:16070 \
  -v opentsdb-data:/data/hbase \
  --name opentsdb \
  opentsdb:latest
```

---

## Exposed Ports

| Port  | Description              |
|-------|--------------------------|
| 4242  | OpenTSDB HTTP API        |
| 16010 | HBase Master Web UI      |
| 16070 | HBase RegionServer Web UI|
| 60000 | HBase Master RPC         |
| 60010 | HBase Master Info        |
| 60030 | HBase RegionServer Info  |

---

## Volumes

| Path                | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `/data/hbase`       | All OpenTSDB and HBase data. **Must be persisted to avoid data loss.**      |
| `/tmp`              | Temporary files and OpenTSDB cache directory.                               |
| `/opentsdb-plugins` | Directory for OpenTSDB plugins.                                             |

---

## Environment Variables

| Variable     | Description                            | Default                          |
|--------------|----------------------------------------|----------------------------------|
| `JAVA_HOME`  | Path to the Java installation.         | `/usr/lib/jvm/java-1.8-openjdk` |
| `HBASE_OPTS` | JVM options for HBase.                 | G1GC with cgroup memory flags    |
| `JVMARGS`    | JVM options for OpenTSDB.              | G1GC with cgroup memory flags    |
| `WAITSECS`   | Seconds to wait for HBase before starting OpenTSDB. | `45`                |

---

## File Structure

```
images/opentsdb/
├── Dockerfile
├── README.md
└── files/
    ├── opentsdb.conf             # OpenTSDB configuration
    ├── hbase-site.xml            # HBase site configuration
    ├── entrypoint.sh             # Container entrypoint script
    ├── start_hbase.sh            # HBase startup script
    ├── start_opentsdb.sh         # OpenTSDB startup script
    └── create_tsdb_tables.sh     # Initial table creation script
```

---

## Configuration

### OpenTSDB (`opentsdb.conf`)

| Parameter                         | Value                                     | Description                            |
|-----------------------------------|-------------------------------------------|----------------------------------------|
| `tsd.network.port`               | `4242`                                    | API listen port                        |
| `tsd.core.auto_create_metrics`   | `true`                                    | Auto-create metrics on write           |
| `tsd.storage.hbase.zk_quorum`   | `zookeeper`                               | ZooKeeper quorum for HBase             |
| `tsd.storage.hbase.zk_basedir`  | `/hbase`                                  | ZooKeeper base directory               |
| `tsd.core.plugin_path`          | `/opentsdb-plugins`                       | Path for OpenTSDB plugins              |

### HBase (`hbase-site.xml`)

| Parameter                              | Value         | Description                             |
|----------------------------------------|---------------|-----------------------------------------|
| `hbase.rootdir`                        | `file:///data/hbase` | Data storage directory             |
| `hbase.zookeeper.quorum`              | `zookeeper`   | ZooKeeper quorum hostname               |
| `hbase.zookeeper.property.clientPort` | `2181`        | ZooKeeper client port                   |
| `hbase.cluster.distributed`           | `true`        | Run HBase in distributed mode           |

---

## Startup Sequence

1. The entrypoint script starts **HBase** (master + regionserver) in the background.
2. Waits for HBase to initialize (default 45 seconds, configurable via `WAITSECS`).
3. On first run, creates the required OpenTSDB tables in HBase.
4. Starts the **OpenTSDB** daemon on port 4242.
5. On `SIGTERM`, gracefully shuts down OpenTSDB and HBase to prevent WAL corruption.

---

## Features

- **Minimal Image:** Built on Alpine Linux to reduce image size.
- **Signal Handling:** Uses Tini as init to ensure clean shutdowns and prevent WAL corruption.
- **Auto Table Creation:** Automatically creates OpenTSDB tables on first startup.
- **JVM Tuning:** Pre-configured G1GC with container-aware memory settings.
- **Graceful Shutdown:** Properly flushes WALs and stops HBase on container termination.

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
