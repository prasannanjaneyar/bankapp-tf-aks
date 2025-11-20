# Banking Application - Complete CI/CD with Infrastructure Deployment

**Full Azure DevOps CI/CD pipeline that deploys BOTH infrastructure and application automatically!**

## 🎯 What This Solution Provides

### Complete Automation
✅ **Infrastructure as Code** - Terraform deploys all Azure resources  
✅ **Application Build** - Automatic Docker image creation  
✅ **Kubernetes Deployment** - Auto-deploy to AKS  
✅ **Zero Configuration** - Push code, everything deploys  

### Single Pipeline Does Everything
```
Code Push → Terraform Apply → Build Image → Deploy to AKS → Live!
```

---

## 📦 What Gets Deployed

### Azure Infrastructure (via Terraform)
- **AKS Cluster** - 3 nodes with auto-scaling
- **Azure Container Registry** - Private Docker registry
- **Application Gateway** - WAF v2 with OWASP 3.2
- **Azure Key Vault** - Secure secret management
- **Virtual Network** - Private networking
- **Log Analytics** - SIEM logging

### Application (via Pipeline)
- **Docker Image** - Built and pushed to ACR
- **Kubernetes Deployment** - 3 replicas with HPA
- **Internal Load Balancer** - Private service
- **Network Policies** - Security rules
- **Auto-Scaling** - 3-10 pods based on load

### Banking Application Features
- **Personal Data Tab** - Account balance, customer info
- **Net Banking Tab** - Transfers, bills, transactions
- **Loan Application Tab** - Multiple loan types

---

## 🚀 Quick Start

### 1. Setup Terraform Backend (One-Time)
```bash
./setup-terraform-backend.sh
```

### 2. Configure Azure DevOps
```bash
# Follow SETUP_GUIDE.md for detailed steps
1. Create Azure DevOps project
2. Create service connection: Azure-ServiceConnection
3. Create environments: banking-infrastructure, banking-production
4. Import this repository
```

### 3. Create Pipeline
```bash
# In Azure DevOps
1. Pipelines → New pipeline
2. Select Azure Repos Git
3. Choose your repository
4. Select existing YAML: /pipelines/azure-pipelines-full.yml
5. Update backend variables
6. Run!
```

### 4. Watch It Deploy! 🎉
```
✅ Validate (2-3 min)
✅ Deploy Infrastructure (10-15 min)
✅ Build Application (3-5 min)
✅ Deploy to AKS (5-7 min)
───────────────────────────────
✅ Total: ~25-30 minutes
```

---

## 📁 Project Structure

```
banking-aks-complete-cicd/
│
├── pipelines/
│   ├── azure-pipelines-full.yml          # Main pipeline (infrastructure + app)
│   └── azure-pipelines-infrastructure.yml # Infrastructure only
│
├── terraform/
│   ├── main.tf                            # All infrastructure
│   ├── variables.tf                       # Configuration
│   └── outputs.tf                         # Export values
│
├── app/
│   ├── Dockerfile                         # Multi-stage build
│   ├── server.js                          # Node.js application
│   └── public/                            # HTML files
│
├── k8s/
│   ├── 00-namespace.yaml                  # Namespace
│   ├── 01-secret.yaml                     # Secrets
│   ├── 02-configmap.yaml                  # Config
│   ├── 03-deployment.yaml                 # Deployment
│   ├── 04-service.yaml                    # Service
│   ├── 05-hpa.yaml                        # Auto-scaling
│   └── 06-network-policy.yaml             # Network security
│
├── setup-terraform-backend.sh             # Backend setup script
├── SETUP_GUIDE.md                         # Detailed setup guide
└── README.md                              # This file
```

---

## 🔄 Pipeline Stages Explained

### Stage 1: Validate
- Installs Terraform
- Initializes backend
- Validates configuration
- Creates plan
- **Time**: 2-3 minutes

### Stage 2: Deploy Infrastructure
- Applies Terraform plan
- Creates all Azure resources
- Waits for AKS to be ready
- Exports configuration
- **Time**: 10-15 minutes

