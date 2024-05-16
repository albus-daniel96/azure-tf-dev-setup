#Importing the resource-group: 
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

#Creating log analytics workspace: 
resource "azurerm_log_analytics_workspace" "example" {
  name                = var.log_analytics_workspace_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}
