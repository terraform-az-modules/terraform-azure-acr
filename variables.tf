##-----------------------------------------------------------------------------
## Naming convention
##-----------------------------------------------------------------------------
variable "custom_name" {
  type        = string
  default     = null
  description = "Override default naming convention"
}

variable "resource_position_prefix" {
  type        = bool
  default     = true
  description = <<EOT
Controls the placement of the resource type keyword (e.g., "vnet", "ddospp") in the resource name.

- If true, the keyword is prepended: "vnet-core-dev".
- If false, the keyword is appended: "core-dev-vnet".

This helps maintain naming consistency based on organizational preferences.
EOT
}

##-----------------------------------------------------------------------------
## Labels
##-----------------------------------------------------------------------------
variable "name" {
  type        = string
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "managedby" {
  type        = string
  default     = "terraform-az-modules"
  description = "ManagedBy, eg 'terraform-az-modules'."
}

variable "extra_tags" {
  type        = map(string)
  default     = null
  description = "Variable to pass extra tags."
}

variable "repository" {
  type        = string
  default     = "https://github.com/terraform-az-modules/terraform-azure-acr"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "location" {
  type        = string
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "Specifies how the infrastructure/resource is deployed"
}

variable "label_order" {
  type        = list(any)
  default     = ["name", "environment", "location"]
  description = "The order of labels used to construct resource names or tags. If not specified, defaults to ['name', 'environment', 'location']."
}

##-----------------------------------------------------------------------------
## Global Variables
##-----------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the network security group."
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

###-----------------------------------------------------------------------------
## Azure Container Registry (ACR)
##-----------------------------------------------------------------------------

variable "container_registry_config" {
  type = object({
    sku                       = optional(string)
    quarantine_policy_enabled = optional(bool)
    zone_redundancy_enabled   = optional(bool)
  })
  description = "Configuration for Azure Container Registry."
  default = {
    sku                       = "Premium"
    quarantine_policy_enabled = true
    zone_redundancy_enabled   = true
  }
}

variable "admin_enabled" {
  type        = bool
  default     = false
  description = "Enable or disable admin access to the ACR."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Allow or deny public network access to the ACR."
}

variable "retention_policy_in_days" {
  type        = number
  default     = 5
  description = "Retention period (in days) for untagged manifests in ACR."
}

variable "enable_content_trust" {
  type        = bool
  default     = false
  description = "Enable or disable content trust in ACR."
}

variable "scope_map" {
  type = map(object({
    actions = list(string)
  }))
  default     = null
  description = "Scope maps for ACR (Premium SKU only)."
}

variable "container_registry_webhooks" {
  type = map(object({
    service_uri    = string
    actions        = list(string)
    status         = optional(string)
    scope          = string
    custom_headers = map(string)
  }))
  default = {
    webhook = {
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
  description = "Webhooks configuration for ACR."
}


variable "georeplications" {
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool)
  }))
  default     = []
  description = "List of Azure regions for ACR geo-replication."
}

variable "encryption" {
  type        = bool
  default     = true
  description = "Enable or disable encryption for ACR."
}

variable "identity_ids" {
  type        = list(string)
  default     = null
  description = "List of user managed identity IDs for ACR."
}

variable "manual_connection" {
  description = "Indicates whether the connection is manual"
  type        = bool
  default     = false
}

variable "enable_data_endpoint" {
  type        = bool
  default     = true
  description = "Enable data endpoint for the container registry."
}

##-----------------------------------------------------------------------------
## Network & Security
##-----------------------------------------------------------------------------

variable "network_rule_set" {
  type = object({
    default_action = optional(string)
    ip_rule = optional(list(object({
      ip_range = string
    })))
    virtual_network = optional(list(object({
      subnet_id = string
    })))
  })
  default     = null
  description = "Network rules for ACR."
}

variable "azure_services_bypass" {
  type        = string
  default     = "AzureServices"
  description = "Allow trusted Azure services to access a network-restricted ACR. Possible values: None, AzureServices."
}

##-----------------------------------------------------------------------------
## Private Endpoint & DNS
##-----------------------------------------------------------------------------

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Enable private endpoint for ACR."
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "Subnet ID for the private endpoint."
}

variable "private_dns_zone_ids" {
  type        = string
  default     = null
  description = "The ID of the private DNS zone."
}
##-----------------------------------------------------------------------------
## Diagnostic Settings & Monitoring
##-----------------------------------------------------------------------------

variable "enable_diagnostic" {
  type        = bool
  default     = true
  description = "Enable diagnostic settings for ACR."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log Analytics Workspace ID for diagnostics."
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "Storage account ID for diagnostic settings destination."
}

variable "metric_enabled" {
  type        = bool
  default     = true
  description = "Boolean flag to specify whether Metrics should be enabled for the Container Registry. Defaults to true."
}

variable "logs" {
  type = list(object({
    category_group = optional(string)
    category       = optional(string)
  }))
  default     = []
  description = "List of log configurations for diagnostic settings. Each object can specify either category_group or category."
}

##-----------------------------------------------------------------------------
## Key Vault
##-----------------------------------------------------------------------------
variable "key_vault_id" {
  type        = string
  default     = null
  description = "Azure Key Vault ID for integration."
}

variable "rotation_policy_config" {
  type = object({
    enabled              = bool
    time_before_expiry   = optional(string, "P30D")
    expire_after         = optional(string, "P90D")
    notify_before_expiry = optional(string, "P29D")
  })
  default = {
    enabled              = false
    time_before_expiry   = "P30D"
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  description = "Rotation policy configuration for Key Vault keys."
}

variable "key_permissions" {
  type        = list(string)
  default     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  description = "List of key permissions for the Key Vault key."
}


variable "key_vault_rbac_auth_enabled" {
  type        = bool
  default     = true
  description = "Enable RBAC authentication for Key Vault."
}

variable "key_expiration_date" {
  description = "The expiration date for the Key Vault key"
  type        = string
  default     = "2028-12-31T23:59:59Z" # ISO 8601 format
}

variable "key_type" {
  description = "The type of the key to create in Key Vault."
  type        = string
  default     = "RSA-HSM"
}

variable "key_size" {
  description = "The size of the RSA key in bits."
  type        = number
  default     = 2048
}