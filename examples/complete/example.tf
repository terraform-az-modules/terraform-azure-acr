provider "azurerm" {
  features {}
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
  source               = "terraform-az-modules/subnet/azure"
  version              = "1.0.0"
  environment          = "dev"
  label_order          = ["name", "environment", "location"]
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name
  subnets = [
    {
      name            = "subnet1"
      subnet_prefixes = ["10.0.1.0/24"]
    }
  ]
}

# ------------------------------------------------------------------------------
# Log Analytics
# ------------------------------------------------------------------------------
module "log-analytics" {
  source                           = "terraform-az-modules/log-analytics/azure"
  version                          = "1.0.0"
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
  source                        = "terraform-az-modules/vault/azure"
  version                       = "1.0.0"
  name                          = "core"
  environment                   = "dev"
  label_order                   = ["name", "environment", "location"]
  resource_group_name           = module.resource_group.resource_group_name
  location                      = module.resource_group.resource_group_location
  subnet_id                     = module.subnet.subnet_ids.subnet1
  public_network_access_enabled = true
  sku_name                      = "premium"
  private_dns_zone_ids          = module.private_dns_zone.private_dns_zone_ids.key_vault
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["0.0.0.0/0"]
  }
  reader_objects_ids = {
    "Key Vault Administrator" = {
      role_definition_name = "Key Vault Administrator"
      principal_id         = data.azurerm_client_config.current_client_config.object_id
    }
  }
  diagnostic_setting_enable  = true
  log_analytics_workspace_id = module.log-analytics.workspace_id
}

# ------------------------------------------------------------------------------
# Private DNS Zone
# ------------------------------------------------------------------------------
module "private_dns_zone" {
  source              = "terraform-az-modules/private-dns-zone/azure"
  version             = "1.0.0"
  resource_group_name = module.resource_group.resource_group_name
  private_dns_config = [
    {
      resource_type = "container_registry"
      vnet_ids      = [module.vnet.vnet_id]
    },
    {
      resource_type = "key_vault"
      vnet_ids      = [module.vnet.vnet_id]
    }
  ]
}

# ------------------------------------------------------------------------------
# Azure Container Registry (ACR)
# ------------------------------------------------------------------------------
module "container-registry" {
  source                     = "../../"
  name                       = "core"
  environment                = "dev"
  label_order                = ["name", "environment", "location"]
  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  depends_on                 = [module.private_dns_zone]
  log_analytics_workspace_id = module.log-analytics.workspace_id
  subnet_id                  = module.subnet.subnet_ids.subnet1
  key_vault_id               = module.vault.id
  private_dns_zone_ids       = module.private_dns_zone.private_dns_zone_ids.container_registry
  logs = [
    {
      category = "ContainerRegistryLoginEvents"
    },
    {
      category = "ContainerRegistryRepositoryEvents"
    }
  ]
}