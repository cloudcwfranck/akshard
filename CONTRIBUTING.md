# Contributing to AKS Bootstrap Kit

Thank you for your interest in contributing! This document provides guidelines for contributing to the AKS Bootstrap Kit.

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Description**: Clear description of the bug
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**: AKS version, Kubernetes version, tool versions
- **Logs**: Relevant error logs or output

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use Case**: Why this enhancement would be useful
- **Proposed Solution**: How you envision the enhancement working
- **Alternatives**: Alternative solutions you've considered
- **Impact**: Potential impact on existing functionality

### Pull Requests

1. **Fork the Repository**
   ```bash
   git clone https://github.com/<your-fork>/akshard.git
   cd akshard
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow coding standards
   - Write/update tests
   - Update documentation
   - Add compliance mappings if applicable

4. **Test Changes**
   ```bash
   # Validate Terraform
   make validate

   # Test Kyverno policies
   make test-policies

   # Run compliance checks
   make compliance-check
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `refactor:` Code refactoring
   - `test:` Adding tests
   - `chore:` Maintenance tasks

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

   Create a Pull Request with:
   - Clear title and description
   - Reference to related issues
   - Screenshots (if applicable)
   - Compliance impact assessment

## Development Guidelines

### Terraform Modules

- Use meaningful variable names
- Include validation rules
- Document all variables and outputs
- Follow HashiCorp best practices
- Add compliance annotations

Example:
```hcl
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.cluster_name))
    error_message = "Cluster name must be 3-63 characters."
  }
}
```

### Kyverno Policies

- Include compliance framework annotations
- Provide clear validation messages
- Test with sample resources
- Document exceptions

Example:
```yaml
metadata:
  annotations:
    policies.kyverno.io/title: "Policy Title"
    policies.kyverno.io/category: "Category"
    policies.kyverno.io/severity: "high"
    compliance.framework/cis: "5.2.1"
    compliance.framework/dod-stig: "V-242381"
```

### Helm Charts

- Use Chainguard distroless images
- Set resource limits/requests
- Enable Pod Security Standards
- Include security contexts
- Add health checks

### Documentation

- Update README for major changes
- Add inline code comments
- Update compliance mappings
- Include examples
- Keep deployment guide current

## Testing Requirements

### Terraform

```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Security scan
tfsec .

# Linting
tflint
```

### Kyverno Policies

```bash
# Validate policies
kyverno validate policies/kyverno/**/*.yaml

# Test against sample resources
kyverno apply policies/kyverno/pod-security/ --resource test-pod.yaml
```

### Integration Tests

```bash
# Deploy to test cluster
make apply

# Run validation
make compliance-check

# Cleanup
make destroy
```

## Security Considerations

### For All Contributions

1. **No Secrets**: Never commit secrets, keys, or credentials
2. **Dependency Security**: Update dependencies, check for CVEs
3. **Image Security**: Use signed images, scan for vulnerabilities
4. **Policy Impact**: Assess impact on security policies
5. **Compliance**: Maintain compliance with CIS, STIG, NIST

### Security Changes

For changes affecting security:

1. Get security team review
2. Update threat model
3. Update compliance documentation
4. Test security controls
5. Document security implications

## Compliance Requirements

All contributions must maintain compliance with:

- CIS Kubernetes Benchmark v1.8
- DoD Kubernetes STIG v1r12
- NIST SP 800-190
- NSA Kubernetes Hardening Guide
- FedRAMP controls

Document compliance impact in PR description.

## Review Process

1. **Automated Checks**
   - Terraform validation
   - Policy validation
   - Security scanning
   - Linting

2. **Code Review**
   - Minimum 1 approval required
   - Security team review for security changes
   - Platform team review for infrastructure changes

3. **Testing**
   - All tests must pass
   - Manual testing for major changes
   - Compliance validation

4. **Documentation Review**
   - Documentation updated
   - Examples provided
   - Compliance mappings current

## Release Process

1. Version bump (semantic versioning)
2. Update CHANGELOG.md
3. Tag release
4. Generate release notes
5. Update documentation

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Issues**: Create a GitHub Issue
- **Security**: See SECURITY.md
- **Chat**: Join our Slack channel (link)

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Annual contributor spotlight

Thank you for contributing to AKS Bootstrap Kit! 🎉
