#!/bin/bash
# Script to validate Kyverno policies
# Usage: ./validate-policies.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Validating Kyverno Policies...${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if kyverno CLI is available
if ! command -v kyverno &> /dev/null; then
    echo -e "${YELLOW}Installing Kyverno CLI...${NC}"
    curl -LO https://github.com/kyverno/kyverno/releases/download/v1.11.0/kyverno-cli_v1.11.0_linux_amd64.tar.gz
    tar -xzf kyverno-cli_v1.11.0_linux_amd64.tar.gz
    sudo mv kyverno /usr/local/bin/
    rm kyverno-cli_v1.11.0_linux_amd64.tar.gz
fi

POLICY_DIR="policies/kyverno"
FAILED=0
PASSED=0

# Validate each policy file
for policy_file in $(find ${POLICY_DIR} -name "*.yaml" -type f); do
    echo -e "${YELLOW}Validating: ${policy_file}${NC}"

    # Validate YAML syntax
    if ! kubectl apply --dry-run=client -f "${policy_file}" > /dev/null 2>&1; then
        echo -e "${RED}❌ Invalid YAML syntax${NC}"
        ((FAILED++))
        continue
    fi

    # Validate with Kyverno CLI
    if kyverno validate "${policy_file}" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Valid Kyverno policy${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Invalid Kyverno policy${NC}"
        kyverno validate "${policy_file}"
        ((FAILED++))
    fi

    echo ""
done

# Summary
echo ""
echo "========================================"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo "========================================"

if [ ${FAILED} -gt 0 ]; then
    exit 1
fi

echo -e "${GREEN}🎉 All policies validated successfully!${NC}"
