variable "prefix" { default = "tf" }
variable "location" { default = "eastus2" }
variable "node_count" { default = 1 }

data "azurerm_client_config" "current" {}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.59.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "rg" {
    name     = "${var.prefix}-rg"
    location = "${var.location}"
}

output "EVENTHUB_CONNECTION_STRING" {
  value = "${azurerm_eventhub_namespace.ehns.default_primary_connection_string}"
  sensitive = true
}

output "EVENTHUB_LOCATION" {
  value = "${azurerm_eventhub_namespace.ehns.name}.servicebus.windows.net:9093"
}

data "template_file" "fluent_conf" {
  template = file("../templates/fluent.conf.tpl")
  vars = {
    eventhubNS = "${azurerm_eventhub_namespace.ehns.name}"
    connectionString = "${azurerm_eventhub_namespace.ehns.default_primary_connection_string}"
  }
}

resource "local_file" "fluent_conf" {
  content = "${data.template_file.fluent_conf.rendered}"
  filename = "../renders/fluent.conf"
}

data "template_file" "fluent_debug_conf" {
  template = file("../templates/fluent.debug.conf.tpl")
  vars = {
    eventhubNS = "${azurerm_eventhub_namespace.ehns.name}"
    connectionString = "${azurerm_eventhub_namespace.ehns.default_primary_connection_string}"
  }
}

resource "local_file" "fluent_debug_conf" {
  content = "${data.template_file.fluent_debug_conf.rendered}"
  filename = "../renders/fluent.debug.conf"
}

