resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = "${var.prefix}-loganalytics-${random_string.name.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_data_export_rule" "toeventhub" {
  name                    = "${var.prefix}-la-dataexport"
  resource_group_name     = azurerm_resource_group.rg.name
  workspace_resource_id   = azurerm_log_analytics_workspace.loganalytics.id
  destination_resource_id = azurerm_eventhub_namespace.ehns.id
  table_names             = ["Syslog"]
  enabled                 = true
}
