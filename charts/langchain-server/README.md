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

---

## 🎯 Goal

The `langchain-server` Helm chart enables seamless deployment of a LangChain Server on Kubernetes. It includes optional integration with Postgres and Redis, and is designed for cloud-native orchestration of LLM pipelines using chains, agents, tools, and memory components.

---

## 💡 Key Features

* 🚀 LangChain Server containerized deployment
* 📦 Optional PostgreSQL and Redis integration
* 🔌 LLM provider integration via environment variables
* 🔐 Ingress with TLS support
* 💾 PersistentVolume support
* ⚙️ Configurable resource limits and replica scaling

---

## 🚀 Getting Started

### Prerequisites

* [Helm](https://helm.sh/docs/intro/install/)
* Access to a running Kubernetes cluster (e.g., Minikube, GKE, etc.)

### Installation

```bash
helm repo add zop https://helm.zop.dev
helm install langchain-server zop/langchain-server
```

To install from source:

```bash
helm install langchain charts/langchain-server
```

### Overriding Values

```bash
helm install langchain charts/langchain-server -f values.yaml
```

---

## 🧰 Configuration

The following configuration options are available in `values.yaml`:

### Image

```yaml
image:
  repository: nginx
  tag: "1.28.0"
  pullPolicy: IfNotPresent
```

### Service

```yaml
service:
  type: ClusterIP
  port: 80
```

### Environment Variables

```yaml
env:
  MODEL_PROVIDER: "openai"
  API_KEYS: "your-api-key"
```

### PostgreSQL

```yaml
postgres:
  enabled: true
  image: postgres:15
  username: langchain
  password: langchain123
  dbName: langchain_db
```

### Redis

```yaml
redis:
  enabled: true
  image: redis:7
```

### Ingress

```yaml
ingress:
  enabled: false
  annotations: {}
  hosts:
    - host: langchain.local
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

### Persistence

```yaml
persistence:
  enabled: true
  accessModes:
    - ReadWriteOnce
  size: 1Gi
```

---

## 🧪 Testing Checklist

| Test Type       | Status                 |
| --------------- | ---------------------- |
| Helm Lint       | ✅ Passed               |
| Template Render | ✅ Passed               |
| Minikube Deploy | ✅ Passed (with nginx)  |
| Redis/Postgres  | ✅ Enabled, Deployable  |
| Local Access    | ✅ Confirmed via tunnel |

---

## 📂 Chart Structure

```
charts/
└── langchain-server/
    ├── Chart.yaml
    ├── values.yaml
    ├── README.md
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        ├── ingress.yaml
        ├── configmap.yaml
        ├── pvc.yaml
        ├── postgres.yaml
        ├── redis.yaml
        └── _helpers.tpl
```

---

## 👷 **Maintainer**

| Name   | Website                  | GitHub                      |
|--------|--------------------------|-----------------------------|
| ZopDev | [zop.dev](https://zop.dev) | [zopdev](https://github.com/zopdev) |


---

## 📄 License

This Helm chart is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 📚 References

* [LangChain GitHub](https://github.com/langchain-ai/langchain)
* [Helm Docs](https://helm.sh/docs/)
* [Kubernetes Docs](https://kubernetes.io/docs/home/)
