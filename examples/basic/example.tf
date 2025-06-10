provider "azurerm" {
  features {}
  subscription_id = "1ac2caa4-336e-4daa-b8f1-0fbabe2d4b11"

}

provider "azurerm" {
  features {}
  subscription_id = "1ac2caa4-336e-4daa-b8f1-0fbabe2d4b11"
  alias           = "peer"
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