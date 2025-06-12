provider "azurerm" {
  features {}
}

##----------------------------------------------------------------------------- 
## ACR module call.
##-----------------------------------------------------------------------------
module "container-registry" {
  source              = "../../"
  name                = "core"
  environment         = "dev"
  label_order         = ["name", "environment", "location"]
  resource_group_name = "test"
  location            = "centralindia"
  ##----------------------------------------------------------------------------- 
  ## To be mentioned for private endpoint, because private endpoint is enabled by default.
  ## To disable private endpoint set 'enable_private_endpoint' variable = false and than no need to specify following variable  
  ##-----------------------------------------------------------------------------
  subnet_id = ""
}