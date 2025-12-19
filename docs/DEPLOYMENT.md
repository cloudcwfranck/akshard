# AKS Bootstrap Kit - Deployment Guide

Complete deployment guide for enterprise-grade AKS with supply chain security.

## Prerequisites

### Required Tools

Install the following tools before deployment:

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az --version  # Should be >= 2.50.0

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash
flux --version

# Cosign (for image verification)
wget https://github.com/sigstore/cosign/releases/download/v2.2.2/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign
cosign version

# Syft (for SBOM generation)
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
syft version

# Trivy (for vulnerability scanning)
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
trivy --version
```

### Azure Permissions

Required Azure RBAC roles:
- **Owner** or **Contributor** + **User Access Administrator** on subscription
- **Azure Kubernetes Service RBAC Cluster Admin** (for cluster operations)
- **Key Vault Administrator** (for Key Vault integration)
- **Managed Identity Operator** (for workload identity)

### Azure AD Setup

1. **Create Admin Group**:
```bash
az ad group create \
  --display-name "AKS-Admins" \
  --mail-nickname "aks-admins" \
  --description "AKS Cluster Administrators"

# Get the group object ID
GROUP_ID=$(az ad group show --group "AKS-Admins" --query id -o tsv)
echo "Group ID: ${GROUP_ID}"
```

2. **Add Users to Admin Group**:
```bash
az ad group member add \
  --group "AKS-Admins" \
  --member-id <user-object-id>
```

---

## Step 1: Prepare Terraform Backend

Create Azure Storage for Terraform state:

```bash
# Variables
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="sttfstate${RANDOM}"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create \
  --name ${RESOURCE_GROUP} \
  --location ${LOCATION}

# Create storage account
az storage account create \
  --name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION} \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2

# Create blob container
az storage container create \
  --name ${CONTAINER_NAME} \
  --account-name ${STORAGE_ACCOUNT}

# Enable versioning
az storage account blob-service-properties update \
  --account-name ${STORAGE_ACCOUNT} \
  --enable-versioning true

echo "Terraform backend created:"
echo "  Resource Group: ${RESOURCE_GROUP}"
echo "  Storage Account: ${STORAGE_ACCOUNT}"
echo "  Container: ${CONTAINER_NAME}"
```

---

## Step 2: Configure Terraform Variables

1. **Navigate to environment directory**:
```bash
cd terraform/environments/commercial/dev
```

2. **Create `terraform.tfvars`**:
```bash
cat > terraform.tfvars <<EOF
# Basic Configuration
resource_group_name = "rg-aks-dev-001"
location            = "eastus"
cluster_name        = "aks-dev-001"
kubernetes_version  = "1.28.3"

# Azure AD
aks_admin_group_name = "AKS-Admins"

# Security
api_server_authorized_ip_ranges = [
  # Add your IP addresses for API access
  # Example: "203.0.113.0/24"
]

# Monitoring
log_retention_days = 90

