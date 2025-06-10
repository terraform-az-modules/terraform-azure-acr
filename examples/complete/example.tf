provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias = "peer"
}

data "azurerm_client_config" "current_client_config" {}

locals {
  name        = "app"
  environment = "test"
}

##-----------------------------------------------------------------------------
## Resource Group module call
## Resource group in which all resources will be deployed.
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "terraform-az-modules/resource-group/azure"
  version     = "1.0.0"
  name        = "core"
  environment = "dev"
  location    = "centralus"
  label_order = ["name", "environment", "location"]
}

# ------------------------------------------------------------------------------
# Virtual Network
# ------------------------------------------------------------------------------
module "vnet" {
  source              = "terraform-az-modules/vnet/azure"
  version             = "1.0.0"
  name                = "core"
  environment         = "dev"
  label_order         = ["name", "environment", "location"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.0.0.0/16"]
}
# ------------------------------------------------------------------------------
# Subnet
# ------------------------------------------------------------------------------
module "subnet" {
  source               = "clouddrove/subnet/azure"
  version              = "1.2.1"
  name                 = local.name
  environment          = local.environment
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name
  subnet_names         = ["subnet1"]
  subnet_prefixes      = ["10.0.0.0/24"]
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

# ------------------------------------------------------------------------------
# Log Analytics
# ------------------------------------------------------------------------------
module "log-analytics" {
  source                           = "clouddrove/log-analytics/azure"
  version                          = "1.1.0"
  name                             = local.name
  environment                      = local.environment
  create_log_analytics_workspace   = true
  log_analytics_workspace_sku      = "PerGB2018"
  log_analytics_workspace_id       = module.log-analytics.workspace_id
  resource_group_name              = module.resource_group.resource_group_name
  log_analytics_workspace_location = module.resource_group.resource_group_location
}

# ------------------------------------------------------------------------------
# Key Vault
# ------------------------------------------------------------------------------
module "vault" {
  source = "git@github.com:clouddrove/terraform-azure-key-vault.git?ref=master"

  providers = {
    azurerm.dns_sub  = azurerm.peer
    azurerm.main_sub = azurerm
  }

  name                          = "apptests9977"
  environment                   = local.environment
  resource_group_name           = module.resource_group.resource_group_name
  location                      = module.resource_group.resource_group_location
  virtual_network_id            = module.vnet.vnet_id
  subnet_id                     = module.subnet.default_subnet_id[0]
  public_network_access_enabled = true
  sku_name                      = "premium"

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["0.0.0.0/0"]
  }

  enable_rbac_authorization  = true
  reader_objects_ids         = [data.azurerm_client_config.current_client_config.object_id]
  admin_objects_ids          = [data.azurerm_client_config.current_client_config.object_id]
  diagnostic_setting_enable  = true
  log_analytics_workspace_id = module.log-analytics.workspace_id
}

# ------------------------------------------------------------------------------
# Private DNS Zone
# ------------------------------------------------------------------------------
module "private_dns_zone" {
  source              = "git::https://github.com/ravimalvia10/private-dns-zone.git?ref=feat/private-dns-zone"
  resource_group_name = module.resource_group.resource_group_name
  private_dns_config = [
    {
      resource_type = "container_registry"
      vnet_ids      = [module.vnet.vnet_id]
    }
  ]
}

# ------------------------------------------------------------------------------
# Azure Container Registry (ACR)
# ------------------------------------------------------------------------------
module "container-registry" {
  source = "../../"
  providers = {
    azurerm.dns_sub  = azurerm.peer
    azurerm.main_sub = azurerm
  }
  name                        = "core"
  environment                 = "dev"
  label_order                 = ["name", "environment", "location"]
  resource_group_name         = module.resource_group.resource_group_name
  location                    = module.resource_group.resource_group_location
  depends_on                  = [module.private_dns_zone]
  log_analytics_workspace_id  = module.log-analytics.workspace_id
  subnet_id                   = module.subnet.default_subnet_id[0]
  encryption                  = true
  enable_content_trust        = true
  key_vault_rbac_auth_enabled = true
  key_vault_id                = module.vault.id
  enable_diagnostic           = true
  private_dns_zone_ids        = module.private_dns_zone.private_dns_zone_ids.container_registry
  logs = [
    {
      category = "ContainerRegistryLoginEvents"
    },
    {
      category = "ContainerRegistryRepositoryEvents"
    }
  ]
  metrics = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
  container_registry_config = {
    sku                       = "Premium"
    quarantine_policy_enabled = true
    zone_redundancy_enabled   = true
  }
  container_registry_webhooks = {
    webhook1 = {
      service_uri = "https://example.com/api/webhook"
      actions     = ["push", "delete"]
      status      = "enabled"
      scope       = "core:*"
      custom_headers = {
        Authorization = "Bearer exampletoken"
        X-Custom-Id   = "webhook-123"
      }
    }
  }
}
