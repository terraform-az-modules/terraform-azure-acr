##----------------------------------------------------------------------------- 
## Locals
##-----------------------------------------------------------------------------
locals {
  valid_rg_name = var.enable_private_endpoint ? var.existing_private_dns_zone == null ? var.resource_group_name : var.existing_private_dns_zone_resource_group_name : null
  name          = var.custom_name != null ? var.custom_name : module.labels.id
}