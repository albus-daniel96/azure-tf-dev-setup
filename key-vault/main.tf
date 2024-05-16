#Importing Resource group
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

#Creating the key vault:
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "example" {
  name                = var.kv_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  sku_name            = "premium"
}

# resource "azurerm_key_vault_access_policy" "example" {
#   key_vault_id = azurerm_key_vault.example.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id
#   key_permissions = ["Get","Create"]
#   secret_permissions = ["Set","Get","Delete","Purge","Recover"]
# }
# 
# resource "azurerm_key_vault_secret" "example" {
#   name         = "Admin"
#   value        = "PeteDJ"
#   key_vault_id = azurerm_key_vault.example.id
# }
