#!/bin/bash
# Script to install all platform services
# Usage: ./install-platform-services.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Installing AKS Platform Services...${NC}"
echo ""

# Install Kyverno
echo -e "${YELLOW}1. Installing Kyverno...${NC}"
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace kyverno pod-security.kubernetes.io/enforce=restricted --overwrite

helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
    --namespace kyverno \
    --values helm-charts/kyverno/values.yaml \
    --wait \
    --timeout 10m

echo -e "${GREEN}✅ Kyverno installed${NC}"
echo ""

# Apply Kyverno policies
echo -e "${YELLOW}2. Applying Kyverno policies...${NC}"
kubectl apply -f policies/kyverno/pod-security/ --recursive
kubectl apply -f policies/kyverno/supply-chain/ --recursive
echo -e "${GREEN}✅ Policies applied${NC}"
echo ""

# Apply network policies
echo -e "${YELLOW}3. Applying network policies...${NC}"
kubectl apply -f policies/network-policies/ --recursive
echo -e "${GREEN}✅ Network policies applied${NC}"
echo ""

# Verify installations
echo -e "${YELLOW}4. Verifying installations...${NC}"
kubectl get pods -n kyverno
kubectl get clusterpolicy
kubectl get networkpolicy -A

echo ""
echo -e "${GREEN}🎉 Platform services installation complete!${NC}"
