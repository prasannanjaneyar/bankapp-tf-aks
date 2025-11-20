# Terraform State Issues - Troubleshooting Guide

## 🔍 Problem: Inconsistent Terraform State

You're seeing errors like:
- "Provider produced inconsistent result after apply"
- "Resource not found" (404 errors)
- Resources partially created

This happens when a Terraform apply is interrupted or fails partway through.

---

## 🚀 Quick Fix (Recommended)

### Option 1: Use the Fix Script

```bash
cd terraform
../fix-terraform-state.sh
```

This script will:
1. Clean up partial resources
2. Remove inconsistent state
3. Redeploy everything fresh

**Time**: 15-20 minutes

---

### Option 2: Manual Fix (Step-by-Step)

#### Step 1: Check What Exists in Azure

```bash
# See what's in the resource group
az group show --name rg-banking-aks-prod

# List all resources
az resource list \
  --resource-group rg-banking-aks-prod \
  --output table
```

#### Step 2: Delete the Resource Group (Clean Slate)

```bash
# Delete everything and start fresh
az group delete \
  --name rg-banking-aks-prod \
  --yes \
  --no-wait

# Wait for deletion (takes 5-10 minutes)
az group show --name rg-banking-aks-prod
# Should eventually return: ResourceGroupNotFound
```

#### Step 3: Clean Terraform State

```bash
cd terraform

# Remove the state file (if using local state)
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

# If using remote state, taint problematic resources
terraform state list

# Remove inconsistent resources
terraform state rm azurerm_public_ip.appgw
terraform state rm azurerm_virtual_network.banking
terraform state rm azurerm_subnet.aks
terraform state rm azurerm_subnet.appgw
terraform state rm azurerm_container_registry.banking
terraform state rm azurerm_key_vault.banking
```

#### Step 4: Re-initialize

```bash
# Reinitialize
terraform init -upgrade

# Create fresh plan
terraform plan -out=tfplan

# Review the plan
# Should show all resources as "will be created"
```

#### Step 5: Apply Fresh

```bash
terraform apply tfplan
```

---

## 🛡️ Prevention: Use Improved Configuration

Replace your `main.tf` with the improved version:

```bash
cd terraform
mv main.tf main.tf.backup
cp main-improved.tf main.tf
```

### What's Improved:

1. **Explicit Dependencies**
   ```hcl
   depends_on = [azurerm_resource_group.banking]
   ```
   Ensures resources are created in correct order

2. **Lifecycle Rules**
   ```hcl
   lifecycle {
     create_before_destroy = true
     ignore_changes = [...]
   }
   ```
   Prevents issues with resource recreation

3. **Better Error Handling**
   ```hcl
   provider "azurerm" {
     features {
       resource_group {
         prevent_deletion_if_contains_resources = false
       }
     }
   }
   ```

4. **Provider Version Pinning**
   ```hcl
   azurerm = {
     source  = "hashicorp/azurerm"
     version = "~> 3.80"  # More specific version
   }
   ```

---

## 🔧 Alternative Approaches

### Approach A: Partial State Recovery

If you want to keep some resources:

```bash
# Import existing resources
terraform import azurerm_resource_group.banking /subscriptions/SUB_ID/resourceGroups/rg-banking-aks-prod

# Continue with other resources...
terraform plan
terraform apply
```

### Approach B: Use `-replace` Flag

Target specific problematic resources:

```bash
terraform plan -replace="azurerm_public_ip.appgw" -out=tfplan
terraform apply tfplan
```

### Approach C: Incremental Deployment

Deploy resources in stages:

```bash
# Stage 1: Core networking
terraform apply -target=azurerm_resource_group.banking
terraform apply -target=azurerm_virtual_network.banking
terraform apply -target=azurerm_subnet.aks
terraform apply -target=azurerm_subnet.appgw

# Stage 2: Services
terraform apply -target=azurerm_kubernetes_cluster.banking
terraform apply -target=azurerm_container_registry.banking

# Stage 3: Everything else
terraform apply
```

