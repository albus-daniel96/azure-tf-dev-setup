#Importing resouce group:
data "azurerm_resource_group" "rg" {
  name = "TWD"
}

#Deploying a new virtual network:
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "example" {
  name                = var.network_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  dynamic "subnet" {
    iterator = rule 
    for_each = var.subnet_name_address
    content {
    name           = rule.value.name          
    address_prefix = rule.value.address_prefix
    } 
  }

  tags = var.network_tags
}
