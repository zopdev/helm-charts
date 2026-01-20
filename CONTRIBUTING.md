# Contributing to Helm Charts

## Welcome Contributors!

We appreciate your interest in contributing to our Helm charts repository. Your contributions help improve these charts and benefit the entire community. This document provides guidelines and best practices to ensure that all contributions are consistent, high quality, and integrate seamlessly with the zop.dev ecosystem.

---

## 1. How to Contribute

### Getting Started
- **Fork** the repository.
- **Clone** your forked repository locally.
- **Create a new branch** for your contribution (e.g., `feature/`, `fix/`, or `docs/`).
- **Make your changes** and test them thoroughly.
- **Submit a pull request (PR)** with a clear title and detailed description.

---

## 2. Branching Strategy

We use a simplified Git workflow:
- The `main` branch is our primary branch for stable releases.
- Create feature branches from `main`.
- **Branch Naming Convention:**
  - `feature/`: For new features.
  - `fix/`: For bug fixes.
  - `docs/`: For documentation updates.

---

## 3. Code and Chart Standards

### Helm Chart Standards
- **Official Best Practices:** Follow the official Helm best practices.
- **Linting:** Ensure all charts pass `helm lint` without errors.
- **Values File:**
  - Include a comprehensive `values.yaml` file with sensible defaults.
  - If any field is intended to be user-configurable, mark it in the accompanying `values.schema.json` with `"mutable": true`.
  - If a field is not meant to be edited, mark it in the accompanying `values.schema.json` with `"editDisabled": true`.
- **Comments & Documentation:**  
  - Add comments in YAML files to explain complex configurations.
  - Document any overrideable values in the chart’s README.
- **YAML Formatting:**
  - Use 2-space indentation; do not use hard tabs.
  - Keep lines under 80 characters where possible.
  - Use snake_case for variable names.


---

## 4. Chart Configuration Guidelines

### Metadata Guidelines
- **Required Annotation:** Every chart must include the following metadata annotation:
  ```yaml
  annotations:
    type: datasource  # or "application"
  ```
This annotation ensures that the chart is automatically reflected in the zop.dev Applications and Datasources section.


### For Application Charts (using the **service** chart)
- **Bundled Configurations:**  
  The service chart bundles configurations for:
  - Horizontal Pod Autoscaling (HPA)
  - Deployments
  - Alerts and Grafana configurations
  - Ingress settings
  - Pod-distribution budgets
  - Persistent Volume Claims (PVCs)
  - Service Monitors (refer to the `service-monitor.yaml` template)
  - Alerts (refer to the `alerts.yaml` template)
- **Credential Management:**  
  Application-specific credentials (ID and password) are automatically managed via templated files (e.g., `<release-name>-login.yaml`). Users do not need to provide these values manually.

### For Datasource Charts

* Datasource charts should require **minimal configuration**.
* Only essential inputs should be exposed to the user.

---

## 5. Contributing a New Chart

If you are contributing a **new chart** to this repository, follow the steps below to ensure consistency and successful deployment.

---

### Step 1: Chart Structure

Create a new folder for your chart inside the `charts/` directory and follow the structure used in existing charts.

Your chart directory **must include**:

```
charts/
└── <chart_name>/
    ├── Chart.yaml
    ├── values.yaml
    ├── values.schema.json
    └── templates/
```

**File descriptions:**

* `Chart.yaml` – Metadata such as name, version, description, and annotations
* `values.yaml` – Default configuration values
* `values.schema.json` – JSON schema for validating configuration fields
* `templates/` – Kubernetes manifest templates written using Helm syntax

Refer to existing charts such as **mysql** or **redis** to maintain consistency in structure, naming, and formatting.

#### Required Annotation in `Chart.yaml`

For **application charts**:

```yaml
annotations:
  type: application
```

For **datasource charts**:

```yaml
annotations:
  type: datasource
```

---

### Step 2: Test the Chart Locally

Install the chart in a local or test Kubernetes cluster:

```bash
helm install <release-name> ./charts/<chart_name>
```

After installation, verify:

* All Kubernetes resources are created successfully
* The application or datasource functions as expected

---

### Step 3: Lint the Chart

Run Helm linting to validate syntax and best practices:

```bash
helm lint ./charts/<chart_name>
```

Fix all warnings and errors before proceeding.

---

### Step 4: Package the Chart

Once verified, package the chart:

```bash
helm package ./charts/<chart_name> --version "<version>"
```

This generates a `.tgz` archive for the chart.

---

### Step 5: Move the Package to `docs/`

Move the generated package to the `docs/` directory:

```bash
mv <chart_name>-<version>.tgz docs/
```

---

### Step 6: Update the Helm Repository Index

From inside the `docs/` directory, update the Helm repository index:

```bash
cd docs
helm repo index . --url https://helm.zop.dev
```

This ensures the new chart version becomes available in the Helm repository once changes are merged into `main`.

---

## 6. Testing Requirements

Before submitting a pull request:

* Run `helm lint` successfully
* Perform a `--dry-run` installation:

  ```bash
  helm install --dry-run --debug mychart ./charts/<chart_name>
  ```
* Validate default configurations
* Ensure clean uninstallation without errors

---

## 7. Submitting Changes

### Pull Request Guidelines
- **Title & Description:**  
  Use a clear and descriptive title. Provide a detailed description of your changes, including:
  - The problem your changes address.
  - Any new features or bug fixes.
  - References to any related GitHub issues.
- **Checklist:**  
  Ensure your PR meets the following:
  - [ ] Code and chart conform to Helm best practices.
  - [ ] `helm lint` passes without errors.
  - [ ] All changes are properly documented.
  - [ ] Tests have been added/updated as necessary.

### Pull Request Template Example
```markdown
## Description
[Provide a detailed description of your changes]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Chart configuration update

## Checklist
- [ ] I have performed a self-review of my code
- [ ] I have added tests proving my fix/feature
- [ ] My changes generate no new warnings
- [ ] I have updated documentation accordingly
```

---

## 8. Issue Tracking

### Reporting Issues
- **Use GitHub Issues:**  
  Open a new issue for any bugs or feature requests.
- **Provide Details:**  
  Include a detailed description, steps to reproduce, and expected versus actual behavior.
- **Labels:**  
  Use appropriate labels to help us prioritize and address the issues.

---

## 9. Important Contribution Policies

- **Timely Reviews:**  
  No PR should remain open for more than 2 weeks without feedback.
- **Avoid WIP or Draft PRs:**  
  Submit PRs only when your work is ready for review.
- **Respectful Communication:**  
  Follow our Code of Conduct. Provide constructive feedback and collaborate positively.

---

## 10. Getting Help

If you need assistance:
- **Consult Documentation:** Review the existing documentation in the repository.
- **Open an Issue:** If you have questions, open an issue for discussion.
- **Community Discussions:** Join our community channels for real-time help and support.

---

## Thank You!

Your contributions are vital to the success and growth of our Helm charts repository. Thank you for taking the time to improve our charts and for being part of the zop.dev community!
```