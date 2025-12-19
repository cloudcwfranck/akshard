#!/bin/bash
# Script to verify container image signatures with Cosign
# Usage: ./verify-signatures.sh <image>

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if cosign is installed
if ! command -v cosign &> /dev/null; then
    echo -e "${RED}Error: cosign is not installed${NC}"
    echo "Install: https://docs.sigstore.dev/cosign/installation/"
    exit 1
fi

# Get image from argument or prompt
IMAGE="${1:-}"
if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <image>"
    echo "Example: $0 cgr.dev/chainguard/nginx:latest"
    exit 1
fi

echo -e "${YELLOW}Verifying image signature for: ${IMAGE}${NC}"
echo ""

# Verify signature (keyless with Fulcio/Rekor)
echo -e "${YELLOW}1. Verifying keyless signature...${NC}"
if cosign verify \
    --certificate-identity-regexp=".*" \
    --certificate-oidc-issuer-regexp=".*" \
    "${IMAGE}" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Signature verification passed${NC}"
else
    echo -e "${RED}❌ Signature verification failed${NC}"
    echo "Image may not be signed or signature is invalid"
    exit 1
fi

# Verify SBOM attestation
echo ""
echo -e "${YELLOW}2. Verifying SBOM attestation...${NC}"
if cosign verify-attestation \
    --type cyclonedx \
    --certificate-identity-regexp=".*" \
    --certificate-oidc-issuer-regexp=".*" \
    "${IMAGE}" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SBOM attestation found (CycloneDX)${NC}"
elif cosign verify-attestation \
    --type spdx \
    --certificate-identity-regexp=".*" \
    --certificate-oidc-issuer-regexp=".*" \
    "${IMAGE}" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SBOM attestation found (SPDX)${NC}"
else
    echo -e "${YELLOW}⚠️  No SBOM attestation found${NC}"
fi

# Verify SLSA provenance
echo ""
echo -e "${YELLOW}3. Verifying SLSA provenance...${NC}"
if cosign verify-attestation \
    --type slsaprovenance \
    --certificate-identity-regexp=".*" \
    --certificate-oidc-issuer-regexp=".*" \
    "${IMAGE}" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SLSA provenance attestation found${NC}"
else
    echo -e "${YELLOW}⚠️  No SLSA provenance attestation found${NC}"
fi

# Display signature details
echo ""
echo -e "${YELLOW}4. Signature details:${NC}"
cosign verify \
    --certificate-identity-regexp=".*" \
    --certificate-oidc-issuer-regexp=".*" \
    "${IMAGE}" 2>/dev/null | jq -r '.[] | {
    issuer: .optional.Issuer,
    subject: .optional.Subject,
    timestamp: .optional.timestamp
}'

echo ""
echo -e "${GREEN}🎉 Image verification complete!${NC}"
