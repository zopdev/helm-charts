# Zookeeper Operator Helm Chart

This Helm chart deploys the Zookeeper Operator, a Kubernetes operator that manages Apache Zookeeper clusters. The operator automates the deployment, scaling, and management of Zookeeper clusters in a Kubernetes environment.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Cluster admin privileges for CRD installation

---

## Add Helm Repository

Add the Helm repository by running:

```bash
helm repo add zopdev https://helm.zop.dev
helm repo update
```

For more details, see the [Helm Repository Documentation](https://helm.sh/docs/helm/helm_repo/).

---

## Install Helm Chart

To deploy the Zookeeper Operator Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/zookeeper-operator
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-zookeeper-operator zopdev/zookeeper-operator
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the Zookeeper Operator Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-zookeeper-operator
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The Zookeeper Operator Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

### CRD Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `crd.create`                 | `boolean` | Whether to create the Zookeeper CRD.                                                          | `true`               |

### Resource Configuration

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `resources.requests.cpu`     | `string`  | CPU resource requests for the operator.                                                        | `"100m"`             |
| `resources.requests.memory`  | `string`  | Memory resource requests for the operator.                                                     | `"128Mi"`            |
| `resources.limits.cpu`       | `string`  | CPU resource limits for the operator.                                                          | `"200m"`             |
| `resources.limits.memory`    | `string`  | Memory resource limits for the operator.                                                       | `"256Mi"`            |

---

## Example `values.yaml`

```yaml
crd:
  create: true

resources: 
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "200m"
    memory: "256Mi"
```

---

## Features

- Automated Zookeeper cluster management
- Custom Resource Definition (CRD) for Zookeeper clusters
- Resource management for the operator
- Automatic CRD installation
- Kubernetes-native deployment
- Operator lifecycle management
- Resource limits and requests configuration

---

## Architecture

The Zookeeper Operator deployment includes:
- Operator pod for managing Zookeeper clusters
- Custom Resource Definition (CRD) for Zookeeper resources
- Resource management configuration
- Kubernetes controller for Zookeeper operations
- Event handling and reconciliation
- Health monitoring
- Resource management

---

## Security Features

- Resource limits and requests
- RBAC configuration
- Pod security context
- Network policies
- Operator security
- CRD security

---

## Usage

After installing the Zookeeper Operator, you can create Zookeeper clusters using the custom resource. Here's an example:

```yaml
crd:
  create: true

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "200m"
    memory: "256Mi"
```

The operator will automatically:
1. Create the necessary Kubernetes resources
2. Manage the Zookeeper cluster lifecycle
3. Handle scaling operations
4. Monitor cluster health
5. Perform automated maintenance

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use. 