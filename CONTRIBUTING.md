# Contributing to Helm Charts

## Welcome Contributors! 

We appreciate your interest in contributing to our Helm charts repository. This document provides guidelines to help you contribute effectively and efficiently.

## 1. How to Contribute

### Getting Started
- Fork the repository
- Clone your forked repository
- Create a new branch for your contribution
- Make your changes
- Submit a pull request

## 2. Branching Strategy

We use a simplified Git workflow:
- `main` branch is the primary branch for stable releases
- Create feature branches from `main`
- Branch naming convention:
  - `feature/`: For new features
  - `fix/`: For bug fixes
  - `docs/`: For documentation updates

## 3. Code Standards

### Helm Chart Standards
- Use official Helm best practices
- Ensure all charts are linted using `helm lint`
- Include comprehensive `values.yaml` with sensible defaults
- Add comments explaining complex configurations
- Use consistent indentation (2 spaces)

### YAML Formatting
- Use 2-space indentation
- No hard tabs
- Keep lines under 80 characters where possible
- Use snake_case for variable names

## 4. Testing Requirements

### Before Submitting a Pull Request
- Run `helm lint` on your chart
- Ensure all default configurations work
- Test chart installation and uninstallation
- Verify all required values are properly documented

### Testing Commands
```bash
# Lint your chart
helm lint ./path/to/your/chart

# Dry run installation
helm install --dry-run --debug mychart ./path/to/your/chart
```

## 5. Submitting Changes

### Pull Request Guidelines
- Title should be clear and descriptive
- Include a detailed description of changes
- Reference any related issues
- Attach screenshots if applicable for visual changes

### Pull Request Template
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

## 6. Issue Tracking

### Reporting Issues
- Use GitHub Issues
- Choose appropriate labels
- Provide:
  - Detailed description
  - Steps to reproduce
  - Expected vs. actual behavior
  - Helm and Kubernetes versions

## 7. Important Contribution Policies

### Pull Request Policies
- **No PR should remain open for more than 2 weeks**
- **Do not create WIP (Work in Progress) or draft PRs**
- All PRs must have at least one approving review

## 8. Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Collaborate and help each other

## 9. Getting Help

If you need assistance:
- Check existing documentation
- Open an issue for questions
- Join our community discussions

## Thank You! 

Your contributions help improve these Helm charts and benefit the entire community.