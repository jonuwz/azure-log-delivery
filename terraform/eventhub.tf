# needed to avoid eventhub NS name collisions
resource "random_string" "name" {
  length  = 8
  upper   = false
  special = false
  numeric = false
}

resource "azurerm_eventhub_namespace" "ehns" {
  name                = "${var.prefix}-ehns-${random_string.name.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}
