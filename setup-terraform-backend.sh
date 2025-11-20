#!/bin/bash

# Setup Terraform Backend in Azure Storage
# This script creates the storage account and container for Terraform state

set -e

echo "=================================================="
echo "🔧 Terraform Backend Setup"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
RESOURCE_GROUP="rg-terraform-state"
LOCATION="eastus"
STORAGE_ACCOUNT="sttfstate$(date +%s | tail -c 7)"  # Append timestamp for uniqueness
CONTAINER_NAME="tfstate"

echo -e "${BLUE}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER_NAME"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✓ Logged in to Azure${NC}"
echo "  Subscription: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"
echo ""

# Create Resource Group
echo -e "${BLUE}📦 Creating resource group...${NC}"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output none

echo -e "${GREEN}✓ Resource group created${NC}"

# Create Storage Account
echo -e "${BLUE}💾 Creating storage account...${NC}"
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

echo -e "${GREEN}✓ Storage account created${NC}"

# Get Storage Account Key
echo -e "${BLUE}🔑 Retrieving storage account key...${NC}"
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Create Container
echo -e "${BLUE}📂 Creating blob container...${NC}"
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY \
  --output none

echo -e "${GREEN}✓ Container created${NC}"

# Enable versioning
echo -e "${BLUE}🔄 Enabling blob versioning...${NC}"
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --enable-versioning true \
  --output none

echo -e "${GREEN}✓ Versioning enabled${NC}"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Terraform Backend Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Backend Configuration:"
echo ""
echo "  Resource Group:    $RESOURCE_GROUP"
echo "  Storage Account:   $STORAGE_ACCOUNT"
echo "  Container:         $CONTAINER_NAME"
echo "  State File:        banking-aks.tfstate"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Update your pipeline variables!${NC}"
echo ""
echo "Update these variables in azure-pipelines-full.yml:"
echo ""
echo "variables:"
echo "  tfBackendResourceGroup: '$RESOURCE_GROUP'"
echo "  tfBackendStorageAccount: '$STORAGE_ACCOUNT'"
echo "  tfBackendContainerName: '$CONTAINER_NAME'"
echo "  tfBackendKey: 'banking-aks.tfstate'"
echo ""
echo "Or set as pipeline variables in Azure DevOps:"
echo "1. Go to Pipelines → Library → Variable groups"
echo "2. Create new variable group: 'terraform-backend'"
echo "3. Add the above variables"
echo ""
echo -e "${BLUE}Storage Account Details:${NC}"
az storage account show \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query "{Name:name, Location:location, Sku:sku.name, State:provisioningState}" \
  --output table
echo ""

# Save to file
cat > terraform-backend-config.txt << EOF
# Terraform Backend Configuration
# Generated: $(date)

Resource Group:    $RESOURCE_GROUP
Storage Account:   $STORAGE_ACCOUNT
Container:         $CONTAINER_NAME
State File:        banking-aks.tfstate

# Pipeline Variables (YAML)
tfBackendResourceGroup: '$RESOURCE_GROUP'
tfBackendStorageAccount: '$STORAGE_ACCOUNT'
tfBackendContainerName: '$CONTAINER_NAME'
tfBackendKey: 'banking-aks.tfstate'

# Azure DevOps Service Connection (Verify)
Service Connection Name: Azure-ServiceConnection
Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)
EOF

echo -e "${GREEN}✓ Configuration saved to: terraform-backend-config.txt${NC}"
echo ""
