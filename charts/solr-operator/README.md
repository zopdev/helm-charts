# Solr Operator Helm Chart

This Helm chart deploys the Solr Operator on Kubernetes, which manages SolrCloud clusters and standalone Solr instances. The Solr Operator simplifies the deployment and management of Solr in Kubernetes environments.

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster

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

To deploy the Solr Operator Helm chart, use the following command:

```bash
helm install [RELEASE_NAME] zopdev/solr-operator
```

Replace `[RELEASE_NAME]` with your desired release name. Example:

```bash
helm install my-solr-operator zopdev/solr-operator
```

You can override default values during installation by providing a `values.yaml` file.

Refer to the [Helm Install Documentation](https://helm.sh/docs/helm/helm_install/) for further details.

---

## Uninstall Helm Chart

To remove the Solr Operator Helm chart and associated resources, run:

```bash
helm uninstall [RELEASE_NAME]
```

Example:

```bash
helm uninstall my-solr-operator
```

Check the [Helm Uninstall Documentation](https://helm.sh/docs/helm/helm_uninstall/) for more information.

---

## Configuration

The Solr Operator Helm chart includes several configuration options to tailor the deployment to your needs. Below is a summary of the key configurations:

| **Input**                    | **Type**  | **Description**                                                                                | **Default**           |
|------------------------------|-----------|------------------------------------------------------------------------------------------------|-----------------------|
| `version`                    | `string`  | Version of the Solr Operator to deploy.                                                       | `"v0.9.0"`           |
| `zookeeper-operator.install` | `boolean` | Whether to install the Zookeeper Operator as a dependency.                                     | `true`               |
| `zookeeper-operator.crd.create` | `boolean` | Whether to create Zookeeper CRDs.                                                          | `true`               |
| `resources.requests.cpu`     | `string`  | Minimum CPU resources required by the Solr Operator.                                          | `"100m"`             |
| `resources.requests.memory`  | `string`  | Minimum memory resources required by the Solr Operator.                                       | `"128Mi"`            |
| `resources.limits.cpu`       | `string`  | Maximum CPU resources the Solr Operator can use.                                              | `"200m"`             |
| `resources.limits.memory`    | `string`  | Maximum memory resources the Solr Operator can use.                                           | `"256Mi"`            |
| `mTLS.clientCertSecret`     | `string`  | Name of the secret containing client certificates for mTLS.                                    | `""`                 |
| `mTLS.caCertSecret`         | `string`  | Name of the secret containing CA certificates for mTLS.                                        | `""`                 |
| `mTLS.caCertSecretKey`      | `string`  | Key in the CA certificate secret containing the CA certificate.                               | `"ca-cert.pem"`      |
| `mTLS.insecureSkipVerify`   | `boolean` | Whether to skip TLS verification.                                                             | `true`               |
| `mTLS.watchForUpdates`      | `boolean` | Whether to watch for certificate updates.                                                      | `true`               |
| `metrics.enable`            | `boolean` | Whether to enable Prometheus metrics.                                                         | `true`               |

---

## Example `values.yaml`

```yaml
version: "v0.9.0"

zookeeper-operator:
  install: true
  crd:
    create: true

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "200m"
    memory: "256Mi"

mTLS:
  clientCertSecret: "solr-client-cert"
  caCertSecret: "solr-ca-cert"
  caCertSecretKey: ca-cert.pem
  insecureSkipVerify: false
  watchForUpdates: true

metrics:
  enable: true
```

---

## Features

- Deploys the Solr Operator for managing SolrCloud clusters
- Optional Zookeeper Operator integration
- Configurable resource limits and requests
- mTLS support for secure communication
- Prometheus metrics integration
- Leader election for high availability
- Role-based access control (RBAC)

---

## Architecture

The Solr Operator deployment includes:
- Deployment for the operator pod
- ServiceAccount for operator permissions
- Role and RoleBinding for RBAC
- Leader election configuration
- Metrics service for Prometheus integration
- Optional Zookeeper Operator deployment

---

## Contributing

We welcome contributions to improve this Helm chart. Please refer to the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for contribution guidelines.

---

## Code of Conduct

To maintain a healthy and collaborative community, please adhere to our [Code of Conduct](../../CODE_OF_CONDUCT.md).

---

## License

This project is licensed under the [LICENSE](../../LICENSE). Please review it for terms of use.
