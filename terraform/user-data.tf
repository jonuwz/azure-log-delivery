data "template_file" "config" {
  template = file("../cloudinit/config_azure.yaml")
  vars = {
    eventhubNS = "${azurerm_eventhub_namespace.ehns.name}"
    eventhub  = "${azurerm_eventhub.eh.name}"
    connectionString = "${azurerm_eventhub_authorization_rule.ehAuthRule.primary_connection_string}"
  }
}

data "template_file" "script" {
  template = file("../cloudinit/script_azure.sh")
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.config.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.script.rendered}"
  }
}
