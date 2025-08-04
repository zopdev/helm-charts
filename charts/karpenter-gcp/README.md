# Karpenter GCP Helm Chart

This Helm chart deploys Karpenter on a GKE (Google Kubernetes Engine) cluster using GCP-specific provisioning. Karpenter is an open-source Kubernetes node provisioning system built for performance, flexibility, and cost efficiency. This chart provides the necessary components to integrate Karpenter with GCP, allowing dynamic, workload-driven node scaling.

---

## Prerequisites

- Kubernetes v1.23+
- Helm 3.0+
- Required GCP APIs enabled:
    - `compute.googleapis.com`
    - `container.googleapis.com`
- A GCP service account with the following roles:
    - Compute Admin
    - Kubernetes Engine Admin
    - Monitoring Admin
    - Service Account User
- A Kubernetes secret containing the GCP service account key (JSON)

---

## Add Helm Repository

Add the Helm repository by running:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

For more details, see the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/).

---

## Create Cluster Secret

Create a Kubernetes `Secret` containing your GCP service account credentials. This secret is mounted into the Karpenter controller pod and must match the name and key configured in `values.yaml` (`credentials.secretName` and `credentials.secretKey`).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: karpenter-gcp-credentials
  namespace: <namespace>
type: Opaque
stringData:
  key.json: |
    {
      "type": "service_account",
      "project_id": "<your-project-id>",
      "private_key_id": "<your-private-key-id>",
      "private_key": "<your-private-key>",
      "client_email": "<your-client-email>",
      "client_id": "<your-client-id>",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "<your-client-x509-cert-url>",
      "universe_domain": "googleapis.com"
    }
```
Save it as gcp-secret.yaml and apply it using:

```bash
kubectl apply -f gcp-secret.yaml
```

## Install Helm Chart

To deploy the JupyterHub Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/karpenter-gcp
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-karpenter zopdev/karpenter-gcp
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

### Post-Installation: Deploy NodeClass and NodePool

After successfully installing the Helm chart, you will need to define and apply NodeClass and NodePool resources based on Custom Resource Definitions in this helm chart. These resources are crucial for Karpenter to begin provisioning nodes.

Example manifests:

#### NodeClass

```yaml
apiVersion: karpenter.k8s.gcp/v1alpha1
kind: GCENodeClass
metadata:
  name: default-example
spec:
  serviceAccount: "<service_account_email_created_before>"
  imageSelectorTerms:
    - alias: ContainerOptimizedOS@latest
  tags:
    env: dev
```
#### NodePool

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default-nodepool
spec:
  weight: 10
  template:
    spec:
      nodeClassRef:
        name: default-example
        kind: GCENodeClass
        group: karpenter.k8s.gcp
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand", "spot"]
        - key: "karpenter.k8s.gcp/instance-family"
          operator: In
          values: ["n4-standard", "n2-standard", "e2"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ["us-central1-c", "us-central1-a", "us-central1-f", "us-central1-b"]
```

## Uninstall Helm Chart

To remove the JupyterHub Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-karpenter
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

This Helm chart includes several configurable parameters to adapt deployment to your environment:

### GCP Controller Settings

| **Input** | **Type** | **Description** | **Default** |
|----------|----------|------------------|-------------|
| `controller.settings.projectID` | `string` | GCP project ID | `""` |
| `controller.settings.region` | `string` | GCP region | `""` |
| `controller.settings.clusterName` | `string` | GKE cluster name | `""` |
| `controller.settings.vmMemoryOverheadPercent` | `float` | Overhead multiplier for VM memory | `0.065` |
| `controller.settings.batchMaxDuration` | `string` | Max batching delay | `"10s"` |
| `controller.settings.batchIdleDuration` | `string` | Idle batching delay | `"1s"` |

### Logging

| **Input** | **Type** | **Description** | **Default** |
|----------|----------|------------------|-------------|
| `logLevel` | `string` | Logging level | `"info"` |
| `logOutputPaths` | `list` | Output paths for logs | `["stdout"]` |
| `logErrorOutputPaths` | `list` | Output paths for error logs | `["stderr"]` |

### Controller Deployment

| **Input** | **Type** | **Description** | **Default** |
|----------|----------|------------------|-------------|
| `controller.replicaCount` | `integer` | Number of controller replicas | `2` |
| `controller.image.repository` | `string` | Controller image repository | `"public.ecr.aws/cloudpilotai/gcp/karpenter"` |
| `controller.image.tag` | `string` | Controller image tag | `"v0.0.1"` |
| `controller.resources` | `object` | CPU and memory requests | `{ cpu: 500m, memory: 500Mi }` |
| `controller.metrics.port` | `integer` | Metrics port | `8080` |

### Service Account

| **Input**                    | **Type** | **Description**                                       | **Default** |
|------------------------------|----------|-------------------------------------------------------|-------------|
| `serviceAccount.create`      | `bool` | Create a service account for the controller           | `true` |
| `serviceAccount.name`        | `string` | Name of the service account  | `""` |
| `serviceAccount.annotations` | `map` | Annotations for the service account                   | `{}` |

### Credentials

| **Input**                          | **Type** | **Description**                                                | **Default**                 |
|------------------------------------|----------|----------------------------------------------------------------|-----------------------------|
| `credentials.enabled`              | `bool`   | Mount kubernetes secret containing the GCP service account key | `true`                      |
| `credentials.secretName`           | `string` | Name of the kubernetes secret to mount                         | `karpenter-gcp-credentials` |
| `credentials.secretKey`            | `string` | Secret key name inside the secret                              | `"key.json"`                |

---

## Example `values.yaml`

```yaml
logLevel: info
logOutputPaths:
  - stdout
logErrorOutputPaths:
  - stderr

additionalAnnotations: {}

serviceAccount:
  create: true
  automount: true
  annotations: {}
  name: ""

podAnnotations: {}
podLabels: {}

podDisruptionBudget:
  minAvailable: 1

controller:
  replicaCount: 2
  revisionHistoryLimit: 10
  image:
    tag: "v0.0.1"

  env: []

  resources:
    requests:
      cpu: 500m
      memory: 500Mi

  metrics:
    port: 8080

  settings:
    projectID: "<project-id>"
    region: "<zone>"
    clusterName: "<cluster-name"
    vmMemoryOverheadPercent: 0.065
    batchMaxDuration: 10s
    batchIdleDuration: 1s

credentials:
  enabled: true
  secretName: "karpenter-gcp-credentials"
  secretKey: "key.json"
```

---
## Features

- Dynamic node provisioning on GCP using Karpenter
- Support for custom VM types, capacity types, and zones
- Workload-based autoscaling
- Secure credential handling using Kubernetes Secrets
- Customizable resource limits

---
## Architecture

The karpenter deployment includes:

- Deployment for the Karpenter controller
- Kubernetes ServiceAccount for the controller
- ClusterRoleBinding for controller access to Karpenter CRDs
- ClusterRoles for managing Karpenter and core Kubernetes resources
- PodDisruptionBudget for controller
- Service for exposing metrics
- CRDs: GCENodeClass, NodePool, NodeClaim

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 