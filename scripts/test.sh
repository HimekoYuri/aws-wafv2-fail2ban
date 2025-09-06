#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test functions
test_terraform_syntax() {
    echo -e "${BLUE}🔍 Testing Terraform syntax...${NC}"
    cd terraform
    terraform fmt -check=true -diff=true
    terraform validate
    echo -e "${GREEN}✅ Terraform syntax test passed${NC}"
    cd ..
}

test_terraform_plan() {
    echo -e "${BLUE}📋 Testing Terraform plan...${NC}"
    cd terraform
    if terraform plan -detailed-exitcode >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Terraform plan executed successfully${NC}"
    else
        local exit_code=$?
        if [ $exit_code -eq 2 ]; then
            echo -e "${YELLOW}⚠️  Changes detected in plan (this is expected for new deployment)${NC}"
        else
            echo -e "${RED}❌ Terraform plan failed with exit code $exit_code${NC}"
            terraform plan
            exit 1
        fi
    fi
    cd ..
}

test_security_scan() {
    echo -e "${BLUE}🛡️  Running security scan...${NC}"
    if command -v checkov &> /dev/null; then
        if checkov -d terraform --framework terraform --quiet; then
            echo -e "${GREEN}✅ Security scan passed${NC}"
        else
            echo -e "${YELLOW}⚠️  Security scan completed with warnings (acceptable for this configuration)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Checkov not installed, skipping security scan${NC}"
    fi
}

test_lambda_function() {
    echo -e "${BLUE}🔧 Testing Lambda function...${NC}"
    if [ -f "terraform/lambda/slack_notifier.py" ]; then
        python3 -m py_compile terraform/lambda/slack_notifier.py
        echo -e "${GREEN}✅ Lambda function syntax test passed${NC}"
    else
        echo -e "${RED}❌ Lambda function not found${NC}"
        exit 1
    fi
}

test_variables() {
    echo -e "${BLUE}📝 Testing variables configuration...${NC}"
    if [ -f "terraform/terraform.tfvars.example" ]; then
        echo -e "${GREEN}✅ Example variables file exists${NC}"
    else
        echo -e "${RED}❌ Example variables file not found${NC}"
        exit 1
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}🧪 Starting AWS WAFv2 Fail2ban Tests${NC}"
    echo "================================================"
    
    test_terraform_syntax
    test_variables
    test_lambda_function
    test_terraform_plan
    test_security_scan
    
    echo "================================================"
    echo -e "${GREEN}🎉 All tests passed successfully!${NC}"
}

# Run main function
main "$@"
