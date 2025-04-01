<p align="center">
  <img src="https://zop.dev/resources/cdn/newsletter/zopdev-transparent-logo.png" alt="zop.dev Logo" width="100">
</p>

<h1 align="center">The Helm Charts Library for zop.dev</h1>

<h2 align="center">An Extensive Collection of Helm Charts for Datastores & Applications</h2>

<p align="center">
  <a href="./LICENSE">
    <img src="https://img.shields.io/badge/License-Apache_2.0-blue?style=for-the-badge" alt="Apache 2.0 License">
  </a>
  <a href="./CONTRIBUTING.md">
    <img src="https://img.shields.io/badge/Contribute-Guide-orange?style=for-the-badge" alt="Contributing">
  </a>
</p>

## 🎯 **Goal**

The zop.dev Helm Charts repository is designed to **simplify the deployment and management** of popular datastores and applications on Kubernetes. With pre-configured charts that work out-of-the-box and allow for explicit overrides, our goal is to streamline operations and integrate seamlessly with the zop.dev ecosystem.

---

## 💡 **Key Features**

1. **Zero Configuration Required:**  
   Charts deploy with default values—no manual configuration is needed to get started.
2. **Explicit Override Options:**  
   Users can override selected parameters through a dedicated `values.yaml` with a corresponding `values.schema.json` that marks user-modifiable fields with `"mutable": true`.
3. **Automatic Integration:**  
   Every chart includes a required metadata annotation (`type: datasource` or `type: application`), ensuring automatic reflection in the zop.dev Applications and Datasources section.
4. **Tailored for Applications & Datasources:**  
   - **Applications:** Utilize the **service** Helm chart which bundles configurations for HPA, deployments, alerts, Grafana, ingress, pod-distribution budgets, PVCs, service monitors etc. Application-specific credentials (ID and password) are automatically handled via templated files (e.g. `<release-name>-login.yaml`), so users need not supply these values.
   - **Datasources:** While supporting a broad range of configurable options, datasource charts are optimized to minimize required values, reducing user input to only the essentials.
5. **Scalability & Flexibility:**  
   Designed to adapt to various production workloads with ease.

---

## 🚀 **Getting Started**

### **Prerequisites**
- **Helm:** Ensure [Helm](https://helm.sh/docs/intro/install/) is installed.
- **Kubernetes:** Access to a running Kubernetes cluster.
- **kubectl:** Configured to interact with your cluster.

### **Installation**

To add the zop.dev repository and install a chart, run:

```bash
helm repo add zop https://helm.zop.dev
helm install <release-name> zop/<chartname>
```

Replace `<release-name>` with your desired release name and `<chartname>` with the name of the chart (e.g., `redis` for datasource or `service` for an application).

---

### **Examples**

### **Deploying an Application Chart:**

  ```bash
  helm repo add zop https://helm.zop.dev
  helm install my-app zop/service
  ```

### **Overriding Values:**

  To customize certain values that are marked mutable, provide a custom `values.yaml`:

  ```bash
  helm install my-app zop/service -f values.yaml
  ```

### **Upgrading & Uninstalling:**

  Upgrade an existing release:

  ```bash
  helm upgrade my-app zop/service --set ingress.enabled=true
  ```

###  Uninstall a release:

  ```bash
  helm uninstall my-app
  ```

###  Verify your deployments:

  ```bash
  helm list
  kubectl get pods
  ```

---


## 📂 **Available Charts**

Below is a list of available charts along with their links:

| **Name**      | **Link**                                          | **Description**                                                                                                                                                           |
|---------------|----------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **MySQL**     | [helm.zop.dev/mysql](https://helm.zop.dev/mysql)   | A widely-used open-source relational database system known for its reliability and ease of use.                                                                           |
| **PostgreSQL**| [helm.zop.dev/postgres](https://helm.zop.dev/postgres) | A powerful, open-source object-relational database system ideal for handling complex queries and transactional workloads.                                                |
| **MariaDB**   | [helm.zop.dev/mariadb](https://helm.zop.dev/mariadb) | A popular open-source relational database, highly compatible with MySQL, suitable for both master-slave replication and standalone setups.                               |
| **Redis**     | [helm.zop.dev/redis](https://helm.zop.dev/redis)   | An in-memory data structure store used as a database, cache, and message broker, with support for persistence.                                                           |
| **SurrealDB** | [helm.zop.dev/surrealdb](https://helm.zop.dev/surrealdb) | A cloud-native database designed for modern, highly scalable applications and real-time analytics.                                                                     |
| **Dgraph**    | [helm.zop.dev/dgraph](https://helm.zop.dev/dgraph) | A distributed, fast, and scalable graph database for efficient graph-based querying and data visualization.                                                              |
| **Solr**      | [helm.zop.dev/solr](https://helm.zop.dev/solr)     | An open-source search platform built for enterprise-scale full-text search and analytics.                                                                               |
| **OpenTSDB**  | [helm.zop.dev/opentsdb](https://helm.zop.dev/opentsdb) | A distributed, scalable time-series database ideal for managing and querying large-scale time-series data.                                                                |
| **ChromaDB**  | [helm.zop.dev/chromadb](https://helm.zop.dev/chromadb) | A specialized datastore designed for AI and machine learning workloads, including managing vector embeddings.                                                           |
| **Cron-Job**  | [helm.zop.dev/cron-job](https://helm.zop.dev/cron-job) | A Helm chart for scheduling and managing cron jobs to handle background tasks efficiently.                                                                              |
| **Service**   | [helm.zop.dev/service](https://helm.zop.dev/service)  | A generic service chart for deploying and managing custom services with built-in configurations for HPA, deployments, alerts, Grafana, ingress, pod budgets, PVCs, etc. |

---


## 👍 **Contribute**

We welcome contributions to improve and expand our Helm charts. To contribute please refer to the [CONTRIBUTING.md](./CONTRIBUTING.md) file.

---

## 🔒 **License**

This project is licensed under the [Apache 2.0 License](./LICENSE).

---

## 📣 **Stay Connected**

For updates and support, visit the [zop.dev website](https://helm.zop.dev) or join our community discussions.