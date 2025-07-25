# Flowise Helm Chart Installation Guide

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.0+
- kubectl configured to connect to your cluster

## Quick Start

### 1. Add the Helm Repository (if published)
```bash
helm repo add flowise https://amanluthra001.github.io/flowise-helm-chart/
helm repo update
```

### 2. Install Flowise
```bash
# Basic installation
helm install flowise flowise/flowise

# Custom installation with values
helm install flowise flowise/flowise -f values.yaml
```

### 3. Access Flowise
```bash
# Port forward to access locally
kubectl port-forward service/flowise 3000:3000

# Open browser to http://localhost:3000
# Default credentials: admin/1234
```

## Configuration Options

### Basic Configuration
```yaml
# values.yaml
replicaCount: 1

flowise:
  env:
    FLOWISE_USERNAME: "admin"
    FLOWISE_PASSWORD: "your-secure-password"

service:
  type: LoadBalancer  # For external access

ingress:
  enabled: true
  hosts:
    - host: flowise.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

### Production Configuration
```yaml
# production-values.yaml
replicaCount: 2

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5

persistence:
  enabled: true
  size: 5Gi
  storageClass: "fast-ssd"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: flowise.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: flowise-tls
      hosts:
        - flowise.yourdomain.com
```

## Upgrade
```bash
helm upgrade flowise flowise/flowise -f values.yaml
```

## Uninstall
```bash
helm uninstall flowise
```

## Troubleshooting

### Common Issues

1. **Pod not starting**: Check resources and image pull
2. **Database connection**: Verify database configuration
3. **Ingress not working**: Check ingress controller and DNS

### Debug Commands
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=flowise

# Check logs
kubectl logs -l app.kubernetes.io/name=flowise

# Describe pod for events
kubectl describe pod <pod-name>
```
