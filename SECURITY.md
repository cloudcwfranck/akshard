# Security Policy

## Reporting a Vulnerability

We take security seriously in the AKS Bootstrap Kit. If you discover a security vulnerability, please report it responsibly.

### How to Report

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, please report security issues via:

1. **GitHub Security Advisories**: [Create a private security advisory](https://github.com/<your-org>/<your-repo>/security/advisories/new)
2. **Email**: security@example.com (PGP key available on request)

### What to Include

Please provide:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Any suggested fixes (optional)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Based on severity
  - Critical: 7-14 days
  - High: 14-30 days
  - Medium: 30-60 days
  - Low: 60-90 days

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Features

### Supply Chain Security

This project implements multiple layers of supply chain security:

1. **Image Signing**
   - All container images signed with Cosign (keyless via Fulcio/Rekor)
   - Signatures verified at admission time via Kyverno

2. **SLSA Provenance**
   - SLSA Level 3 build provenance
   - Immutable build logs in Rekor transparency log

3. **SBOM Generation**
   - Software Bill of Materials (SBOM) in CycloneDX and SPDX formats
   - Automated vulnerability scanning with Trivy and Grype

4. **Approved Registries**
   - Only images from approved registries allowed:
     - cgr.dev (Chainguard)
     - ghcr.io/chainguard-images
     - *.azurecr.io (Azure Container Registry)
     - mcr.microsoft.com (Microsoft)
     - registry.k8s.io (Kubernetes official)

### Runtime Security

1. **Pod Security Standards**
   - Restricted profile enforced cluster-wide
   - No privileged containers
   - Drop all capabilities
   - Run as non-root user (UID >= 1000)
   - Read-only root filesystem
   - Seccomp and AppArmor profiles required

2. **Network Policies**
   - Default deny-all policy
   - Explicit allow rules only
   - Zero-trust microsegmentation

3. **Admission Control**
   - Kyverno policy engine
   - OPA Gatekeeper constraints
   - Azure Policy integration

4. **Runtime Threat Detection**
   - Microsoft Defender for Containers
   - Falco behavioral monitoring
   - Real-time alerting

### Infrastructure Security

1. **Private AKS Cluster**
   - No public API endpoint
   - VNet integration
   - Authorized IP ranges (optional)

2. **Identity and Access**
   - Azure AD integration (no local accounts)
   - Workload Identity (OIDC, no static credentials)
   - RBAC with least privilege

3. **Secrets Management**
   - Azure Key Vault CSI Driver
   - No secrets in environment variables
   - Automatic rotation

4. **Audit Logging**
   - All control plane logs to Log Analytics
   - 90-day retention minimum
   - Immutable audit trail

## Compliance

This implementation meets or exceeds:

- **CIS Kubernetes Benchmark v1.8** (Level 1 + Level 2)
- **DoD Kubernetes STIG v1r12**
- **NIST SP 800-190** (Container Security)
- **NSA Kubernetes Hardening Guide**
- **FedRAMP Moderate/High** controls
- **Executive Order 14028** (SBOM requirements)

## Security Best Practices

### For Users

1. **Keep Updated**
   - Regularly update to latest versions
   - Subscribe to security advisories
   - Monitor CVE databases

2. **Configuration**
   - Never disable security policies
   - Use private registries
   - Enable audit logging
   - Implement network policies

3. **Monitoring**
   - Review policy reports regularly
   - Monitor runtime alerts
   - Investigate anomalies

4. **Secrets**
   - Never commit secrets to Git
   - Use Azure Key Vault
   - Rotate credentials regularly
   - Enable secret scanning

### For Contributors

1. **Code Review**
   - All changes require review
   - Security team review for security-related changes
   - Automated security scanning in CI/CD

2. **Dependencies**
   - Keep dependencies updated
   - Use Dependabot alerts
   - Verify dependency signatures
   - Generate SBOMs

3. **Testing**
   - Write security tests
   - Test policy enforcement
   - Validate RBAC configurations
   - Perform penetration testing

## Known Limitations

### Azure AKS Managed Service Constraints

1. **Control Plane Access**: Limited access to control plane components (managed by Microsoft)
2. **Node OS**: Limited ability to modify node OS beyond supported configurations
3. **Network Plugins**: Limited to Azure CNI or kubenet

### Policy Limitations

1. **Existing Workloads**: Policies apply to new resources; existing resources require migration
2. **System Namespaces**: Some policies exclude system namespaces for cluster stability
3. **Custom Resources**: Policy coverage for CRDs requires explicit policy creation

## Security Contacts

- **Security Team**: security@example.com
- **Platform Team**: platform@example.com
- **Emergency**: Use GitHub Security Advisory for urgent issues

## Additional Resources

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [DoD Kubernetes STIG](https://public.cyber.mil/stigs/)
- [NIST 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final)
- [NSA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
- [SLSA Framework](https://slsa.dev/)
- [Sigstore Documentation](https://docs.sigstore.dev/)

---

**Last Updated**: 2024-01-15
**Version**: 1.0.0
