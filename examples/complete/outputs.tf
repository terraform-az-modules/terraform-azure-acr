output "container_registry_id" {
  value       = module.container-registry.container_registry_id
  description = "The ID of the Container Registry"
}

output "container_registry_private_endpoint" {
  value       = module.container-registry.container_registry_private_endpoint
  description = "The ID of the Azure Container Registry Private Endpoint"
}

output "container_registry_login_server" {
  value       = module.container-registry.container_registry_login_server
  description = "The URL that can be used to log into the Container Registry"
}

output "container_registry_admin_username" {
  value       = module.container-registry.container_registry_admin_username
  description = "The Username associated with the Container Registry Admin account"
}

output "container_registry_identity_principal_id" {
  value       = module.container-registry.container_registry_identity_principal_id
  description = "The Principal ID for the Service Principal associated with the Managed Service Identity of the Container Registry"
}

output "container_registry_identity_tenant_id" {
  value       = module.container-registry.container_registry_identity_tenant_id
  description = "The Tenant ID for the Service Principal associated with the Managed Service Identity of the Container Registry"
}

output "tags" {
  value       = module.container-registry.tags
  description = "A mapping of tags which should be assigned to the Container Registry."
}