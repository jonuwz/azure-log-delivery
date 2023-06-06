data "template_file" "dcr" {
  template = file("../templates/dcr.tpl")
  vars = {
    name = "${random_string.name.result}"
    location = azurerm_resource_group.rg.location
    log_analytics_workspace_id = azurerm_log_analytics_workspace.loganalytics.id
  }
}

resource "null_resource" "data_collection_rule" {
  provisioner "local-exec" {
    command = <<EOC
      az rest --subscription ${data.azurerm_client_config.current.subscription_id} \
              --method PUT \
              --url "https://management.azure.com/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Insights/dataCollectionRules/linux-vms?api-version=2021-04-01" \
              --body '${data.template_file.dcr.rendered}'

EOC
  }

  triggers = {
    data = md5(data.template_file.dcr.rendered)
  }
}


data "template_file" "dcra" {
  template = file("../templates/dcra.tpl")
  vars = {
    data_collection_rule = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Insights/dataCollectionRules/linux-vms"
  }
}

resource "null_resource" "data_collection_rule_association" {
  count = "${var.node_count}"

  provisioner "local-exec" {
    command = <<EOC
      az rest --subscription ${data.azurerm_client_config.current.subscription_id} \
              --method PUT \
              --url "https://management.azure.com${element(azurerm_linux_virtual_machine.vm.*.id,count.index)}/providers/Microsoft.Insights/dataCollectionRuleAssociations/dcra${count.index}?api-version=2021-04-01" \
              --body '${data.template_file.dcra.rendered}'
EOC
  }

  triggers = {
    data = md5(data.template_file.dcra.rendered)
  }

  depends_on = [ null_resource.data_collection_rule ]
}
