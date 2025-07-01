# 📦 ToolJet Helm Chart

![ToolJet](https://avatars.githubusercontent.com/u/87657345?s=200&v=4)

This Helm chart deploys **[ToolJet](https://tooljet.com/)** — a modern open-source low-code platform that lets teams build internal tools with ease. You can self-host ToolJet on any Kubernetes cluster using this chart.

---

## 🚀 Features

- ✅ Deploy ToolJet with just one command
- ⚙️ Customizable environment variables
- 🌐 Optional ingress support
- 📈 Scalable with built-in autoscaling settings
- 🔒 Deploy-ready with service accounts and resource limits

---

## 📦 Installing the Chart

### Prerequisites

- Kubernetes cluster (local or cloud)
- Helm v3+

### Install ToolJet

```bash
helm install my-tooljet ./tooljet
helm uninstall my-tooljet

🛠 Configuration
You can override default settings by editing values.yaml or using --set:

Parameter	Description	Default
service.port	Port where ToolJet runs	3000
env.TOOLJET_HOST	Host address	0.0.0.0
ingress.enabled	Enable Ingress	false
autoscaling.enabled	Enable autoscaling	false
resources	CPU/memory limits	Configurable

📚 References
ToolJet GitHub

ToolJet Docs

Helm Docs

👨‍💻 Maintainers
Name	Email
Madira Mahanandi Reddy	madhirereddy4@gmail.com

Crafted with 💻 and ☁️ by the community. Fork, deploy, and power your internal apps!

yaml
Copy
Edit


---

