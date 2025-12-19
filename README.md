# AKS Bootstrap Kit - Enterprise Supply Chain Security

A comprehensive, FedRAMP/NIST-compliant Azure Kubernetes Service (AKS) bootstrap platform with integrated supply chain security.

## 🎯 Overview

This bootstrap kit provides a production-ready, security-hardened AKS deployment framework that implements:

- **Infrastructure Security**: CIS Kubernetes Benchmark, DoD STIG, NIST 800-190
- **Supply Chain Security**: Sigstore, SLSA provenance, SBOM generation
- **Runtime Security**: Falco, Pod Security Standards, Network Policies
- **Policy Enforcement**: Kyverno, OPA Gatekeeper
- **GitOps**: Flux v2 with automated security validation
- **Observability**: Prometheus, Grafana, Loki, Tempo

## 🏗️ Architecture

### Infrastructure Layer
- **AKS Cluster**: Private, Azure CNI Overlay, Workload Identity
- **Azure Services**: Key Vault CSI, Defender for Containers, Azure Policy
- **Cloud Support**: Azure Commercial + Azure Government

### Platform Services (Chainguard Distroless Images)
- Ingress: NGINX Ingress Controller
- Certificates: cert-manager
- Secrets: External Secrets Operator
- Policy: Kyverno + OPA Gatekeeper
- Observability: Prometheus Stack, Loki, Tempo
- Runtime Security: Falco
- Image Scanning: Trivy Operator

### Security Controls
- Pod Security Standards (restricted profile)
- Zero-trust network policies
- Keyless image signing (Cosign + Fulcio)
- SLSA Level 3 provenance
- Continuous vulnerability scanning

## 📁 Project Structure

```
.
├── terraform/              # Infrastructure as Code
│   ├── modules/
│   │   ├── aks-cluster/   # Core AKS cluster module
│   │   ├── networking/    # VNet, subnets, NSGs
│   │   ├── identity/      # Workload Identity, RBAC
│   │   ├── monitoring/    # Log Analytics, Defender
│   │   └── governance/    # Azure Policy, compliance
│   ├── environments/
│   │   ├── commercial/    # Azure Commercial deployments
│   │   └── government/    # Azure Government deployments
│   └── examples/          # Reference deployments
│
├── helm-charts/           # Platform service Helm charts
│   ├── ingress-nginx/
│   ├── cert-manager/
│   ├── external-secrets/
│   ├── kyverno/
│   ├── gatekeeper/
│   ├── falco/
│   ├── trivy-operator/
│   └── observability/
│
├── gitops/               # Flux v2 GitOps manifests
│   ├── clusters/
│   ├── infrastructure/
│   └── applications/
│
├── policies/             # Policy-as-Code
│   ├── kyverno/
│   │   ├── pod-security/
│   │   ├── supply-chain/
│   │   └── compliance/
│   └── gatekeeper/
│       ├── templates/
│       └── constraints/
│
├── ci/                   # CI/CD pipelines
│   ├── github-actions/
│   ├── azure-pipelines/
│   └── gitlab-ci/
│
├── docs/                 # Documentation
│   ├── compliance/       # CIS, STIG, NIST mappings
│   ├── architecture/
│   ├── runbooks/
│   └── security/
│
└── scripts/              # Automation scripts
    ├── bootstrap/
    ├── security/
    └── validation/
```

## 🚀 Quick Start

### Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI (`az` >= 2.50.0)
- Terraform >= 1.6.0
- kubectl >= 1.28.0
- Helm >= 3.13.0
- Flux CLI >= 2.2.0
- Cosign >= 2.2.0

### Deploy AKS Cluster

```bash
# 1. Initialize Terraform
cd terraform/environments/commercial/dev
terraform init

# 2. Review and apply
terraform plan -out=tfplan
terraform apply tfplan

# 3. Get kubeconfig
az aks get-credentials --resource-group <rg-name> --name <cluster-name>

# 4. Bootstrap Flux GitOps
flux bootstrap github \
  --owner=<your-org> \
  --repository=<your-repo> \
  --branch=main \
  --path=./gitops/clusters/dev
```

## 🔒 Security Features

### Supply Chain Security
- **Image Signing**: Keyless signing with Cosign (Fulcio/Rekor)
- **Provenance**: SLSA Level 3 attestations
- **SBOM**: CycloneDX and SPDX format generation
- **Scanning**: Trivy and Grype integration
- **Base Images**: Chainguard distroless images only

### Runtime Security
- **Admission Control**: Kyverno + OPA Gatekeeper
- **Pod Security**: PSS restricted profile enforced
- **Network Policies**: Zero-trust microsegmentation
- **Runtime Detection**: Falco behavioral monitoring
- **Secret Management**: Azure Key Vault CSI Driver

### Compliance
- ✅ CIS Kubernetes Benchmark v1.8
- ✅ DoD Kubernetes STIG v1r12
- ✅ NIST 800-190 Container Security
- ✅ NSA Kubernetes Hardening Guide
- ✅ FedRAMP Moderate/High controls

## 📊 Observability

- **Metrics**: Prometheus with Azure Monitor integration
- **Logs**: Loki with long-term Azure Storage
- **Traces**: Tempo for distributed tracing
- **Dashboards**: Grafana with security-focused views
- **Alerting**: AlertManager with Azure integration

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## 📄 License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

## 🔗 References

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [DoD Kubernetes STIG](https://public.cyber.mil/stigs/)
- [NIST 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final)
- [NSA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
- [SLSA Framework](https://slsa.dev/)
- [Sigstore](https://www.sigstore.dev/)
