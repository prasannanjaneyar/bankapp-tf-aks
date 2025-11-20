#!/bin/bash

# Quick Fix for Application Gateway Syntax Error
set -e

echo "=================================================="
echo "🔧 Fixing Application Gateway Syntax Error"
echo "=================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ ! -f "main.tf" ]; then
    echo "Error: Run this from the terraform directory"
    exit 1
fi

echo -e "${BLUE}Fixing lifecycle block in main.tf...${NC}"

# Create backup
cp main.tf main.tf.bak
echo "✓ Backup created: main.tf.bak"

# Fix the syntax error using sed
sed -i 's/backend_address_pool\[0\]\.ip_addresses/backend_address_pool/g' main.tf

echo -e "${GREEN}✓ Fixed!${NC}"
echo ""
echo "The error was:"
echo "  backend_address_pool[0].ip_addresses"
echo ""
echo "Changed to:"
echo "  backend_address_pool"
echo ""
echo "This ignores ALL backend address pool changes (which is what we want)"
echo ""
echo "Next steps:"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
