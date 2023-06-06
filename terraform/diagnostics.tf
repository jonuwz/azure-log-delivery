resource "random_id" "randomId" {
    keepers = {
        resource_group = azurerm_resource_group.rg.name
    }
    byte_length = 8
}

resource "azurerm_storage_account" "storage" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = azurerm_resource_group.rg.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

data "azurerm_storage_account_sas" "storage_sas" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = true
    file  = false
  }

  start  = "2018-03-21T00:00:00Z"
  expiry = "2030-01-01T00:00:00Z"

  permissions {
    read    = false
    write   = true
    delete  = false
    list    = true
    add     = true
    create  = true
    update  = true
    process = false
    tag     = false
    filter  = false
  }
}

data "template_file" "lad_public_settings" {
  template = file("../templates/lad_public_settings.json.tpl")
  vars = {
    storageAccount = "${azurerm_storage_account.storage.name}"
  }
}

resource "local_file" "lad_public_settings" {
  content = "${data.template_file.lad_public_settings.rendered}"
  filename = "../renders/lad_public_settings.json"
}

data "template_file" "lad_private_settings" {
  template = file("../templates/lad_private_settings.json.tpl")
  vars = {
    storageAccount = "${azurerm_storage_account.storage.name}"
    storageAccountToken = "${trim(data.azurerm_storage_account_sas.storage_sas.sas,"?")}"
  }
}

resource "local_file" "lad_private_settings" {
  content = "${data.template_file.lad_private_settings.rendered}"
  filename = "../renders/lad_private_settings.json"
}

data "template_file" "logging" {
  template = file("../templates/logging.sh.tpl")
  vars = {
    eventHubURI = "https://${azurerm_eventhub_namespace.ehns.name}.servicebus.windows.net/${azurerm_eventhub.eh.name}"
    accessKeyName = "RootManageSharedAccessKey"
    accessKey = "${azurerm_eventhub_namespace.ehns.default_primary_key}"
    rgName     = "${azurerm_resource_group.rg.name}"
  }
}

resource "local_file" "logging" {
  content = "${data.template_file.logging.rendered}"
  filename = "../renders/logging.sh"
}
