#importing the resource group
data "azurerm_resource_group" "target_rg" {
  name = var.target_rg_name
}

#importing the virtual network
data "azurerm_virtual_network" "target_vnet" {
  name                = var.target_vnet_name
  resource_group_name = data.azurerm_resource_group.target_rg.name
}

data "azurerm_subnet" "target_subnet" {
  name                 = var.target_subnet
  virtual_network_name = data.azurerm_virtual_network.target_vnet.name
  resource_group_name  = data.azurerm_resource_group.target_rg.name
}

#importing action group for alert configuration: 
data "azurerm_monitor_action_group" "act_group" {
  resource_group_name = data.azurerm_resource_group.target_rg.name
  name                = "CriticalAlertsAction"
}

#Creating a public IP: 
resource "azurerm_public_ip" "vm_pip" {
  count = var.public_ip_needed == "yes" ? length(var.vm_sku) : 0  
  name                = "${var.vm_name}${count.index}-PIP"
  resource_group_name = data.azurerm_resource_group.target_rg.name
  location            = data.azurerm_resource_group.target_rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  count = length(var.vm_sku)  
  name                = "${var.vm_name}nic-${count.index}"
  location            = data.azurerm_resource_group.target_rg.location
  resource_group_name = data.azurerm_resource_group.target_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.target_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = var.public_ip_needed == "yes" ? azurerm_public_ip.vm_pip[count.index].id : null

  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
}

resource "azurerm_managed_disk" "vm_disk" {
  count = var.disk_count  
  name                 = "${var.vm_name}disk-${count.index}"
  location             = data.azurerm_resource_group.target_rg.location
  resource_group_name  = data.azurerm_resource_group.target_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_windows_virtual_machine" "vm_dev" {
  count = length(var.vm_sku)  
  name                = "${var.vm_name}${count.index}"
  computer_name = var.computer_name
  resource_group_name = data.azurerm_resource_group.target_rg.name
  location            = data.azurerm_resource_group.target_rg.location
  size                = var.vm_size[count.index]
  admin_username      = "adminuser"
  admin_password      = random_password.password.result
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.vm_sku[count.index]
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  count = var.disk_count  
  managed_disk_id    = azurerm_managed_disk.vm_disk[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm_dev[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

# Creating VM alerts: 
resource "azurerm_monitor_metric_alert" "example" {
  count = length(var.vm_sku)
  name                = "CPU-Overuse"
  resource_group_name = data.azurerm_resource_group.target_rg.name
  scopes              = [azurerm_windows_virtual_machine.vm_dev[count.index].id]
  description         = "CPU Overuse Alert"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.act_group.id
  }
}

# Importing log analytics workspace: 
data "azurerm_log_analytics_workspace" "log_workspace" {
  name                = var.log_work_space
  resource_group_name = data.azurerm_resource_group.target_rg.name
}

# Connecting VM to Log Analytics Workspace: 
resource "azurerm_virtual_machine_extension" "OMS" {
  count = length(var.vm_sku)
  name                 = "OMS"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_dev[count.index].id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "MicrosoftMonitoringAgent"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = "true"
  settings = <<SETTINGS
    {
      "workspaceId": "${var.log_ws_id}"
    }
SETTINGS
   protected_settings = <<PROTECTED_SETTINGS
   {
      "workspaceKey": "${var.log_ws_key}"
   }
PROTECTED_SETTINGS
}

# Importing backup vault: 
data "azurerm_recovery_services_vault" "backup_vault" {
  name                = "CentralBackUp"
  resource_group_name = "TWD"
}

# Impoting the backup policy: 
data "azurerm_backup_policy_vm" "policy" {
  name                = "ShipRocketDefault"
  recovery_vault_name = "CentralBackUp"
  resource_group_name = "TWD"
}

# Establishing VM connection:
resource "azurerm_backup_protected_vm" "backup_vm" {
  count = length(var.vm_sku)
  resource_group_name = data.azurerm_resource_group.target_rg.name
  recovery_vault_name = data.azurerm_recovery_services_vault.backup_vault.name
  source_vm_id        = azurerm_windows_virtual_machine.vm_dev[count.index].id
  backup_policy_id    = data.azurerm_backup_policy_vm.policy.id
} 
