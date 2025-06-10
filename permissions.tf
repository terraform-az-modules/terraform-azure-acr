##-----------------------------------------------------------------------------
## Permissions, Roles, and Policies
##-----------------------------------------------------------------------------
resource "azurerm_role_assignment" "identity_assigned" {
  provider             = azurerm.main_sub
  depends_on           = [azurerm_user_assigned_identity.identity]
  count                = var.enabled && var.encryption && var.key_vault_rbac_auth_enabled ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.identity[0].principal_id
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
}