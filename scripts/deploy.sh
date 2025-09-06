#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
TFVARS_FILE="terraform.tfvars"

# Functions
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform is not installed${NC}"
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not configured${NC}"
        exit 1
    fi
    
    # Check if tfvars file exists
    if [ ! -f "$TERRAFORM_DIR/$TFVARS_FILE" ]; then
        echo -e "${YELLOW}⚠️  $TFVARS_FILE not found. Please create it from terraform.tfvars.example${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

deploy() {
    echo -e "${BLUE}🚀 Starting deployment...${NC}"
    
    cd $TERRAFORM_DIR
    
    # Initialize Terraform
    echo -e "${BLUE}📦 Initializing Terraform...${NC}"
    terraform init
    
    # Validate configuration
    echo -e "${BLUE}✅ Validating configuration...${NC}"
    terraform validate
    
    # Format files
    echo -e "${BLUE}🎨 Formatting files...${NC}"
    terraform fmt
    
    # Show plan
    echo -e "${BLUE}📋 Showing execution plan...${NC}"
    terraform plan -var-file="$TFVARS_FILE"
    
    # Confirm deployment
    echo -e "${YELLOW}❓ Do you want to apply these changes? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${BLUE}🚀 Applying changes...${NC}"
        terraform apply -var-file="$TFVARS_FILE"
        echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    else
        echo -e "${YELLOW}⏸️  Deployment cancelled${NC}"
    fi
    
    cd ..
}

# Main execution
main() {
    echo -e "${BLUE}🚀 AWS WAFv2 Fail2ban Deployment Script${NC}"
    echo "================================================"
    
    check_prerequisites
    deploy
    
    echo "================================================"
    echo -e "${GREEN}✨ Deployment script completed${NC}"
}

# Run main function
main "$@"
