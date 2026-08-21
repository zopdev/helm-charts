<p align="center">
  <picture>
    <!-- The logo is a dark wordmark on a transparent background, so it
         disappears on GitHub's dark canvas. Dark mode gets the same
         image flattened onto white by an image proxy - same source
         asset, no second file to host. -->
    <source media="(prefers-color-scheme: dark)" srcset="https://wsrv.nl/?url=zop.dev/logo.png&amp;bg=white">
    <img src="https://zop.dev/logo.png" alt="zop.dev Logo" width="200">
  </picture>
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

| **Name**             | **Link**                                                               | **Metrics** |
|----------------------|------------------------------------------------------------------------|-------------|
| **MySQL**            | [helm.zop.dev/mysql](https://helm.zop.dev/src/readme.html?id=mysql)                       | ✅           |
| **PostgreSQL**       | [helm.zop.dev/postgres](https://helm.zop.dev/src/readme.html?id=postgres)                 | ✅           |
| **MariaDB**          | [helm.zop.dev/mariadb](https://helm.zop.dev/src/readme.html?id=mariadb)                   | ✅           |
| **Redis**            | [helm.zop.dev/redis](https://helm.zop.dev/src/readme.html?id=redis)                       | ✅           |
| **SurrealDB**        | [helm.zop.dev/surrealdb](https://helm.zop.dev/src/readme.html?id=surrealdb)               |             |
| **Dgraph**           | [helm.zop.dev/dgraph](https://helm.zop.dev/src/readme.html?id=dgraph)                     |             |
| **Solr**             | [helm.zop.dev/solr](https://helm.zop.dev/src/readme.html?id=solr)                         | ✅           |
| **OpenTSDB**         | [helm.zop.dev/opentsdb](https://helm.zop.dev/src/readme.html?id=opentsdb)                 |             |
| **ChromaDB**         | [helm.zop.dev/chromadb](https://helm.zop.dev/src/readme.html?id=chromadb)                 |             |
| **Cassandra**        | [helm.zop.dev/cassandra](https://helm.zop.dev/src/readme.html?id=cassandra)               |             |
| **CockroachDB**      | [helm.zop.dev/cockroachdb](https://helm.zop.dev/src/readme.html?id=cockroachdb)           |             |
| **ClickHouse**       | [helm.zop.dev/clickhouse](https://helm.zop.dev/src/readme.html?id=clickhouse)             | ✅           |
| **Kafka**            | [helm.zop.dev/kafka](https://helm.zop.dev/src/readme.html?id=kafka)                       | ✅           |
| **RedisDistributed** | [helm.zop.dev/redisdistributed](https://helm.zop.dev/src/readme.html?id=redisdistributed) | ✅           |
| **SolrCloud**        | [helm.zop.dev/solrcloud](https://helm.zop.dev/src/readme.html?id=solrcloud)               |             |
| **ScyllaDB**         | [helm.zop.dev/scylladb](https://helm.zop.dev/src/readme.html?id=scylladb)               |             |


2. **APPLICATIONS**

| **Name** | **Link** | **Deploy** |
|---|---|---|
| **HolmesGPT** | [helm.zop.dev/holmesgpt](https://helm.zop.dev/src/readme.html?id=holmesgpt) | <a href="https://zop.dev/zopday/app/deploy?install=holmesgpt"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |
| **Immich** | [helm.zop.dev/immich](https://helm.zop.dev/src/readme.html?id=immich) | <a href="https://zop.dev/zopday/app/deploy?install=immich"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |
| **JupyterHub** | [helm.zop.dev/jupyterhub](https://helm.zop.dev/src/readme.html?id=jupyterhub) | <a href="https://zop.dev/zopday/app/deploy?install=jupyterhub"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |
| **LiteLLM** | [helm.zop.dev/litellm](https://helm.zop.dev/src/readme.html?id=litellm) | <a href="https://zop.dev/zopday/app/deploy?install=litellm"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |
| **LocalAI** | [helm.zop.dev/localai](https://helm.zop.dev/src/readme.html?id=localai) | <a href="https://zop.dev/zopday/app/deploy?install=localai"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |
| **Outline** | [helm.zop.dev/outline](https://helm.zop.dev/src/readme.html?id=outline) | <a href="https://zop.dev/zopday/app/deploy?install=outline"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |
| **Superset** | [helm.zop.dev/superset](https://helm.zop.dev/src/readme.html?id=superset) | <a href="https://zop.dev/zopday/app/deploy?install=superset"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |
| **WordPress** | [helm.zop.dev/wordpress](https://helm.zop.dev/src/readme.html?id=wordpress) | <a href="https://zop.dev/zopday/app/deploy?install=wordpress"><img src="https://zop.dev/deploytozopday-inkhard.svg" alt="Deploy to Zopday" height="28"></a> |


3. **OTHERS**

| **Name** | **Link** | **Metrics** |
|---|---|---|
| **Cron-Job** | [helm.zop.dev/cron-job](https://helm.zop.dev/src/readme.html?id=cron-job) | ✅ |
| **Service** | [helm.zop.dev/service](https://helm.zop.dev/src/readme.html?id=service) | ✅ |
| **OpenObserve** | [helm.zop.dev/openobserve-standalone](https://helm.zop.dev/src/readme.html?id=openobserve-standalone) |  |
| **Uptime Monitoring** | [helm.zop.dev/uptime-monitoring](https://helm.zop.dev/src/readme.html?id=uptime-monitoring) |  |
| **ZooKeeper** | [helm.zop.dev/zookeeper](https://helm.zop.dev/src/readme.html?id=zookeeper) |  |
| **ZooKeeper Operator** | [helm.zop.dev/zookeeper-operator](https://helm.zop.dev/src/readme.html?id=zookeeper-operator) |  |
| **Solr Operator** | [helm.zop.dev/solr-operator](https://helm.zop.dev/src/readme.html?id=solr-operator) |  |
| **Karpenter (GCP)** | [helm.zop.dev/karpenter-gcp](https://helm.zop.dev/src/readme.html?id=karpenter-gcp) |  |


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