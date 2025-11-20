#!/bin/bash

# Fix AKS Version and Application Gateway TLS Issues
set -e

echo "=================================================="
echo "🔧 Fixing AKS Version & App Gateway TLS Policy"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "main.tf" ]; then
    echo "Error: Run this from the terraform directory"
    exit 1
fi

echo -e "${YELLOW}This script will fix:${NC}"
echo "1. AKS Kubernetes version (use latest supported)"
echo "2. Application Gateway TLS policy (modern version)"
echo ""

# Create backup
cp main.tf main.tf.backup
echo -e "${GREEN}✓ Backup created: main.tf.backup${NC}"
echo ""

# Fix 1: Remove hardcoded Kubernetes version
echo -e "${BLUE}Fix 1: Removing hardcoded AKS version...${NC}"

# Comment out kubernetes_version line
sed -i 's/kubernetes_version.*=.*var\.kubernetes_version/# kubernetes_version removed - uses latest supported version/' main.tf

echo -e "${GREEN}✓ AKS will now use the latest supported version in your region${NC}"
echo ""

# Fix 2: Add modern TLS policy to Application Gateway
echo -e "${BLUE}Fix 2: Adding modern TLS policy to Application Gateway...${NC}"

# Check if ssl_policy already exists
if grep -q "ssl_policy" main.tf; then
    echo -e "${YELLOW}⚠ SSL policy already exists, skipping...${NC}"
else
    # Add ssl_policy block after waf_configuration
    sed -i '/waf_configuration {/,/^  }$/{
        /^  }$/a\
\
  ssl_policy {\
    policy_type = "Predefined"\
    policy_name = "AppGwSslPolicy20220101"\
  }
    }' main.tf
    
    echo -e "${GREEN}✓ Modern TLS policy added (AppGwSslPolicy20220101)${NC}"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Fixes Applied Successfully!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

echo "What was fixed:"
echo ""
echo "1. AKS Kubernetes Version:"
echo "   ❌ Was: kubernetes_version = \"1.28.3\" (unsupported)"
echo "   ✅ Now: Uses latest supported version automatically"
echo ""
echo "2. Application Gateway TLS:"
echo "   ❌ Was: Default (AppGwSslPolicy20150501 - deprecated)"
echo "   ✅ Now: AppGwSslPolicy20220101 (modern, secure)"
echo ""

# Get supported AKS versions
echo -e "${BLUE}Checking supported AKS versions in your region...${NC}"
LOCATION=$(grep 'location.*=' variables.tf | grep default | head -1 | sed 's/.*"\(.*\)".*/\1/' | tr '[:upper:]' '[:lower:]' | tr ' ' '')

if [ -n "$LOCATION" ]; then
    echo "Region: $LOCATION"
    echo ""
    echo "Supported Kubernetes versions:"
    az aks get-versions --location "$LOCATION" --output table 2>/dev/null || echo "  Run: az aks get-versions --location $LOCATION"
else
    echo "  Run: az aks get-versions --location eastus"
fi

echo ""
echo "Next steps:"
echo "  1. terraform init"
echo "  2. terraform plan -out=tfplan"
echo "  3. terraform apply tfplan"
echo ""
