variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-banking-aks-prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "bankaks"
}

variable "node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"  # 2 vCPU, 8 GB RAM (was D4s_v3 = 4 vCPU)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Application = "Banking"
    ManagedBy   = "Terraform"
    Compliance  = "PCI-DSS"
  }
}
