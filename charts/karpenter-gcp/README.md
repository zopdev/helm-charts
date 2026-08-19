# Karpenter GCP Helm Chart

This Helm chart deploys Karpenter on a GKE (Google Kubernetes Engine) cluster using GCP-specific provisioning. Karpenter is an open-source Kubernetes node provisioning system built for performance, flexibility, and cost efficiency. This chart provides the necessary components to integrate Karpenter with GCP, allowing dynamic, workload-driven node scaling.

---

## Prerequisites

- Kubernetes v1.26+
- Helm 3.0+
- Required GCP APIs enabled:
    - `compute.googleapis.com`
    - `container.googleapis.com`
- A GCP service account for the controller, granted a **minimal custom IAM role** rather than
  the broad predefined roles. Upstream publishes the role definition:

  ```bash
  export PROJECT_ID=<your-project-id>
  export GSA_NAME=karpenter-gsa

  curl -fsSL https://raw.githubusercontent.com/cloudpilot-ai/karpenter-provider-gcp/main/deploy/iam/karpenter-controller-role.yaml \
      -o karpenter-controller-role.yaml
  gcloud iam roles create karpenter_controller --project=$PROJECT_ID --file=karpenter-controller-role.yaml 2>/dev/null || \
  gcloud iam roles update karpenter_controller --project=$PROJECT_ID --file=karpenter-controller-role.yaml

  gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
      --role="projects/$PROJECT_ID/roles/karpenter_controller"
  ```

  Grant `roles/iam.serviceAccountUser` **scoped to the node service account** the controller
  attaches to VMs, not project-wide:

  ```bash
  export NODE_SA_EMAIL=<your-node-sa>@$PROJECT_ID.iam.gserviceaccount.com
  gcloud iam service-accounts add-iam-policy-binding $NODE_SA_EMAIL \
      --role roles/iam.serviceAccountUser \
      --member "serviceAccount:$GSA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
      --project $PROJECT_ID
  ```
- A Kubernetes secret containing the GCP service account key (JSON), unless you use Workload
  Identity — in which case annotate the chart's service account and set `credentials.enabled=false`.

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

