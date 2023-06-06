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

resource "azurerm_eventhub" "eh" {
  name                = "app_${var.prefix}"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 16
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "ehAuthRule" {
  name                = "${var.prefix}-clientSend"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  eventhub_name       = azurerm_eventhub.eh.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = false
  send                = true
  manage              = false
}

