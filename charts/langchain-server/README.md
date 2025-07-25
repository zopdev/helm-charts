# LangChain Server Helm Chart

This Helm chart deploys a self-hosted LangChain Server instance, allowing orchestration of LLM pipelines using LangChain components.

## Features
- Dynamic LLM pipeline orchestration
- Optional Redis and Postgres integration
- Ingress with TLS support
- Persistent volume for caching/memory
- GPU/CPU configuration via values.yaml

## Usage

```bash
helm install langchain-server ./charts/langchain-server
