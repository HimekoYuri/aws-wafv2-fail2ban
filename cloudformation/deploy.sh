#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="aws-wafv2-fail2ban"
TEMPLATE_FILE="waf-fail2ban.yaml"
PARAMETERS_FILE="parameters.json"

# Functions
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not configured${NC}"
        exit 1
    fi
    
    # Check if template file exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo -e "${RED}❌ Template file $TEMPLATE_FILE not found${NC}"
        exit 1
    fi
    
    # Check if parameters file exists
    if [ ! -f "$PARAMETERS_FILE" ]; then
        echo -e "${YELLOW}⚠️  Parameters file $PARAMETERS_FILE not found. Using template defaults.${NC}"
        PARAMETERS_FILE=""
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

validate_template() {
    echo -e "${BLUE}✅ Validating CloudFormation template...${NC}"
    if aws cloudformation validate-template --template-body file://$TEMPLATE_FILE > /dev/null; then
        echo -e "${GREEN}✅ Template validation passed${NC}"
    else
        echo -e "${RED}❌ Template validation failed${NC}"
        exit 1
    fi
}

deploy_stack() {
    echo -e "${BLUE}🚀 Deploying CloudFormation stack...${NC}"
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name $STACK_NAME &> /dev/null; then
        echo -e "${YELLOW}📝 Stack exists. Updating...${NC}"
        OPERATION="update-stack"
    else
        echo -e "${BLUE}🆕 Creating new stack...${NC}"
        OPERATION="create-stack"
    fi
    
    # Build AWS CLI command
    CMD="aws cloudformation $OPERATION --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --capabilities CAPABILITY_NAMED_IAM"
    
    if [ -n "$PARAMETERS_FILE" ]; then
        CMD="$CMD --parameters file://$PARAMETERS_FILE"
    fi
    
    # Execute deployment
    if eval $CMD; then
        echo -e "${BLUE}⏳ Waiting for stack operation to complete...${NC}"
        if [ "$OPERATION" = "create-stack" ]; then
            aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
        else
            aws cloudformation wait stack-update-complete --stack-name $STACK_NAME
        fi
        echo -e "${GREEN}🎉 Stack deployment completed successfully!${NC}"
    else
        echo -e "${RED}❌ Stack deployment failed${NC}"
        exit 1
    fi
}

show_outputs() {
    echo -e "${BLUE}📋 Stack outputs:${NC}"
    aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs' --output table
}

# Main execution
main() {
    echo -e "${BLUE}🚀 AWS WAFv2 Fail2ban CloudFormation Deployment${NC}"
    echo "================================================"
    
    check_prerequisites
    validate_template
    deploy_stack
    show_outputs
    
    echo "================================================"
    echo -e "${GREEN}✨ Deployment completed successfully!${NC}"
    echo -e "${YELLOW}📝 Don't forget to associate the Web ACL with your CloudFront distribution${NC}"
}

# Run main function
main "$@"
