data "azurerm_resource_group" "rg_name" {
  name = var.rg_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg_name.name
}

resource "azurerm_network_interface" "example" {
  count = length(var.sku)
  name                = "${var.nic_name}${count.index}"
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_string" "password" {
  length           = 16
  special          = true
}

resource "azurerm_windows_virtual_machine" "example" {
  count = length(var.sku)
  name                = "${var.vm_name}${count.index}"
  resource_group_name = data.azurerm_resource_group.rg_name.name
  location            = data.azurerm_resource_group.rg_name.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = random_string.password.result
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.sku[count.index]
    version   = "latest"
  }
}
