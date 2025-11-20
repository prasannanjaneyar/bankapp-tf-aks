#!/bin/bash

# Fix Terraform State Issues
# This script cleans up inconsistent state and redeploys

set -e

echo "=================================================="
echo "🔧 Fixing Terraform State Issues"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    echo -e "${RED}❌ Error: main.tf not found${NC}"
    echo "Please run this script from the terraform directory"
    exit 1
fi

echo -e "${YELLOW}⚠️  This script will:${NC}"
echo "1. Remove inconsistent resources from state"
echo "2. Clean up partial resources in Azure"
echo "3. Re-apply Terraform configuration"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# Get resource group name
RESOURCE_GROUP="rg-banking-aks-prod"

echo ""
echo -e "${BLUE}Step 1: Checking Azure login...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

echo -e "${GREEN}✓ Logged in to Azure${NC}"

echo ""
echo -e "${BLUE}Step 2: Checking if resource group exists...${NC}"
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${YELLOW}⚠️  Resource group exists with partial resources${NC}"
    echo ""
    echo "Resources in group:"
    az resource list --resource-group $RESOURCE_GROUP --query "[].{Name:name, Type:type}" --output table
    echo ""
    
    read -p "Delete entire resource group and start fresh? (yes/no): " DELETE_RG
    
    if [ "$DELETE_RG" == "yes" ]; then
        echo -e "${BLUE}Deleting resource group...${NC}"
        az group delete --name $RESOURCE_GROUP --yes --no-wait
        
        echo -e "${YELLOW}Waiting for deletion to complete (this may take a few minutes)...${NC}"
        
        # Wait for deletion
        while az group show --name $RESOURCE_GROUP &> /dev/null; do
            echo -n "."
            sleep 10
        done
        
        echo ""
        echo -e "${GREEN}✓ Resource group deleted${NC}"
    fi
else
    echo -e "${GREEN}✓ Resource group doesn't exist (clean state)${NC}"
fi

echo ""
echo -e "${BLUE}Step 3: Cleaning Terraform state...${NC}"

# Remove problematic resources from state if they exist
RESOURCES_TO_REMOVE=(
    "azurerm_public_ip.appgw"
    "azurerm_virtual_network.banking"
    "azurerm_subnet.aks"
    "azurerm_subnet.appgw"
    "azurerm_container_registry.banking"
    "azurerm_key_vault.banking"
)

for resource in "${RESOURCES_TO_REMOVE[@]}"; do
    if terraform state show "$resource" &> /dev/null; then
        echo "Removing $resource from state..."
        terraform state rm "$resource" || true
    fi
done

echo -e "${GREEN}✓ State cleaned${NC}"

echo ""
echo -e "${BLUE}Step 4: Refreshing Terraform state...${NC}"
terraform refresh || true

echo ""
echo -e "${BLUE}Step 5: Re-initializing Terraform...${NC}"
terraform init -upgrade

echo ""
echo -e "${BLUE}Step 6: Creating new plan...${NC}"
terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}⚠️  Ready to apply fresh configuration${NC}"
read -p "Apply now? (yes/no): " APPLY_NOW

if [ "$APPLY_NOW" == "yes" ]; then
    echo -e "${BLUE}Applying Terraform configuration...${NC}"
    terraform apply tfplan
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}✅ Terraform Fix Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Verify resources: terraform output"
    echo "2. Deploy application: ../deploy-manual.sh"
else
    echo "Plan saved to tfplan"
    echo "Apply when ready: terraform apply tfplan"
fi
