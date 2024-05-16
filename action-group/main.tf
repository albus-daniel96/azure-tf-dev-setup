data "azurerm_resource_group" "rg_name" {
  name = "TWD"
}

resource "azurerm_monitor_action_group" "example" {
  name                = "CriticalAlertsAction"
  resource_group_name = data.azurerm_resource_group.rg_name.name
  short_name          = "p0action"

  email_receiver {
    name          = "sendtoadmin"
    email_address = "petejax123@gmail.com"
  }
}