### Stage 3: Build Application
- Logs into ACR
- Builds Docker image
- Tags with build number
- Pushes to registry
- **Time**: 3-5 minutes

### Stage 4: Deploy Application
- Gets AKS credentials
- Updates K8s manifests
- Deploys all resources
- Configures App Gateway
- Runs health checks
- **Time**: 5-7 minutes

---

## 🔐 Access Information

### After Deployment

Get the Application Gateway IP from pipeline output:
```
http://<APP_GATEWAY_IP>
```

### Login Credentials
- **Customer ID**: `5439090`
- **Password**: `Passw0rd!!`

### Kubernetes Access
```bash
az aks get-credentials \
  --resource-group rg-banking-aks-prod \
  --name bankaks-aks
  
kubectl get all -n banking
```

---

## 🎨 Pipeline Features

### Automatic Triggers
```yaml
# Main branch → Production deployment
push to main → Full pipeline

# Develop branch → Dev deployment  
push to develop → Full pipeline

# Pull Request → Validation only
PR to main/develop → Validate stage only
```

### Smart Infrastructure Updates
- Only applies Terraform when infrastructure files change
- Skips infrastructure stage if no changes detected
- Always builds new application image
- Always deploys latest code

### Deployment Safety
- Approval gates for production
- Rollback on failure
- Health checks before completion
- Zero-downtime rolling updates

---

## 💰 Cost Estimate

Monthly costs for complete deployment:

| Resource | Cost/Month |
|----------|-----------|
| AKS (3 nodes D4s_v3) | ~$450 |
| Application Gateway WAF v2 | ~$300 |
| Container Registry Premium | ~$170 |
| Load Balancer | ~$20 |
| Log Analytics | ~$50 |
| Key Vault | ~$5 |
| **Total** | **~$995** |

💡 **Save costs**: Infrastructure can be destroyed when not in use

---

## 🔧 Configuration

### Update Pipeline Variables

Edit `pipelines/azure-pipelines-full.yml`:

```yaml
variables:
  azureSubscription: 'Azure-ServiceConnection'
  
  # Terraform Backend (from setup script output)
  tfBackendResourceGroup: 'rg-terraform-state'
  tfBackendStorageAccount: 'sttfstate1234567'
  tfBackendContainerName: 'tfstate'
  tfBackendKey: 'banking-aks.tfstate'
  
  # Application
  imageName: 'banking-app'
  k8sNamespace: 'banking'
```

### Customize Infrastructure

Edit `terraform/variables.tf`:

```hcl
variable "node_count" {
  default = 3  # Change cluster size
}

variable "vm_size" {
  default = "Standard_D4s_v3"  # Change VM size
}

variable "location" {
  default = "East US"  # Change region
}
```

---

## 📊 Monitoring

### View Logs
```bash
# Application logs
kubectl logs -f deployment/banking-app -n banking

# Pipeline logs
# Azure DevOps → Pipelines → Select run → View logs
```

### Check Status
```bash
# Infrastructure
az resource list --resource-group rg-banking-aks-prod --output table

# Kubernetes
kubectl get all -n banking
kubectl get hpa -n banking
```

### Azure Monitor
1. Go to Azure Portal
2. Navigate to Log Analytics Workspace
3. Run queries:

```kusto
// Application logs
ContainerLog
| where Namespace == "banking"
| order by TimeGenerated desc

// Pod status
KubePodInventory
| where Namespace == "banking"
| summarize by ContainerStatus
```

---

## 🐛 Troubleshooting

### Backend Setup Issues
```bash
# Verify backend exists
az storage account show --name <STORAGE_ACCOUNT> --resource-group rg-terraform-state

# Recreate if needed
./setup-terraform-backend.sh
```

### Service Connection Issues
```bash
# Verify service principal
SP_ID=$(az ad sp list --display-name "Azure-ServiceConnection" --query "[0].id" -o tsv)

# Grant permissions
az role assignment create \
  --assignee $SP_ID \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)
```

### Pipeline Failures
1. Check stage logs in Azure DevOps
2. Verify Terraform state in storage account
3. Check Azure resource status in portal
4. Review Kubernetes events: `kubectl get events -n banking`