To deploy the Karpenter Helm chart, use the following command:

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
  # Follow the GKE release channel the cluster is enrolled in. Pin instead with
  # `version: "125.19216.104.126"` if you want to control when image updates roll out.
  imageSelectorTerms:
    - family: ContainerOptimizedOS
      channel: cluster
  labels:
    env: dev
  # Required in practice. The CRD does not mark `disks` as required and has no
  # default, but GCE rejects every instance create without it:
  #   Error 400: Invalid value for field 'resource.disks': ''. No disks are specified.
  disks:
    - boot: true
      category: pd-balanced
      sizeGiB: 100
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
        # Machine type prefix only -- "n4-standard" no longer matches.
        - key: "karpenter.k8s.gcp/instance-family"
          operator: In
          values: ["n4", "n2", "e2"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ["us-central1-c", "us-central1-a", "us-central1-f", "us-central1-b"]
```

---

## Upgrading from chart 0.0.3

Chart 0.0.4 moves the controller from Karpenter GCP v0.0.1 to v0.6.0. That spans several
upstream breaking changes, so read this before upgrading a live cluster. Upstream's
[MIGRATION.md](https://github.com/cloudpilot-ai/karpenter-provider-gcp/blob/main/MIGRATION.md)
has the full detail.

**Apply the CRDs by hand first.** Helm installs everything under `crds/` on first install and
never touches it again on upgrade. This release changes all three existing CRDs and adds
NodeOverlay, so apply them yourself before `helm upgrade`:

```bash
helm pull zopdev/karpenter-gcp --untar
kubectl apply -f karpenter-gcp/crds/
```

**Values renamed.** `controller.settings.location` is now `controller.settings.clusterLocation`,
with an optional `controller.settings.nodeLocation` for the exact GKE API location. Nothing
carries over automatically — a stale `location` key is silently ignored and the controller
starts with no location.

**NodePool `instance-family` values.** Requirements must use the machine type prefix, not
family plus shape. `n4-standard` no longer matches anything; use `n4`. Audit every NodePool
before upgrading or Karpenter stops finding instance types.

**GCENodeClass `tags` is now `labels`.** Rename the field on existing node classes.

**`imageSelectorTerms[].alias` is deprecated** in favour of structured `family` with `channel`
or `version`. Existing aliases keep working, but migrate them.

**Instance labels removed.** `karpenter.k8s.gcp/instance-category` and
`karpenter.k8s.gcp/instance-cpu-model` no longer exist. Remove them from NodePool
requirements and workload scheduling constraints.

**Reserved `GCENodeClass.spec.metadata` keys are rejected**, including `kube-env`,
`startup-script`, `cluster-name`, and others GKE bootstrap owns. Audit existing node classes.

**`kubeletConfiguration` fields now take effect.** Fields the CRD previously accepted and
dropped — `systemReserved`, `kubeReserved`, the `eviction*` family, and others — are now
applied. Values already set will change node behaviour on the next provision.

**IAM.** Replace the broad `roles/compute.admin` and `roles/container.admin` bindings with
the minimal custom role in [Prerequisites](#prerequisites), and scope
`roles/iam.serviceAccountUser` to the node service account. The controller also needs
`container.clusters.get` and, if you use `channel:` image terms, `container.clusters.list`.

**Legacy bootstrap pools.** Karpenter no longer creates `karpenter-default`,
`karpenter-ubuntu`, `karpenter-cos-arm64`, or `karpenter-ubuntu-arm64`. It discovers an
existing RUNNING pool instead. Once provisioning works, delete the legacy pools at your pace.

**`disks` is now effectively mandatory on GCENodeClass.** The CRD neither requires it
nor supplies a default, but GCE rejects instance creation without it
(`Error 400: Invalid value for field 'resource.disks': ''`). Add a boot disk to every
node class before upgrading, or provisioning fails silently at the NodeClaim level while
the NodePool still reports Ready.

**Node rotation.** The GCENodeClass hash version bumps, so Karpenter triggers one controlled
rolling replacement of every node it manages after the upgrade.

## Uninstall Helm Chart

To remove the Karpenter Helm chart and associated resources, run:

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
| `controller.settings.clusterLocation` | `string` | Region or zone used for instance type discovery, e.g. `us-central1` | `""` |
| `controller.settings.nodeLocation` | `string` | Exact cluster location for GKE API calls: `us-central1-a` for a zonal cluster, `us-central1` for a regional one. Falls back to `clusterLocation` | `""` |
| `controller.settings.clusterName` | `string` | GKE cluster name | `""` |
| `controller.settings.vmMemoryOverheadPercent` | `float` | Overhead multiplier for VM memory | `0.065` |
| `controller.settings.batchMaxDuration` | `string` | Max batching delay | `"10s"` |
| `controller.settings.batchIdleDuration` | `string` | Idle batching delay | `"1s"` |
| `controller.settings.ignoreDRARequests` | `bool` | Ignore pods' Dynamic Resource Allocation requests while simulating scheduling | `true` |
| `controller.settings.defaultNodePoolTemplateName` | `string` | Pin the GKE node pool read for bootstrap metadata. Empty means automatic discovery | `""` |
| `controller.settings.defaultNodepoolServiceAccount` | `string` | GCP service account email attached to provisioned nodes, overriding the Compute Engine default | `""` |

### Feature Gates

Everything except `spotToSpotConsolidation` is ALPHA upstream and off by default.

| **Input** | **Type** | **Description** | **Default** |
|----------|----------|------------------|-------------|
| `controller.featureGates.spotToSpotConsolidation` | `bool` | Spot replacement consolidation, single and multi-node | `true` |
| `controller.featureGates.nodeOverlay` | `bool` | Let NodeOverlay resources influence scheduling decisions | `false` |
| `controller.featureGates.staticCapacity` | `bool` | A NodePool with `spec.replicas` holds a fixed node count regardless of pod demand | `false` |
| `controller.featureGates.nodeRepair` | `bool` | Replace nodes failing GKE Node Problem Detector health conditions | `false` |
| `controller.featureGates.reservedCapacity` | `bool` | Scheduling onto reserved GCP capacity. The provider does not implement GCE reservations yet | `false` |
| `controller.featureGates.capacityBuffer` | `bool` | CapacityBuffer pre-provisioning. The CRD is not shipped here — GKE provides it from `1.35.2-gke.1842000`, and enabling this without it fails at render time | `false` |
| `controller.disableControllerWarmup` | `bool` | Whether watches/informers start before leader election is won. `false` speeds up leader failover | `true` |

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
| `controller.image.tag` | `string` | Controller image tag | `"v0.6.0"` |
| `controller.priorityClassName` | `string` | Priority class for the controller pods. `gmp-critical` is created by Google Managed Prometheus. Set to `""` on clusters without it — naming a class that does not exist blocks pod creation entirely | `"gmp-critical"` |
| `controller.image.repository` | `string` | Controller image repository | `"public.ecr.aws/cloudpilotai/gcp/karpenter"` |
| `controller.image.pullPolicy` | `string` | Image pull policy | `"IfNotPresent"` |
| `imagePullSecrets` | `list` | Existing pull secrets, for a private registry mirror | `[]` |
| `controller.strategy` | `object` | Deployment update strategy | `{ rollingUpdate: { maxUnavailable: 1 } }` |
| `controller.terminationGracePeriodSeconds` | `integer` | Grace period for controller shutdown | `30` |
| `controller.healthProbe.port` | `integer` | Port for the health and readiness probes. Upstream defaults to `8081`; this chart keeps `8001` so the port does not move on upgrade | `8001` |
| `controller.affinity` | `object` | Overrides the default pod anti-affinity, which spreads replicas one per node using the chart's selector labels. Leave empty to keep that default | `{}` |
| `controller.tolerations` | `list` | Tolerations for the controller pods | `[]` |
| `controller.resources` | `object` | CPU and memory requests | `{ cpu: 500m, memory: 500Mi }` |
| `controller.metrics.port` | `integer` | Metrics port | `8080` |
| `podSecurityContext` | `object` | Security context applied at the pod level | `{ runAsNonRoot: true, seccompProfile: { type: RuntimeDefault } }` |
| `securityContext` | `object` | Security context applied to the karpenter container | see `values.yaml` |
| `podDisruptionBudget.minAvailable` | `integer` | Minimum available pods, used only when `maxUnavailable` is null | `1` |
| `podDisruptionBudget.maxUnavailable` | `integer` | Maximum unavailable pods. Takes precedence over `minAvailable` when set | `null` |

### Metrics

`serviceMonitor` renders a Prometheus Operator `ServiceMonitor`, and only when the
`monitoring.coreos.com/v1` API is present on the cluster.

| **Input** | **Type** | **Description** | **Default** |
|----------|----------|------------------|-------------|
| `serviceMonitor.enabled` | `bool` | Create a ServiceMonitor for the metrics endpoint | `false` |
| `serviceMonitor.additionalLabels` | `map` | Extra labels on the ServiceMonitor | `{}` |
| `serviceMonitor.interval` | `string` | Scrape interval. Empty uses the operator default | `""` |
| `serviceMonitor.scrapeTimeout` | `string` | Scrape timeout. Empty uses the operator default | `""` |
| `serviceMonitor.relabelings` | `list` | Relabelings for the metrics endpoint | `[]` |
| `serviceMonitor.metricRelabelings` | `list` | Metric relabelings for the metrics endpoint | `[]` |
| `serviceMonitor.sampleLimit` | `integer` | Per-scrape cap on accepted samples. `null` means no limit | `null` |

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
  maxUnavailable: null

serviceMonitor:
  enabled: false

controller:
  replicaCount: 2
  revisionHistoryLimit: 10
  image:
    tag: "v0.6.0"

  env: []

  resources:
    requests:
      cpu: 500m
      memory: 500Mi

  metrics:
    port: 8080

  featureGates:
    spotToSpotConsolidation: true

  settings:
    projectID: "<project-id>"
    clusterLocation: "<region-or-zone>"
    clusterName: "<cluster-name>"
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
- Service for exposing metrics, and an optional ServiceMonitor for the Prometheus Operator
- CRDs: GCENodeClass, NodePool, NodeClaim, NodeOverlay

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 