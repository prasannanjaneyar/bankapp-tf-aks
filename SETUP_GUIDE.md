# Complete Azure DevOps Setup Guide - Infrastructure + Application

This guide shows you how to deploy **BOTH infrastructure and application** using Azure DevOps pipelines.

## 🎯 What This Pipeline Does

### Single Pipeline Deploys Everything:
1. ✅ **Validate** - Terraform validation and planning
2. ✅ **Deploy Infrastructure** - AKS, ACR, VNet, App Gateway, Key Vault
3. ✅ **Build Application** - Docker image build and push to ACR
4. ✅ **Deploy Application** - Deploy to AKS with auto-scaling

### Result: Complete end-to-end deployment from code push!

---

## 📋 Prerequisites

- [x] Azure subscription with Owner or Contributor access
- [x] Azure DevOps organization
- [x] This repository code

---

## 🚀 Step-by-Step Setup

### Step 1: Setup Terraform Backend (One-Time Setup)

The Terraform state needs to be stored in Azure Storage.

```bash
# Run the setup script
./setup-terraform-backend.sh
```

This creates:
- Resource Group: `rg-terraform-state`
- Storage Account: `sttfstate<random>`
- Blob Container: `tfstate`

**Save the output!** You'll need these values for the pipeline.

Example output:
```
tfBackendResourceGroup: 'rg-terraform-state'
tfBackendStorageAccount: 'sttfstate1234567'
tfBackendContainerName: 'tfstate'
tfBackendKey: 'banking-aks.tfstate'
```

---

### Step 2: Create Azure DevOps Project

1. Go to https://dev.azure.com
2. Click **"+ New project"**
3. Enter details:
   - **Name**: `Banking-AKS-Full-CICD`
   - **Visibility**: Private
   - **Version control**: Git
4. Click **"Create"**

---

### Step 3: Import Repository

#### Option A: Import from Git
1. Go to **Repos** → **Files**
2. Click **"Import"**
3. Upload or import your repository

#### Option B: Push from Local
```bash
cd banking-aks-complete-cicd

git init
git add .
git commit -m "Initial commit"

# Add remote
git remote add origin https://dev.azure.com/YOUR_ORG/Banking-AKS-Full-CICD/_git/banking-aks

# Push
git push -u origin main
```

---

### Step 4: Create Service Connection

This allows Azure DevOps to manage your Azure resources.

1. Go to **Project Settings** (bottom left)
2. Click **Service connections** (under Pipelines)
3. Click **"New service connection"**
4. Select **"Azure Resource Manager"**
5. Click **"Next"**

#### Configure Service Connection:
- **Authentication method**: Service principal (automatic)
- **Scope level**: Subscription
- **Subscription**: Select your subscription
- **Resource group**: Leave empty (or select `rg-terraform-state`)
- **Service connection name**: `Azure-ServiceConnection`
- ✅ Check **"Grant access permission to all pipelines"**
- Click **"Save"**

⚠️ **CRITICAL**: The name must be exactly `Azure-ServiceConnection`

---

### Step 5: Grant Service Principal Permissions

The service principal needs permissions to create resources.

```bash
# Get Service Principal ID
SP_ID=$(az ad sp list --display-name "Azure-ServiceConnection" --query "[0].id" -o tsv)

# Grant Contributor role at subscription level
az role assignment create \
  --assignee $SP_ID \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)

# Verify
az role assignment list --assignee $SP_ID --output table
```

---

### Step 6: Create Pipeline Environments

Environments provide deployment approvals and history.

#### Create Infrastructure Environment
1. Go to **Pipelines** → **Environments**
2. Click **"New environment"**
3. Configure:
   - **Name**: `banking-infrastructure`
   - **Description**: Infrastructure deployment
   - **Resource**: None
4. Click **"Create"**

#### Create Production Environment
1. Click **"New environment"** again
2. Configure:
   - **Name**: `banking-production`
   - **Description**: Production deployment
   - **Resource**: None
3. Click **"Create"**

#### Add Approval Gate (Recommended)
1. Click on `banking-production` environment
2. Click **"..."** → **"Approvals and checks"**
3. Click **"+"** → **"Approvals"**
4. Configure:
   - **Approvers**: Add yourself and team members
   - **Instructions**: "Review production deployment"
   - **Timeout**: 24 hours
5. Click **"Create"**

---

