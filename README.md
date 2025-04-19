<p align="center">
  <img src="https://zop.dev/resources/cdn/newsletter/zopdev-transparent-logo.png" alt="zop.dev Logo" width="200">
</p>

<h2 align="center">Helm Charts : An Extensive Collection of Helm Charts for Datastores & Applications</h2>

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
4. **Scalability & Flexibility:**  
   Designed to adapt to various production workloads with ease.

---

## 🚀 **Getting Started**

### **Prerequisites**
- **Helm:** Ensure [Helm](https://helm.sh/docs/intro/install/) is installed.
- **Kubernetes:** Access to a running Kubernetes cluster.

### **Installation**

To add the zop.dev repository and install a chart, run:

```bash
helm repo add zop https://helm.zop.dev
helm install <release-name> zop/<chartname>
```

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
  ```

---


## 📂 **Available Charts**

Below is a list of available charts along with their links:

1. **DATASOURCES**

| **Name**              | **Link**                                                                 | **Metrics** |
|-----------------------|--------------------------------------------------------------------------|-------------|
| **MySQL**             | [helm.zop.dev/mysql](https://helm.zop.dev/mysql)                         | ✅           |
| **PostgreSQL**        | [helm.zop.dev/postgres](https://helm.zop.dev/postgres)                   | ✅           |
| **MariaDB**           | [helm.zop.dev/mariadb](https://helm.zop.dev/mariadb)                     |             |
| **Redis**             | [helm.zop.dev/redis](https://helm.zop.dev/redis)                         | ✅           |
| **SurrealDB**         | [helm.zop.dev/surrealdb](https://helm.zop.dev/surrealdb)                 |             |
| **Dgraph**            | [helm.zop.dev/dgraph](https://helm.zop.dev/dgraph)                       |             |
| **Solr**              | [helm.zop.dev/solr](https://helm.zop.dev/solr)                           |             |
| **OpenTSDB**          | [helm.zop.dev/opentsdb](https://helm.zop.dev/opentsdb)                   |             |
| **ChromaDB**          | [helm.zop.dev/chromadb](https://helm.zop.dev/chromadb)                   |             |
| **Cassandra**         | [helm.zop.dev/cassandra](https://helm.zop.dev/cassandra)                 |             |
| **CockroachDB**       | [helm.zop.dev/cockroachdb](https://helm.zop.dev/cockroachdb)             |             |
| **Kafka**             | [helm.zop.dev/kafka](https://helm.zop.dev/kafka)                         |             |
| **RedisDistributed**  | [helm.zop.dev/redisdistributed](https://helm.zop.dev/redisdistributed)   | ✅           |
| **SolrCloud**         | [helm.zop.dev/solrcloud](https://helm.zop.dev/solrcloud)                 |             |


2. **APPLICATIONS**

| **Name**       | **Link**                                                   |
|----------------|------------------------------------------------------------|
| **JupyterHub** | [helm.zop.dev/jupyterhub](https://helm.zop.dev/jupyterhub) |
| **Outline**    | [helm.zop.dev/outline](https://helm.zop.dev/outline)       |
| **Superset**   | [helm.zop.dev/superset](https://helm.zop.dev/superset)     |
| **WordPress**  | [helm.zop.dev/wordpress](https://helm.zop.dev/wordpress)   |


3. **OTHERS**

| **Name**     | **Link**                                               | **Metrics** |
|--------------|--------------------------------------------------------|-------------|
| **Cron-Job** | [helm.zop.dev/cron-job](https://helm.zop.dev/cron-job) | ✅           |
| **Service**  | [helm.zop.dev/service](https://helm.zop.dev/service)   | ✅           |


📊 **Metrics Export** - All charts that support metrics expose them on port 2121 by default.

---

## 👍 **Contribute**

We welcome contributions to improve and expand our Helm charts. To contribute please refer to the [CONTRIBUTING.md](./CONTRIBUTING.md) file.

---

## 🔒 **License**

This project is licensed under the [Apache 2.0 License](./LICENSE).

---

## 📣 **Stay Connected**

For updates and support, visit the [zop.dev website](https://helm.zop.dev) or join our community discussions.