.PHONY: help init plan apply destroy validate fmt test clean

# Default target
help:
	@echo "AWS WAFv2 Fail2ban Terraform Management"
	@echo ""
	@echo "Available targets:"
	@echo "  init      - Initialize Terraform"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform files"
	@echo "  plan      - Show Terraform execution plan"
	@echo "  apply     - Apply Terraform configuration"
	@echo "  destroy   - Destroy Terraform resources"
	@echo "  test      - Run all tests"
	@echo "  clean     - Clean temporary files"

# Terraform operations
init:
	@echo "🚀 Initializing Terraform..."
	cd terraform && terraform init

validate:
	@echo "✅ Validating Terraform configuration..."
	cd terraform && terraform validate

fmt:
	@echo "🎨 Formatting Terraform files..."
	cd terraform && terraform fmt -recursive

plan:
	@echo "📋 Creating Terraform plan..."
	cd terraform && terraform plan

apply:
	@echo "🚀 Applying Terraform configuration..."
	cd terraform && terraform apply

destroy:
	@echo "💥 Destroying Terraform resources..."
	cd terraform && terraform destroy

# Testing
test:
	@echo "🧪 Running tests..."
	./scripts/test.sh

# Cleanup
clean:
	@echo "🧹 Cleaning temporary files..."
	rm -f terraform/*.zip
	rm -rf terraform/.terraform/providers
	find . -name "*.backup" -delete
