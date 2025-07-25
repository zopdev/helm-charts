# LangChain Server Helm Chart

This Helm chart deploys the **LangChain Server**, a self-hosted orchestration platform for running Language Model (LLM) pipelines using LangChain components such as chains, agents, tools, and memory systems.

---

## 🧠 Features

* LangChain Server containerized deployment
* Optional PostgreSQL database for metadata/session storage
* Optional Redis instance for memory/cache layer
* API exposure via Kubernetes Service and optional Ingress
* Environment variable support for connecting to OpenAI, HuggingFace, Ollama, etc.
* Configurable CPU/GPU resource limits
* Persistent volume support for caching

---

## 📦 Chart Structure

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
        └── _helpers.tpl
```

---

## 🚀 Usage

### 1. Lint the chart

```bash
helm lint charts/langchain-server
```

### 2. Render the chart

```bash
helm template langchain charts/langchain-server
```

### 3. Deploy on Minikube

```bash
minikube start --driver=docker
helm install langchain charts/langchain-server
```

### 4. Access via browser

```bash
minikube service langchain-langchain
```

---

## 🔧 Configuration Parameters

The following values can be set via `values.yaml` or CLI overrides:

### Deployment Options

```yaml
replicaCount: 1
image:
  repository: ghcr.io/langchain-ai/langchainplus
  tag: latest
  pullPolicy: IfNotPresent
```

### Service Options

```yaml
service:
  type: ClusterIP
  port: 8000
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

## 🧪 Testing Status

| Test Type       | Status                      |
| --------------- | --------------------------- |
| Helm Lint       | ✅ Passed                    |
| Template Render | ✅ Passed                    |
| Minikube Deploy | ✅ Passed (with nginx image) |
| Local Access    | ✅ Success                   |

---

## 👨‍💻 Maintainer

**Developer:** Krishna Kumar

**Email:** [meet.kumarkrishna@gmail.com](mailto:meet.kumarkrishna@gmail.com)

**GitHub:** [Krishnaqwerty](https://github.com/krishnaqwerty)

---

## 📄 License

This Helm chart is open-source and may be used under the [MIT License](https://opensource.org/licenses/MIT) unless otherwise specified by ZopDev.

---

## 📚 References

* [LangChain GitHub](https://github.com/langchain-ai/langchain)
* [Helm Docs](https://helm.sh/docs/)
* [Kubernetes Docs](https://kubernetes.io/docs/home/)
