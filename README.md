# Helm Charts

This repository contains the Helm charts for various datastores. Users can easily install these charts and use it in the Kubernetes Clusters.

## Description

This project provides Helm charts for setting up and managing popular datastores with ease. Each chart is pre-configured to help users deploy, manage, and scale these datastores efficiently in their Kubernetes environments.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Datastores](#datastores)
- [Features](#features)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [License](#license)

## Installation

To install a specific datastore's Helm chart, use the following command:

```bash
helm repo add zop https://helm.zop.dev
helm install <release-name> zop/<chartname>
```

Replace `<release-name>` with your desired release name and `<chartname>` with the name of the datastore chart.

## Usage

Each datastore comes with a Helm chart that supports various configurable parameters. Below are examples for specific use cases:

### Install a Datastore Chart

To install a specific datastore, such as `redis`, run:

```bash
helm repo add zop https://helm.zop.dev
helm install my-redis zop/redis
```

This will deploy a `redis` instance with the default configuration.

### Customize Values

You can override default values during installation by providing a `values.yaml` file:

```bash
helm install my-redis zop/redis -f values.yaml
```

Alternatively, you can pass parameters directly via the command line:

```bash
helm install my-redis zop/redis --set image="redis:6.2.13"
```

### Upgrade a Chart

To upgrade an existing chart deployment, use:

```bash
helm upgrade my-redis zop/redis --set diskSize="5Gi"
```

### Uninstall a Chart

To uninstall a datastore deployment, use:

```bash
helm uninstall my-redis
```

### Verify Installation

To verify the installation, check the status of the release:

```bash
helm list
kubectl get pods
```

## Datastores

This repository provides Helm charts for a wide variety of datastores. Each chart is tailored to simplify the deployment and management of specific technologies. Below is an overview:

### Relational Databases

- **[MySQL](./mysql):** A widely-used open-source relational database system known for its reliability and ease of use.
  - URL: `https://helm.zop.dev/mysql`
  - Example: Use this chart to deploy MySQL for a high-availability setup.

- **[PostgreSQL](./postgres):** A powerful, open-source object-relational database system.
  - URL: `https://helm.zop.dev/postgres`
  - Example: Ideal for handling complex queries and transactional workloads.

### NoSQL Databases

- **[Redis](./redis):** An in-memory data structure store, used as a database, cache, and message broker.
  - URL: `https://helm.zop.dev/redis`
  - Example: Deploy a Redis cluster with persistence enabled for caching and session storage.

- **[SurrealDB](./surrealdb):** A cloud-native database for modern, highly-scalable applications.
  - URL: `https://helm.zop.dev/surrealdb`
  - Example: Use this chart to deploy SurrealDB for high-speed real-time analytics.

### Graph Databases

- **[Dgraph](./dgraph):** A distributed, fast, and scalable graph database.
  - URL: `https://helm.zop.dev/dgraph`
  - Example: Use this chart for graph-based querying and data visualization.

### Search and Analytics

- **[Solr](./solr):** An open-source search platform for enterprise-scale applications.
  - URL: `https://helm.zop.dev/solr`
  - Example: Deploy Solr for full-text search and analytics.

- **[OpenTSDB](./opentsdb):** A distributed, scalable time-series database.
  - URL: `https://helm.zop.dev/opentsdb`
  - Example: Ideal for managing and querying large-scale time-series data.

### Specialized Services

- **[ChromaDB](./chromadb):** A specialized datastore designed for AI and machine learning workloads.
  - URL: `https://helm.zop.dev/chromadb`
  - Example: Use this chart for managing vector embeddings in ML applications.

- **[Cron-Job](./cron-job):** A datastore setup for scheduling and managing cron jobs.
  - URL: `https://helm.zop.dev/cron-job`
  - Example: Deploy this chart to handle background tasks in your application.

- **[Service](./service):** A generic service chart to deploy and manage custom services.
  - URL: `https://helm.zop.dev/service`
  - Example: Extend this chart to suit your unique service deployment needs.

## Features

- **Wide Range of Datastores:** Helm charts available for relational, NoSQL, graph, and other specialized databases.
- **Ease of Use:** Simplified installation process using Helm.
- **Pre-configured Settings:** Default configurations tailored for most use cases.
- **Scalability:** Easily scale datastores to meet your requirements.
- **Extensibility:** Modify the charts to suit your custom needs.

## Contributing

We welcome contributions! Please follow the guidelines below:

1. Fork the repository and clone it locally.
2. Create a branch for your feature or bug fix.
3. Commit your changes with descriptive messages.
4. Submit a pull request.

For more details, check the [CONTRIBUTING.md](./CONTRIBUTING.md) file.

## Code of Conduct

Please adhere to our [Code of Conduct](./CODE_OF_CONDUCT.md) to ensure a respectful and inclusive community.

## License

This project is licensed under the terms of the [LICENSE](./LICENSE). Please review it for more information.