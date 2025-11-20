#!/bin/bash

# Fix vCPU Quota and Cleanup Issues
set -e

echo "=================================================="
echo "🔧 Fixing vCPU Quota & Cleanup Issues"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
RESOURCE_GROUP="rg-banking-aks-prod"

echo -e "${RED}⚠️  Two issues detected:${NC}"
echo "1. Insufficient vCPU quota (need 12, have 10)"
echo "2. Diagnostic setting already exists from previous run"
echo ""

echo -e "${YELLOW}Solutions:${NC}"
echo "Option A: Use smaller VMs (2 vCPUs each = 6 total)"
echo "Option B: Increase Azure quota"
echo "Option C: Use different region"
echo ""

read -p "Choose solution (A/B/C): " SOLUTION

case $SOLUTION in
  A|a)
    echo ""
    echo -e "${BLUE}Option A: Using smaller VMs${NC}"
    echo ""
    
    # Update variables.tf to use smaller VMs
    if [ -f "variables.tf" ]; then
      cp variables.tf variables.tf.backup
      
      # Change from D4s_v3 (4 vCPU) to D2s_v3 (2 vCPU)
      sed -i 's/Standard_D4s_v3/Standard_D2s_v3/g' variables.tf
      
      echo -e "${GREEN}✓ Changed VM size from D4s_v3 to D2s_v3${NC}"
      echo "  Old: 4 vCPU × 3 nodes = 12 vCPUs"
      echo "  New: 2 vCPU × 3 nodes = 6 vCPUs"
      echo ""
    fi
    ;;
    
  B|b)
    echo ""
    echo -e "${BLUE}Option B: Requesting quota increase${NC}"
    echo ""
    echo "To increase your quota:"
    echo "1. Go to Azure Portal"
    echo "2. Search for 'Quotas'"
    echo "3. Select 'Compute'"
    echo "4. Filter by region: eastus"
    echo "5. Find 'Standard DSv3 Family vCPUs'"
    echo "6. Click 'Request increase'"
    echo "7. Request at least 12 vCPUs"
    echo ""
    echo "Or use Azure CLI:"
    echo "  az vm list-usage --location eastus --output table"
    echo ""
    echo "Approval usually takes 1-2 hours"
    echo ""
    read -p "Press Enter when quota is increased..."
    ;;
    
  C|c)
    echo ""
    echo -e "${BLUE}Option C: Using different region${NC}"
    echo ""
    
    echo "Available regions with likely quota:"
    echo "  - westus"
    echo "  - westus2"
    echo "  - centralus"
    echo "  - westeurope"
    echo "  - northeurope"
    echo ""
    
    read -p "Enter region name (e.g., westus2): " NEW_REGION
    
    if [ -f "variables.tf" ]; then
      cp variables.tf variables.tf.backup
      
      # Update location
      sed -i "s/\"East US\"/\"$NEW_REGION\"/g" variables.tf
      sed -i "s/eastus/$NEW_REGION/g" variables.tf
      
      echo -e "${GREEN}✓ Changed region to: $NEW_REGION${NC}"
      echo ""
    fi
    ;;
    
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

# Fix 2: Clean up existing diagnostic settings
echo -e "${BLUE}Cleaning up existing diagnostic settings...${NC}"

if az account show &> /dev/null; then
    # Check if resource group exists
    if az group show --name $RESOURCE_GROUP &> /dev/null 2>&1; then
        echo "Found resource group: $RESOURCE_GROUP"
        
        # Try to delete diagnostic settings
        echo "Removing existing diagnostic settings..."
        
        # Application Gateway diagnostic setting
        az monitor diagnostic-settings delete \
          --name bankaks-appgw-diag \
          --resource $(az network application-gateway show --name bankaks-appgw --resource-group $RESOURCE_GROUP --query id -o tsv 2>/dev/null) \
          2>/dev/null || echo "  No App Gateway diagnostic setting to remove"
        
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    else
        echo "Resource group doesn't exist yet (this is fine)"
    fi
else
    echo -e "${YELLOW}⚠ Not logged in to Azure, skipping cleanup${NC}"
    echo "Run: az login"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Fixes Applied!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

if [ "$SOLUTION" == "A" ] || [ "$SOLUTION" == "a" ]; then
    echo "Next steps:"
    echo "  1. terraform plan -out=tfplan"
    echo "  2. Review that it uses D2s_v3 VMs"
    echo "  3. terraform apply tfplan"
elif [ "$SOLUTION" == "C" ] || [ "$SOLUTION" == "c" ]; then
    echo "Next steps:"
    echo "  1. terraform init -reconfigure"
    echo "  2. terraform plan -out=tfplan"
    echo "  3. terraform apply tfplan"
else
    echo "Next steps:"
    echo "  1. Wait for quota increase"
    echo "  2. terraform plan -out=tfplan"
    echo "  3. terraform apply tfplan"
fi
echo ""
