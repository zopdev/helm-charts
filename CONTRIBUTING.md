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
- **Minimal Configuration:**  
  Datasource charts are optimized to require only the essential inputs, minimizing the configuration overhead for users.

---

## 5. Testing Requirements

### Before Submitting a Pull Request
- **Lint Your Chart:**  
  Run `helm lint` on your chart to catch any issues.
- **Dry Run Installation:**  
  Test chart installation with:
  ```bash
  helm install --dry-run --debug mychart ./path/to/your/chart
  ```
- **Functionality Testing:**  
  Ensure that all default configurations work as expected.
- **Uninstallation Testing:**  
  Verify that the chart can be uninstalled cleanly without errors.

---

## 6. Submitting Changes

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

## 7. Issue Tracking

### Reporting Issues
- **Use GitHub Issues:**  
  Open a new issue for any bugs or feature requests.
- **Provide Details:**  
  Include a detailed description, steps to reproduce, and expected versus actual behavior.
- **Labels:**  
  Use appropriate labels to help us prioritize and address the issues.

---

## 8. Important Contribution Policies

- **Timely Reviews:**  
  No PR should remain open for more than 2 weeks without feedback.
- **Avoid WIP or Draft PRs:**  
  Submit PRs only when your work is ready for review.
- **Respectful Communication:**  
  Follow our Code of Conduct. Provide constructive feedback and collaborate positively.

---

## 9. Getting Help

If you need assistance:
- **Consult Documentation:** Review the existing documentation in the repository.
- **Open an Issue:** If you have questions, open an issue for discussion.
- **Community Discussions:** Join our community channels for real-time help and support.

---

## Thank You!

Your contributions are vital to the success and growth of our Helm charts repository. Thank you for taking the time to improve our charts and for being part of the zop.dev community!
```