### Application Not Accessible
```bash
# Check pods
kubectl get pods -n banking

# Check service
kubectl get svc banking-app-service -n banking

# Check App Gateway
az network application-gateway show \
  --resource-group rg-banking-aks-prod \
  --name bankaks-appgw
```

---

## 🔄 Common Operations

### Trigger Deployment
```bash
# Make changes
git add .
git commit -m "Update application"
git push

# Pipeline automatically runs
```

### Manual Pipeline Run
1. Azure DevOps → Pipelines
2. Select pipeline
3. Click "Run pipeline"
4. Select branch
5. Click "Run"

### Rollback Deployment
```bash
# In Kubernetes
kubectl rollout undo deployment/banking-app -n banking

# Or redeploy previous build via pipeline
# Select previous successful run → "Rerun"
```

### Update Infrastructure Only
```bash
# Use infrastructure-only pipeline
# Pipelines → Select azure-pipelines-infrastructure.yml
# Run with parameter: apply
```

### Destroy Everything
```bash
# Via pipeline
# Run infrastructure pipeline with parameter: destroy

# Or manually
cd terraform
terraform destroy -auto-approve
```

---

## 📚 Documentation

- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Complete step-by-step setup
- **[Pipeline YAML](./pipelines/azure-pipelines-full.yml)** - Full pipeline configuration
- **[Terraform Configuration](./terraform/)** - Infrastructure code

---

## 🎓 What You'll Learn

By implementing this solution:

✅ Azure DevOps pipeline creation  
✅ Terraform backend configuration  
✅ Infrastructure as Code with Terraform  
✅ Azure Kubernetes Service (AKS)  
✅ Container Registry integration  
✅ Docker multi-stage builds  
✅ Kubernetes deployments and services  
✅ Auto-scaling with HPA  
✅ Application Gateway configuration  
✅ CI/CD best practices  

---

## 🔒 Security Features

### Infrastructure Security
- ✅ Terraform state encrypted in Azure Storage
- ✅ Service principal with least privilege
- ✅ Network isolation with VNet
- ✅ Application Gateway WAF (OWASP 3.2)
- ✅ Key Vault for secrets

### Application Security
- ✅ Container scanning (ACR)
- ✅ Non-root containers
- ✅ Network policies in Kubernetes
- ✅ RBAC enabled
- ✅ Secrets encrypted at rest

### Pipeline Security
- ✅ Approval gates for production
- ✅ Separate environments
- ✅ Audit logging enabled
- ✅ No hardcoded secrets

---

## ✅ Success Criteria

After deployment, you should have:

- [x] Pipeline running successfully
- [x] All Azure resources created
- [x] AKS cluster with 3 nodes
- [x] Application accessible via App Gateway
- [x] 3 pods running in banking namespace
- [x] Auto-scaling configured (HPA)
- [x] Logs flowing to Log Analytics
- [x] Login working (5439090 / Passw0rd!!)

---

## 🎉 Benefits

### Automation
- ✅ Push code → Everything deploys
- ✅ No manual steps required
- ✅ Consistent deployments

### Reliability
- ✅ Infrastructure versioned in Git
- ✅ Terraform state managed
- ✅ Automatic rollback on failure

### Scalability
- ✅ Auto-scaling pods (3-10)
- ✅ Auto-scaling nodes (2-5)
- ✅ Load balancing included

### Security
- ✅ Approval gates
- ✅ Secrets in Key Vault
- ✅ Network isolation
- ✅ WAF protection

---

## 🚀 Next Steps

1. **Review** the SETUP_GUIDE.md
2. **Run** ./setup-terraform-backend.sh
3. **Configure** Azure DevOps
4. **Deploy** via pipeline
5. **Enjoy** your automated infrastructure!

---

## 📞 Support

For issues or questions:
1. Check SETUP_GUIDE.md for detailed instructions
2. Review pipeline logs in Azure DevOps
3. Check Azure Portal for resource status
4. Review Kubernetes events

---

**Complete CI/CD automation for Azure infrastructure and applications!** 🏦🚀

Everything you need to deploy infrastructure and application via Azure DevOps pipelines!
