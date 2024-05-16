output "id" {
  description = "Details of resource group:"
  value = data.azurerm_resource_group.rg.id
}
output "rg_name" {
  description = "Details of resource group:"
  value = data.azurerm_resource_group.rg.name
}
