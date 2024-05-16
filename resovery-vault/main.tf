#Importing resource group: 
data "azurerm_resource_group" "rg_name" {
  name = var.rg-name
}


#Creating service recovery vault: 
resource "azurerm_recovery_services_vault" "vault" {
  name                = var.vault_name
  location            = data.azurerm_resource_group.rg_name.location
  resource_group_name = data.azurerm_resource_group.rg_name.name
  sku                 = "Standard"

  soft_delete_enabled = true
}

resource "azurerm_backup_policy_vm" "Terra-Policy" {
  name                = "ShipRocketDefault"
  resource_group_name = data.azurerm_resource_group.rg_name.name
  recovery_vault_name = var.vault_name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}
