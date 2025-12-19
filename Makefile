.PHONY: help init validate plan apply destroy bootstrap test clean

# Variables
TERRAFORM_DIR ?= terraform/environments/commercial/dev
KUBECONFIG_PATH ?= ~/.kube/config

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	cd $(TERRAFORM_DIR) && terraform init

validate: ## Validate Terraform configuration
	cd $(TERRAFORM_DIR) && terraform validate
	@echo "Running tflint..."
	cd $(TERRAFORM_DIR) && tflint
	@echo "Running terraform fmt check..."
	terraform fmt -check -recursive

fmt: ## Format Terraform files
	terraform fmt -recursive

plan: ## Create Terraform plan
	cd $(TERRAFORM_DIR) && terraform plan -out=tfplan

apply: ## Apply Terraform plan
	cd $(TERRAFORM_DIR) && terraform apply tfplan

destroy: ## Destroy Terraform resources
	cd $(TERRAFORM_DIR) && terraform destroy

bootstrap-flux: ## Bootstrap Flux GitOps
	./scripts/bootstrap/flux-bootstrap.sh

install-platform: ## Install platform services via Helm
	./scripts/bootstrap/install-platform-services.sh

validate-policies: ## Validate Kyverno and Gatekeeper policies
	./scripts/validation/validate-policies.sh

test-policies: ## Test policies against sample workloads
	./scripts/validation/test-policies.sh

scan-images: ## Scan container images for vulnerabilities
	./scripts/security/scan-images.sh

verify-signatures: ## Verify image signatures with Cosign
	./scripts/security/verify-signatures.sh

generate-sbom: ## Generate SBOM for all images
	./scripts/security/generate-sbom.sh

compliance-check: ## Run CIS and STIG compliance checks
	./scripts/validation/compliance-check.sh

clean: ## Clean temporary files
	find . -type f -name '*.tfplan' -delete
	find . -type d -name '.terraform' -exec rm -rf {} +
	find . -type f -name 'Chart.lock' -delete
	find . -type d -name 'charts/*/charts' -exec rm -rf {} +

docs: ## Generate documentation
	./scripts/docs/generate-docs.sh

pre-commit: validate test-policies ## Run pre-commit checks
	@echo "Pre-commit checks passed!"

.DEFAULT_GOAL := help
