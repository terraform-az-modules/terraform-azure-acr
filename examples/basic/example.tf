provider "azurerm" {
  features {}

}

provider "azurerm" {
  features {}
  alias = "peer"
}
##----------------------------------------------------------------------------- 
## ACR module call.
##-----------------------------------------------------------------------------
module "container-registry" {
  providers = {
    azurerm.dns_sub  = azurerm.peer,
    azurerm.main_sub = azurerm
  }
  source                  = "../../"
  name                    = "core"
  environment             = "dev"
  label_order             = ["name", "environment", "location"]
  resource_group_name     = "test"
  location                = "centralindia"
  enable_private_endpoint = false
  ##----------------------------------------------------------------------------- 
  ## To be mentioned for private endpoint, because private endpoint is enabled by default.
  ## To disable private endpoint set 'enable_private_endpoint' variable = false and than no need to specify following variable  
  ##-----------------------------------------------------------------------------
  subnet_id         = ""
  enable_diagnostic = false
}