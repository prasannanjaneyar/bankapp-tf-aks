output "resource_group_name" {
  description = "Resource Group Name"
  value       = azurerm_resource_group.banking.name
}

output "aks_cluster_name" {
  description = "AKS Cluster Name"
  value       = azurerm_kubernetes_cluster.banking.name
}

output "aks_cluster_id" {
  description = "AKS Cluster ID"
  value       = azurerm_kubernetes_cluster.banking.id
}

output "acr_name" {
  description = "Azure Container Registry Name"
  value       = azurerm_container_registry.banking.name
}

output "acr_login_server" {
  description = "Azure Container Registry Login Server"
  value       = azurerm_container_registry.banking.login_server
}

output "acr_admin_username" {
  description = "Azure Container Registry Admin Username"
  value       = azurerm_container_registry.banking.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Azure Container Registry Admin Password"
  value       = azurerm_container_registry.banking.admin_password
  sensitive   = true
}

output "key_vault_name" {
  description = "Key Vault Name"
  value       = azurerm_key_vault.banking.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.banking.vault_uri
}

output "application_gateway_public_ip" {
  description = "Application Gateway Public IP"
  value       = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_url" {
  description = "Application Gateway URL"
  value       = "http://${azurerm_public_ip.appgw.ip_address}"
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (SIEM)"
  value       = azurerm_log_analytics_workspace.banking.id
}

output "get_aks_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.banking.name} --name ${azurerm_kubernetes_cluster.banking.name}"
}

output "login_credentials" {
  description = "Login credentials for testing"
  value = {
    customer_id = "5439090"
    password    = "Passw0rd!!"
  }
}
