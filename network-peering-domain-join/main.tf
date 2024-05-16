# RESOURCE GROUP
resource "azurerm_resource_group" "rg_group" {
  name     = var.rg_name
  location = var.rg_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg_group.location
  resource_group_name = azurerm_resource_group.rg_group.name
  dns_servers         = var.vnet_DNS
}

resource "azurerm_subnet" "vnet_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_space
}

# Creating NSG: 
resource "azurerm_network_security_group" "nsg" {
  name                = "SHIP-ROCK-NSG"
  location            = azurerm_resource_group.rg_group.location
  resource_group_name = azurerm_resource_group.rg_group.name
}

# Associating nsg to vnet
resource "azurerm_subnet_network_security_group_association" "connect_nsg" {
  subnet_id                 = azurerm_subnet.vnet_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Importing DNS network. 
data "azurerm_virtual_network" "domain_vnet" {
  name                = "DOMAIN-VNET"
  resource_group_name = "DOMAIN-RG"
}

# Peering vnet to domain
resource "azurerm_virtual_network_peering" "peering_to_domain" {
  name                         = "${var.vnet_name}-TO-DOMAIN-VNET"
  resource_group_name          = azurerm_resource_group.rg_group.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.domain_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# Peering domain to vnet
resource "azurerm_virtual_network_peering" "peering_from_domain" {
  name                         = "DOMAIN-VNET-TO-${var.vnet_name}"
  resource_group_name          = data.azurerm_virtual_network.domain_vnet.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.domain_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}


resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-NIC"
  location            = azurerm_resource_group.rg_group.location
  resource_group_name = azurerm_resource_group.rg_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnet_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "win_vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg_group.name
  location            = azurerm_resource_group.rg_group.location
  size                = var.vm_size
  computer_name       = "SHIP-ROCK"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.vm_sku
    version   = "latest"
  }
}

# Importing Log Analytics workspace:
data "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "west-us-logging"
  resource_group_name = "cloud-shell-storage-centralindia"
}

locals {
  log_ws_id  = data.azurerm_log_analytics_workspace.log_workspace.workspace_id
  log_ws_key = data.azurerm_log_analytics_workspace.log_workspace.primary_shared_key
}

resource "azurerm_virtual_machine_extension" "mmaagent" {
  name                       = "mmaagent"
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
  settings                   = <<SETTINGS
    {
      "workspaceId": "${local.log_ws_id}"
    }
SETTINGS
  protected_settings         = <<PROTECTED_SETTINGS
   {
      "workspaceKey": "${local.log_ws_key}"
   }
PROTECTED_SETTINGS

  depends_on = [azurerm_windows_virtual_machine.win_vm]
}

# Action Group: 
resource "azurerm_monitor_action_group" "CloudAlert" {
  name                = "CriticalAlertsAction"
  resource_group_name = azurerm_resource_group.rg_group.name
  short_name          = "p0action"

  email_receiver {
    name                    = "CloudOpsTeam"
    email_address           = "petejax123@gmail.com"
    use_common_alert_schema = true
  }
}

# Setting up alerts: 
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "High-CPU-Alert"
  resource_group_name = azurerm_resource_group.rg_group.name
  scopes              = [azurerm_windows_virtual_machine.win_vm.id]
  description         = "Action will be triggered when CPU percentage is greater than 85."

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.CloudAlert.id
  }
}

# DOMAIN JOIN METHOD ONE - (THIS ONE WORKS)

#module "domain-join" {
#  source  = "kumarvna/domain-join/azurerm"
#  version = "1.1.0"
#
#  virtual_machine_id        = azurerm_windows_virtual_machine.win_vm.id
#  active_directory_domain   = "coconut.com"
#  active_directory_username = "IamtheAdmin"
#  active_directory_password = "ThisIs@FakePassword@12345"
#  depends_on = [azurerm_windows_virtual_machine.win_vm]
#}

# DOAMIN JOIN METHOD TWO - (WORKING)

resource "azurerm_virtual_machine_extension" "coconut_domain_join" {
  name                 = "coconut_domain_joined"
  virtual_machine_id   = azurerm_windows_virtual_machine.win_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  settings           = <<SETTINGS
    {
        "Name": "coconut.com",
        "User": "IamtheAdmin"
    }
SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
{
"Password": "ThisIs@FakePassword@12345"
}
PROTECTED_SETTINGS
  depends_on         = [azurerm_windows_virtual_machine.win_vm]
}
