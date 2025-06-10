##-----------------------------------------------------------------------------
## Azure Container Registry
##-----------------------------------------------------------------------------

output "container_registry_id" {
  value       = azurerm_container_registry.main[0].id
  description = "The ID of the newly created Container Registry."
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.main[0].login_server
  description = "The login server URL of the newly created Container Registry."
}

output "container_registry_admin_username" {
  value       = var.admin_enabled ? azurerm_container_registry.main[0].admin_username : null
  description = "The admin username of the newly created Container Registry, if admin access is enabled."
}

output "container_registry_admin_password" {
  value       = var.admin_enabled ? azurerm_container_registry.main[0].admin_password : null
  sensitive   = true
  description = "The admin password of the newly created Container Registry, if admin access is enabled."
}

##-----------------------------------------------------------------------------
## Managed Identity
##-----------------------------------------------------------------------------

output "container_registry_identity_principal_id" {
  value       = azurerm_container_registry.main[0].identity[0].principal_id
  description = "The Principal ID of the Managed Service Identity assigned to the newly created Container Registry."
}

output "container_registry_identity_tenant_id" {
  value       = azurerm_container_registry.main[0].identity[0].tenant_id
  description = "The Tenant ID of the Managed Service Identity assigned to the newly created Container Registry."
}

##-----------------------------------------------------------------------------
## Scope Map & Token (Premium SKU)
##-----------------------------------------------------------------------------

output "container_registry_scope_map_id" {
  value       = var.scope_map != null ? [for k in azurerm_container_registry_scope_map.main : k.id] : null
  description = "List of IDs for the newly created Container Registry scope maps (Premium SKU only)."
}

output "container_registry_token_id" {
  value       = var.scope_map != null ? [for k in azurerm_container_registry_token.main : k.id] : null
  description = "List of IDs for the newly created Container Registry tokens (Premium SKU only)."
}

##-----------------------------------------------------------------------------
## Webhook
##-----------------------------------------------------------------------------

output "container_registry_webhook_id" {
  value       = var.container_registry_webhooks != null ? [for k in azurerm_container_registry_webhook.main : k.id] : null
  description = "List of IDs for the newly created Container Registry webhooks."
}

##-----------------------------------------------------------------------------
## Private Endpoint & DNS
##-----------------------------------------------------------------------------

output "container_registry_private_endpoint" {
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.pep1[0].id : null
  description = "The ID of the newly created Azure Container Registry Private Endpoint, if enabled."
}

##-----------------------------------------------------------------------------
## Key Vault Integration
##-----------------------------------------------------------------------------

output "key_vault_key_id" {
  value       = var.encryption ? azurerm_key_vault_key.kvkey[0].id : null
  description = "The ID of the newly created Key Vault Key used for ACR encryption."
}

output "user_assigned_identity_id" {
  value       = var.encryption ? azurerm_user_assigned_identity.identity[0].id : null
  description = "The ID of the newly created User Assigned Identity for ACR encryption."
}

output "user_assigned_identity_principal_id" {
  value       = var.encryption ? azurerm_user_assigned_identity.identity[0].principal_id : null
  description = "The Principal ID of the newly created User Assigned Identity for ACR encryption."
}

##-----------------------------------------------------------------------------
## Diagnostic Settings 
##-----------------------------------------------------------------------------

output "diagnostic_setting_id" {
  value       = var.enable_diagnostic ? azurerm_monitor_diagnostic_setting.acr-diag[0].id : null
  description = "The ID of the newly created Diagnostic Setting for the Container Registry."
}

##-----------------------------------------------------------------------------
## Tags  
##-----------------------------------------------------------------------------
output "tags" {
  value       = try(module.labels.tags, null)
  description = "A mapping of tags which should be assigned to the Container Registry."

}