# Tags
tags = {
  Environment  = "Development"
  CostCenter   = "Engineering"
  Owner        = "platform-team@example.com"
  Project      = "AKS-Bootstrap"
}
EOF
```

3. **Configure backend** (edit `main.tf`):
```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "sttfstate12345"  # Your storage account
  container_name       = "tfstate"
  key                  = "aks-dev.tfstate"
}
```

---

## Step 3: Deploy AKS Infrastructure

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan deployment
terraform plan -out=tfplan

# Review the plan carefully, then apply
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

**Expected deployment time**: 15-20 minutes

---

## Step 4: Connect to AKS Cluster

```bash
# Get cluster name and resource group from outputs
CLUSTER_NAME=$(terraform output -raw cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Get credentials
az aks get-credentials \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --overwrite-existing

# Verify connection
kubectl get nodes
kubectl cluster-info

# Verify RBAC
kubectl auth can-i "*" "*" --all-namespaces
```

---

## Step 5: Bootstrap Flux GitOps

1. **Create GitHub Personal Access Token**:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Generate new token with `repo` scope
   - Save token securely

2. **Export token**:
```bash
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
export GITHUB_REPO=<your-repo-name>
```

3. **Bootstrap Flux**:
```bash
flux bootstrap github \
  --owner=${GITHUB_USER} \
  --repository=${GITHUB_REPO} \
  --branch=main \
  --path=./gitops/clusters/dev \
  --personal \
  --components-extra=image-reflector-controller,image-automation-controller
```

4. **Verify Flux installation**:
```bash
flux check
kubectl get pods -n flux-system
flux get sources git
flux get kustomizations
```

---

## Step 6: Deploy Platform Services

### Install Kyverno

```bash
# Create namespace
kubectl create namespace kyverno

# Label namespace for Pod Security Standards
kubectl label namespace kyverno \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Install Kyverno via Helm
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --values helm-charts/kyverno/values.yaml \
  --wait

# Verify installation
kubectl get pods -n kyverno
kubectl get clusterpolicy
```

### Apply Kyverno Policies

```bash
# Apply Pod Security Standards policies
kubectl apply -f policies/kyverno/pod-security/

# Apply Supply Chain Security policies
kubectl apply -f policies/kyverno/supply-chain/

# Verify policies
kubectl get clusterpolicy
kubectl get policyreport -A
```

### Install Network Policies

```bash
# Apply default deny-all policies
kubectl apply -f policies/network-policies/default-deny-all.yaml

# Apply application-specific policies
kubectl apply -f policies/network-policies/allow-ingress-to-app.yaml
```

---

## Step 7: Verify Security Configuration

### Pod Security Standards

```bash
# Test PSS enforcement
kubectl run test-pod \
  --image=nginx \
  --dry-run=server
# Should fail due to missing securityContext

# Test with compliant pod
kubectl run test-pod \
  --image=cgr.dev/chainguard/nginx:latest \
  --dry-run=server \
  --overrides='
{
  "spec": {
    "securityContext": {
      "runAsNonRoot": true,
      "runAsUser": 65532,
      "seccompProfile": {"type": "RuntimeDefault"}
    },
    "containers": [{
      "name": "test-pod",
      "image": "cgr.dev/chainguard/nginx:latest",
      "securityContext": {
        "allowPrivilegeEscalation": false,
        "capabilities": {"drop": ["ALL"]},
        "readOnlyRootFilesystem": true
      }
    }]
  }
}'
```

### Image Signature Verification

```bash
# Try to deploy unsigned image (should fail)
kubectl run test-unsigned \
  --image=docker.io/nginx:latest \
  --dry-run=server
# Should be blocked by policy

# Deploy signed Chainguard image (should succeed)
kubectl run test-signed \
  --image=cgr.dev/chainguard/nginx:latest@sha256:... \
  --dry-run=server
```

### Network Policies

```bash
# Verify default deny
kubectl run test-curl --image=cgr.dev/chainguard/curl:latest -- sleep 3600
kubectl exec test-curl -- curl -m 5 http://kubernetes.default.svc
# Should timeout (blocked by network policy)
```

---

## Step 8: Enable Monitoring and Observability

```bash
# Verify Container Insights
kubectl get pods -n kube-system | grep omsagent

# Check Azure Monitor integration
az aks show \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --query "addonProfiles.omsAgent.enabled"

# Verify Microsoft Defender
az aks show \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --query "securityProfile.defender.logAnalyticsWorkspaceResourceId"
```

---

## Step 9: Compliance Validation

```bash
# Run CIS Benchmark scan
make compliance-check

# Generate compliance report
./scripts/compliance/generate-report.sh

# Verify all policies are enforced
kubectl get clusterpolicy -o json | jq '.items[] | {name: .metadata.name, action: .spec.validationFailureAction}'
```

---

## Troubleshooting

### Common Issues

**1. Terraform backend authentication fails**:
```bash
az login
az account set --subscription <subscription-id>
```

**2. AKS cluster creation fails**:
- Check Azure subscription limits
- Verify service principal/managed identity permissions
- Check regional VM quota

**3. Kubectl connection fails**:
```bash
# For private cluster, use Azure Bastion or VPN
# Or enable authorized IP ranges temporarily
az aks update \
  --resource-group ${RESOURCE_GROUP} \
  --name ${CLUSTER_NAME} \
  --api-server-authorized-ip-ranges "$(curl -s ifconfig.me)/32"
```

**4. Kyverno policy blocks all pods**:
```bash
# Temporarily set to Audit mode
kubectl patch clusterpolicy <policy-name> \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/validationFailureAction", "value":"Audit"}]'
```

---

## Next Steps

1. **Set up CI/CD**: Configure GitHub Actions or Azure DevOps
2. **Deploy Applications**: Use GitOps to deploy workloads
3. **Configure Alerting**: Set up Azure Monitor alerts
4. **Implement Backup**: Configure Velero for cluster backups
5. **Security Hardening**: Review and customize policies for your needs

---

## Additional Resources

- [Terraform AKS Module Documentation](../terraform/modules/aks-cluster/README.md)
- [Kyverno Policy Reference](../policies/kyverno/README.md)
- [Compliance Mapping](./compliance/CIS-KUBERNETES-BENCHMARK-v1.8-MAPPING.md)
- [Network Architecture](./architecture/NETWORK-DESIGN.md)

---

**Support**: For issues, create a GitHub issue or contact platform-team@example.com
