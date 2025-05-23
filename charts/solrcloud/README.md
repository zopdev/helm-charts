# SolrCloud Helm Chart

This Helm chart deploys Apache SolrCloud on Kubernetes, providing a highly available, distributed search platform. SolrCloud is built on Apache Solr and offers features like distributed indexing, automatic sharding, and fault tolerance.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Solr Operator installed in the cluster (automatically installed as a dependency)

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

To deploy the SolrCloud Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/solrcloud
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-solrcloud zopdev/solrcloud
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the SolrCloud Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-solrcloud
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The SolrCloud Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

| **Input**                                 | **Type** | **Description**                                      | **Default** |
|-------------------------------------------|----------|------------------------------------------------------|-------------|
| `version`                                 | `string` | Version of Solr to deploy.                           | `"8.11"`    |
| `resources.requests.cpu`                  | `string` | Minimum CPU resources required by each Solr pod.     | `"500m"`    |
| `resources.requests.memory`               | `string` | Minimum memory resources required by each Solr pod.  | `"500Mi"`   |
| `resources.limits.cpu`                    | `string` | Maximum CPU resources each Solr pod can use.         | `"1000m"`   |
| `resources.limits.memory`                 | `string` | Maximum memory resources each Solr pod can use.      | `"1500Mi"`  |
| `diskSize`                                | `string` | Size of the persistent volume for Solr data storage. | `"20Gi"`    |
| `solr-operator.version`                   | `string` | Version of the Solr Operator to deploy.              | `"v0.9.0"`  |
| `solr-operator.resources.requests.cpu`    | `string` | Minimum CPU resources for the Solr Operator.         | `"100m"`    |
| `solr-operator.resources.requests.memory` | `string` | Minimum memory resources for the Solr Operator.      | `"128Mi"`   |
| `solr-operator.resources.limits.cpu`      | `string` | Maximum CPU resources for the Solr Operator.         | `"200m"`    |
| `solr-operator.resources.limits.memory`   | `string` | Maximum memory resources for the Solr Operator.      | `"256Mi"`   |

---

## Example `values.yaml`

```yaml
version: "8.11"

resources:
  requests:
    cpu: "500m"
    memory: "500Mi"
  limits:
    cpu: "1000m"
    memory: "1500Mi"

diskSize: "20Gi"

solr-operator:
  version: "v0.9.0"
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

- Deploys a fully configured SolrCloud cluster
- Automatic Zookeeper ensemble management
- Persistent storage for Solr data
- Basic authentication enabled by default
- Pod disruption budget for high availability
- Automatic scaling with pod vacate/populate
- Managed update strategy
- Customizable resource limits and requests
- Automatic Solr Operator deployment

---

## Architecture

The SolrCloud deployment includes:
- SolrCloud cluster with configurable resources
- Zookeeper ensemble (3 replicas by default)
- Persistent volume claims for data storage
- Pod disruption budget for high availability
- Solr Operator for cluster management
- Basic authentication security
- Configurable update and scaling strategies

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.
