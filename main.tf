##-----------------------------------------------------------------------------
# Standard Tagging Module – Applies standard tags to all resources for traceability
##-----------------------------------------------------------------------------
module "labels" {
  source          = "terraform-az-modules/tags/azure"
  version         = "1.0.0"
  name            = var.custom_name == null ? var.name : var.custom_name
  location        = var.location
  environment     = var.environment
  managedby       = var.managedby
  label_order     = var.label_order
  repository      = var.repository
  deployment_mode = var.deployment_mode
  extra_tags      = var.extra_tags
}

##-----------------------------------------------------------------------------
## Azure Container Registry - Deploy secure container image registry service
##-----------------------------------------------------------------------------

resource "azurerm_container_registry" "main" {
  count                         = var.enabled ? 1 : 0
  name                          = replace(var.resource_position_prefix ? format("acr-%s", local.name) : format("%s-acr", local.name), "-", "")
  resource_group_name           = var.resource_group_name
  location                      = var.location
  admin_enabled                 = var.admin_enabled
  sku                           = var.container_registry_config.sku
  public_network_access_enabled = var.public_network_access_enabled
  quarantine_policy_enabled     = var.container_registry_config.quarantine_policy_enabled
  zone_redundancy_enabled       = var.container_registry_config.zone_redundancy_enabled
  tags                          = module.labels.tags
  network_rule_bypass_option    = var.azure_services_bypass

  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = merge({ "Name" = format("%s", "georep-${georeplications.value.location}") }, module.labels.tags, )
    }
  }

  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = lookup(network_rule_set.value, "default_action", "Allow")

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rule
        content {
          action   = "Allow"
          ip_range = ip_rule.value.ip_range
        }
      }

    }
  }

  trust_policy_enabled     = var.container_registry_config.sku == "Premium" ? var.enable_content_trust : false
  retention_policy_in_days = var.retention_policy_in_days != null && var.container_registry_config.sku == "Premium" ? var.retention_policy_in_days : null

  identity {
    type         = var.identity_ids != null || var.encryption ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.encryption ? [azurerm_user_assigned_identity.identity[0].id] : var.identity_ids
  }

  dynamic "encryption" {
    for_each = var.encryption && var.container_registry_config.sku == "Premium" ? ["encryption"] : []
    content {
      key_vault_key_id   = azurerm_key_vault_key.kvkey[0].id
      identity_client_id = azurerm_user_assigned_identity.identity[0].client_id
    }
  }
}

##-----------------------------------------------------------------------------
## Scope Map - Deploy token scopes for ACR access control
##-----------------------------------------------------------------------------

resource "azurerm_container_registry_scope_map" "main" {
  for_each                = var.enabled && var.scope_map != null ? { for k, v in var.scope_map : k => v if v != null } : {}
  name                    = format("%s", each.key)
  resource_group_name     = var.resource_group_name
  container_registry_name = azurerm_container_registry.main[0].name
  actions                 = each.value["actions"]
}

##-----------------------------------------------------------------------------
## Registry Token - Deploy tokens for ACR authentication
##-----------------------------------------------------------------------------

resource "azurerm_container_registry_token" "main" {
  for_each                = var.enabled && var.scope_map != null ? { for k, v in var.scope_map : k => v if v != null } : {}
  name                    = format("%s", "${each.key}-token")
  resource_group_name     = var.resource_group_name
  container_registry_name = azurerm_container_registry.main[0].name
  scope_map_id            = element([for k in azurerm_container_registry_scope_map.main : k.id], 0)
  enabled                 = true
}

##-----------------------------------------------------------------------------
## Registry Webhook - Deploy webhooks for container events
##-----------------------------------------------------------------------------
resource "azurerm_container_registry_webhook" "main" {
  for_each            = var.enabled && var.container_registry_webhooks != null ? { for k, v in var.container_registry_webhooks : k => v if v != null } : {}
  name                = format("%s", each.key)
  resource_group_name = var.resource_group_name
  location            = var.location
  registry_name       = azurerm_container_registry.main[0].name
  service_uri         = each.value["service_uri"]
  actions             = each.value["actions"]
  status              = each.value["status"]
  scope               = each.value["scope"]
  custom_headers      = each.value["custom_headers"]
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

##-----------------------------------------------------------------------------
## Key Vault Key - Deploy encryption key for ACR content
##-----------------------------------------------------------------------------
resource "azurerm_key_vault_key" "kvkey" {
  depends_on      = [azurerm_role_assignment.identity_assigned]
  count           = var.enabled && var.encryption ? 1 : 0
  name            = var.resource_position_prefix ? format("cmk-key-acr-%s", local.name) : format("%s-cmk-key-acr", local.name)
  key_vault_id    = var.key_vault_id
  key_type        = "RSA"
  key_size        = 2048
  expiration_date = var.key_expiration_date
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  dynamic "rotation_policy" {
    for_each = var.enable_rotation_policy ? [1] : []
    content {
      automatic {
        time_before_expiry = "P30D"
      }

      expire_after         = "P90D"
      notify_before_expiry = "P29D"
    }
  }
}

##-----------------------------------------------------------------------------
## Managed Identity - Deploy user-assigned identity for ACR encryption
##-----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "identity" {
  count               = var.enabled && var.encryption != null ? 1 : 0
  location            = var.location
  name                = var.resource_position_prefix ? format("mid-acr-%s", local.name) : format("%s-mid-acr", local.name)
  resource_group_name = var.resource_group_name
}

#-----------------------------------------------------------------------------
## Private Endpoint - Deploy private network access to ACR
##-----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "pep1" {
  count                         = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                          = var.resource_position_prefix ? format("pe-acr-%s", local.name) : format("%s-pe-acr", local.name)
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.subnet_id
  custom_network_interface_name = var.resource_position_prefix ? format("pe-nic-acr-%s", local.name) : format("%s-pe-nic-acr", local.name)
  private_dns_zone_group {
    name                 = var.resource_position_prefix ? format("dns-zone-group-acr-%s", local.name) : format("%s-dns-zone-group-acr", local.name)
    private_dns_zone_ids = var.private_dns_zone_id
  }
  private_service_connection {
    name                           = var.resource_position_prefix ? format("psc-acr-%s", local.name) : format("%s-psc-acr", local.name)
    is_manual_connection           = var.manual_connection
    private_connection_resource_id = azurerm_container_registry.main[0].id
    subresource_names              = ["registry"]
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

##-----------------------------------------------------------------------------
## Diagnostic Setting - Deploy monitoring and logging for ACR
##-----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "acr-diag" {
  count                      = var.enabled && var.enable_diagnostic ? 1 : 0
  name                       = var.resource_position_prefix ? format("nic-diag-log-acr-%s", local.name) : format("%s-nic-diag-log-acr", local.name)
  target_resource_id         = azurerm_container_registry.main[0].id
  storage_account_id         = var.storage_account_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.logs
    content {
      category_group = lookup(enabled_log.value, "category_group", null)
      category       = lookup(enabled_log.value, "category", null)
    }
  }
  dynamic "metric" {
    for_each = var.metrics
    content {
      category = lookup(metric.value, "category", null)
      enabled  = lookup(metric.value, "enabled", true)
    }
  }
  lifecycle {
    ignore_changes = [enabled_log, metric]
  }
}