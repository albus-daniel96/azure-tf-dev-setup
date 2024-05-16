data "azurerm_resource_group" "rg_name" {
  name = var.data_rg_name
}
resource "azurerm_storage_account" "stg_account" {
  name                     = var.stg_name
  resource_group_name      = data.azurerm_resource_group.rg_name.name
  location                 = data.azurerm_resource_group.rg_name.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = var.stg_tags
}
