resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = "dcr"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location

  destinations {
   log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.loganalytics.id
      name                  = "loganalytics"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["loganalytics"]
  }

  data_sources {
    syslog {
      facility_names = [ "auth", "authpriv", "cron", "daemon", "mark", "kern", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp" ]
      log_levels     = [ "Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency" ]
      streams        = [ "Microsoft-Syslog"]
      name           = "syslog"
    }
  }
  description = "data collection rule"
}
