# Mosquitto Helm Chart

A fully-templated, production-grade Helm chart for deploying the [Eclipse Mosquitto](https://mosquitto.org/) MQTT broker on Kubernetes.

---

## ✨ Features

- ✅ Lightweight MQTT 3.1/3.1.1/5.0 support
- 🔐 Optional authentication via Kubernetes Secrets
- 🔒 TLS support using pre-generated secrets
- 💾 Persistent volume support for data durability
- ⚙️ Custom `mosquitto.conf` via ConfigMap
- 📦 Resource limits and health probes

---

## 🚀 Installation

helm repo add my-repo https://your.repo.url/
helm install mosquitto my-repo/mosquitto