### Step 7: Update Pipeline Variables

Update the pipeline YAML with your Terraform backend configuration.

Edit `pipelines/azure-pipelines-full.yml`:

```yaml
variables:
  azureSubscription: 'Azure-ServiceConnection'
  
  # Update these with values from setup-terraform-backend.sh output
  tfBackendResourceGroup: 'rg-terraform-state'
  tfBackendStorageAccount: 'sttfstate1234567'  # YOUR STORAGE ACCOUNT
  tfBackendContainerName: 'tfstate'
  tfBackendKey: 'banking-aks.tfstate'
```

**OR** create a Variable Group:

1. Go to **Pipelines** → **Library**
2. Click **"+ Variable group"**
3. Name: `terraform-backend`
4. Add variables:
   - `tfBackendResourceGroup`
   - `tfBackendStorageAccount`
   - `tfBackendContainerName`
   - `tfBackendKey`
5. Link to pipeline (update YAML to reference variable group)

---

### Step 8: Create the Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **"New pipeline"**
3. **Connect**: Select **"Azure Repos Git"**
4. **Select**: Choose your repository
5. **Configure**: Select **"Existing Azure Pipelines YAML file"**
6. **Path**: Select `/pipelines/azure-pipelines-full.yml`
7. Click **"Continue"**
8. Review the pipeline
9. Click **"Save"** (don't run yet)

---

### Step 9: Run the Pipeline

Now you're ready to deploy everything!

1. Click **"Run pipeline"**
2. Select branch: `main`
3. Click **"Run"**

### What Happens:

```
Stage 1: Validate (2-3 min)
├─ Install Terraform
├─ Initialize backend
├─ Validate configuration
└─ Create plan

Stage 2: Deploy Infrastructure (10-15 min)
├─ Apply Terraform
├─ Create AKS cluster
├─ Create ACR
├─ Create VNet, App Gateway
├─ Create Key Vault
└─ Output configuration

Stage 3: Build Application (3-5 min)
├─ Login to ACR
├─ Build Docker image
├─ Push to ACR
└─ Publish manifests

Stage 4: Deploy Application (5-7 min)
├─ Get AKS credentials
├─ Update K8s manifests
├─ Deploy to Kubernetes
├─ Wait for pods
├─ Configure App Gateway
└─ Health checks

✅ COMPLETE! (~25-30 min total)
```

---

### Step 10: Monitor Deployment

Watch the pipeline execution in Azure DevOps:

1. Click on the running pipeline
2. Watch each stage complete
3. Click on stages/jobs to see logs
4. Wait for approvals (if configured)

---

### Step 11: Access Your Application

After successful deployment:

1. Go to the pipeline run
2. Look at the **Deployment Summary** in the logs
3. Find the Application Gateway IP
4. Open in browser: `http://<APP_GATEWAY_IP>`

**Login Credentials:**
- Customer ID: `5439090`
- Password: `Passw0rd!!`

---

## 🔄 Subsequent Deployments

After the initial setup, deployments are automatic:

```bash
# Make changes to code
git add .
git commit -m "Update application"
git push

# Pipeline automatically:
# 1. Validates changes
# 2. Updates infrastructure (if needed)
# 3. Builds new image
# 4. Deploys to AKS
```

---

## 🔧 Pipeline Features

### Automatic Triggers
- ✅ Push to `main` → Full deployment
- ✅ Push to `develop` → Dev deployment
- ✅ Pull Request → Validation only

### Smart Deployment
- ✅ Only applies Terraform if infrastructure changed
- ✅ Always builds new Docker image
- ✅ Rolling updates with zero downtime
- ✅ Automatic rollback on failure

### Security
- ✅ Terraform state encrypted in Azure Storage
- ✅ State locking prevents concurrent modifications
- ✅ Approval gates for production
- ✅ Secrets in Key Vault

---

## 📊 Pipeline Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `azureSubscription` | Service connection name | Azure-ServiceConnection |
| `tfBackendResourceGroup` | Terraform state RG | rg-terraform-state |
| `tfBackendStorageAccount` | Storage account name | sttfstate1234567 |
| `tfBackendContainerName` | Blob container | tfstate |
| `tfBackendKey` | State file name | banking-aks.tfstate |
| `imageName` | Docker image name | banking-app |
| `k8sNamespace` | Kubernetes namespace | banking |

---

## 🐛 Troubleshooting

### Issue: "Terraform Backend Does Not Exist"

**Solution**: Run the backend setup script
```bash
./setup-terraform-backend.sh
```

### Issue: "Service Connection Failed"

**Solution**: Verify service principal permissions
```bash
# Grant Contributor role
SP_ID=$(az ad sp list --display-name "Azure-ServiceConnection" --query "[0].id" -o tsv)
az role assignment create \
  --assignee $SP_ID \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)
```

### Issue: "AKS Deployment Failed"

**Solution**: Check if AKS cluster is ready
```bash
az aks show \
  --resource-group rg-banking-aks-prod \
  --name bankaks-aks \
  --query provisioningState
```

### Issue: "Pipeline Stuck at Approval"

**Solution**: 
1. Go to Pipelines → Environments
2. Click on `banking-production`
3. Review pending approvals
4. Approve or reject

### Issue: "Terraform State Locked"

**Solution**: Break the lease
```bash
az storage blob lease break \
  --container-name tfstate \
  --blob-name banking-aks.tfstate \
  --account-name <STORAGE_ACCOUNT>
```

---

## 🔐 Security Best Practices

### Service Connection Security
- ✅ Use service principal (not personal account)
- ✅ Limit scope to specific resource groups
- ✅ Rotate credentials regularly
- ✅ Use managed identities where possible

### Terraform State Security
- ✅ State stored in encrypted Azure Storage
- ✅ Enable versioning for rollback
- ✅ Restrict access with RBAC
- ✅ Enable soft delete

### Pipeline Security
- ✅ Require approvals for production
- ✅ Separate environments (dev/prod)
- ✅ Use variable groups for secrets
- ✅ Enable audit logging

---

## 📈 Advanced Configuration

### Multi-Region Deployment

Add another stage to deploy to a second region:

```yaml
- stage: DeployInfrastructure_WestUS
  displayName: 'Deploy Infrastructure - West US'
  dependsOn: []
  variables:
    tfBackendKey: 'banking-aks-westus.tfstate'
  # ... rest of configuration
```

### Blue-Green Deployment

Modify the deployment stage to use blue-green strategy:

```yaml
strategy:
  runOnce:
    preDeploy:
      steps:
      - script: # Create green environment
    deploy:
      steps:
      - script: # Deploy to green
    routeTraffic:
      steps:
      - script: # Switch traffic to green
    postRouteTraffic:
      steps:
      - script: # Verify green
```

### Automated Testing

Add a testing stage:

```yaml
- stage: Test
  displayName: 'Automated Tests'
  dependsOn: DeployApplication
  jobs:
  - job: IntegrationTests
    steps:
    - script: # Run tests
```

---

## 📊 Cost Monitoring

Monitor deployment costs:

```bash
# View costs for resource group
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --query "[?contains(instanceName, 'banking')]" \
  --output table
```

Set up cost alerts in Azure Portal:
1. Cost Management + Billing
2. Cost alerts
3. Create alert for resource group

---

## 🧹 Cleanup

### Delete Everything via Pipeline

1. Run the infrastructure pipeline with `destroy` action
2. Or manually:

```bash
cd terraform
terraform destroy -auto-approve
```

### Delete Terraform Backend

```bash
az group delete --name rg-terraform-state --yes --no-wait
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Terraform backend created
- [ ] Service connection working
- [ ] Pipeline runs successfully
- [ ] Infrastructure deployed (AKS, ACR, etc.)
- [ ] Application accessible via App Gateway
- [ ] Login works (5439090 / Passw0rd!!)
- [ ] All pods running (3 replicas)
- [ ] HPA configured
- [ ] Logs in Log Analytics
- [ ] Approval gates working (if enabled)

---

## 📞 Support

For issues:
1. Check pipeline logs in Azure DevOps
2. Verify Azure Portal for resource status
3. Check Terraform state in Storage Account
4. Review Kubernetes events: `kubectl get events -n banking`

---

## 🎉 Success!

You now have a **fully automated CI/CD pipeline** that deploys both infrastructure and application!

**Every code push triggers**:
- Infrastructure updates (if needed)
- New Docker image build
- Deployment to AKS
- Zero-downtime rolling update

**Total deployment time**: ~25-30 minutes (first run), ~5-10 minutes (subsequent runs)

---

**Ready to deploy? Run the pipeline and watch the magic happen!** 🚀
