#!/bin/bash

# Complete Cleanup and Fresh Deployment
set -e

echo "=================================================="
echo "🧹 Complete Cleanup & Fresh Deployment"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

RESOURCE_GROUP="rg-banking-aks-prod"

echo -e "${YELLOW}⚠️  This script will:${NC}"
echo "1. Delete the entire resource group (if exists)"
echo "2. Clean Terraform state"
echo "3. Remove diagnostic settings that may conflict"
echo "4. Use smaller VMs (D2s_v3 instead of D4s_v3)"
echo "5. Redeploy everything fresh"
echo ""
echo "This ensures a clean deployment without quota or conflict issues."
echo ""

read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# Check Azure login
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 1: Checking for existing resource group...${NC}"

if az group show --name $RESOURCE_GROUP &> /dev/null 2>&1; then
    echo "Found resource group: $RESOURCE_GROUP"
    echo ""
    echo "Current resources:"
    az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:type}" --output table
    echo ""
    
    echo -e "${BLUE}Deleting resource group...${NC}"
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    
    echo -e "${YELLOW}Waiting for deletion to complete (this may take 5-10 minutes)...${NC}"
    
    # Wait for deletion
    COUNTER=0
    while az group show --name $RESOURCE_GROUP &> /dev/null 2>&1; do
        echo -n "."
        sleep 10
        COUNTER=$((COUNTER + 1))
        
        if [ $COUNTER -gt 60 ]; then
            echo ""
            echo -e "${YELLOW}⚠ Deletion is taking longer than expected${NC}"
            echo "You can continue in Azure Portal or wait longer"
            read -p "Continue anyway? (yes/no): " CONTINUE
            if [ "$CONTINUE" == "yes" ]; then
                break
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Resource group deleted${NC}"
else
    echo "Resource group doesn't exist (clean slate)"
fi

echo ""
echo -e "${BLUE}Step 2: Cleaning Terraform state...${NC}"

if [ -f "terraform.tfstate" ]; then
    mv terraform.tfstate terraform.tfstate.old.backup
    echo "✓ Moved old state file to terraform.tfstate.old.backup"
fi

if [ -f "terraform.tfstate.backup" ]; then
    rm -f terraform.tfstate.backup
    echo "✓ Removed old backup"
fi

if [ -d ".terraform" ]; then
    rm -rf .terraform
    echo "✓ Removed .terraform directory"
fi

echo -e "${GREEN}✓ State cleaned${NC}"

echo ""
echo -e "${BLUE}Step 3: Updating configuration for lower quota...${NC}"

# Ensure we're using smaller VMs
if grep -q "Standard_D4s_v3" variables.tf; then
    sed -i 's/Standard_D4s_v3/Standard_D2s_v3/g' variables.tf
    echo "✓ Changed VM size: D4s_v3 → D2s_v3"
    echo "  vCPU usage: 12 → 6 vCPUs"
fi

echo -e "${GREEN}✓ Configuration updated${NC}"

echo ""
echo -e "${BLUE}Step 4: Re-initializing Terraform...${NC}"
terraform init

echo ""
echo -e "${BLUE}Step 5: Creating deployment plan...${NC}"
terraform plan -out=tfplan

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Ready to Deploy!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

echo "Review the plan above. Key points:"
echo "  • VM Size: Standard_D2s_v3 (2 vCPU)"
echo "  • Node Count: 3"
echo "  • Total vCPUs: 6 (well within quota)"
echo ""

read -p "Deploy now? (yes/no): " DEPLOY

if [ "$DEPLOY" == "yes" ]; then
    echo ""
    echo -e "${BLUE}Deploying infrastructure...${NC}"
    echo "This will take 20-25 minutes..."
    echo ""
    
    terraform apply tfplan
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}✅ Deployment Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    
    echo "Infrastructure deployed successfully!"
    echo ""
    
    # Show outputs
    echo "Key Information:"
    terraform output
    
    echo ""
    echo "Next steps:"
    echo "1. Deploy the application: cd .. && ./deploy-manual.sh"
    echo "2. Access your banking app at the Application Gateway IP"
    echo "3. Login with: 5439090 / Passw0rd!!"
else
    echo ""
    echo "Plan saved to: tfplan"
    echo "Apply when ready: terraform apply tfplan"
fi