---

## 🎯 Specific Error Solutions

### Error: "Provider produced inconsistent result"

**Cause**: Resource created in Azure but Terraform lost track

**Solution**:
```bash
terraform refresh
terraform plan
terraform apply
```

### Error: "ResourceNotFound (404)"

**Cause**: Terraform expects a resource that doesn't exist

**Solution**:
```bash
# Remove from state
terraform state rm <resource_name>

# Let Terraform recreate it
terraform plan
terraform apply
```

### Error: "Resource already exists"

**Cause**: Resource exists in Azure but not in state

**Solution**:
```bash
# Import it
terraform import <resource_type>.<name> <azure_resource_id>

# Or remove and recreate
az resource delete --ids <resource_id>
terraform apply
```

---

## 🚨 Common Mistakes to Avoid

### ❌ Don't Do This:
```bash
# Running apply multiple times rapidly
terraform apply
terraform apply  # Before first one finishes
```

### ✅ Do This Instead:
```bash
# Wait for completion
terraform apply
# Wait for "Apply complete!" message
# Then check status
terraform show
```

### ❌ Don't Do This:
```bash
# Manually deleting resources in Azure Portal
# while Terraform state still references them
```

### ✅ Do This Instead:
```bash
# Use Terraform to destroy
terraform destroy -target=<resource>
# Or remove from state first
terraform state rm <resource>
```

---

## 📊 Verification Steps

After fixing, verify everything:

### 1. Check Terraform State
```bash
terraform state list
# Should show all resources
```

### 2. Check Azure Resources
```bash
az resource list \
  --resource-group rg-banking-aks-prod \
  --output table
```

### 3. Verify Outputs
```bash
terraform output
# Should show all expected outputs
```

### 4. Test AKS Connection
```bash
az aks get-credentials \
  --resource-group rg-banking-aks-prod \
  --name bankaks-aks

kubectl get nodes
# Should show 3 nodes
```

---

## 💡 Best Practices Going Forward

### 1. Use Remote State

Set up Azure Storage backend (prevents local state corruption):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "banking-aks.tfstate"
  }
}
```

### 2. Enable State Locking

Prevents concurrent modifications:
- Azure Storage backend has built-in locking
- Always shows who has the lock

### 3. Use Version Control

```bash
# Commit your .tf files
git add *.tf
git commit -m "Infrastructure configuration"
```

### 4. Plan Before Apply

Always review changes:
```bash
terraform plan -out=tfplan
# Review the plan
terraform apply tfplan
```

### 5. Use Workspaces for Environments

```bash
# Development
terraform workspace new dev
terraform apply -var-file=dev.tfvars

# Production
terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

---

## 🔄 Recovery Checklist

After fixing the state:

- [ ] All resources created successfully
- [ ] Terraform state is clean
- [ ] No "unknown" or "null" values in state
- [ ] `terraform plan` shows no changes
- [ ] AKS cluster is accessible
- [ ] ACR is accessible
- [ ] Application Gateway has backend pool
- [ ] Key Vault contains secrets

---

## 📞 Still Having Issues?

### Debug Mode

Enable detailed logging:
```bash
export TF_LOG=DEBUG
terraform apply
```

### State Inspection

```bash
# View specific resource
terraform state show azurerm_kubernetes_cluster.banking

# Show entire state
terraform show

# Validate configuration
terraform validate
```

### Azure Portal Check

1. Go to Azure Portal
2. Navigate to Resource Group
3. Verify each resource manually
4. Check Activity Log for errors

---

## 🎯 Summary

**Quick Fix**:
```bash
cd terraform
../fix-terraform-state.sh
```

**Manual Fix**:
1. Delete resource group
2. Clean state
3. Re-apply

**Prevention**:
1. Use improved main.tf
2. Set up remote state
3. Always plan before apply

---

**Most issues can be resolved by cleaning up and starting fresh!** The fix script automates this entire process.
