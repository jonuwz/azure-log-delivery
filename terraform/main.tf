data "template_file" "config" {
  template = file("../cloudinit/config_azure.yaml")
  vars = {
    eventhubNS = "${azurerm_eventhub_namespace.tfEventhubNS.name}"
    eventhub  = "${azurerm_eventhub.tfEventhub.name}"
    connectionString = "${azurerm_eventhub_authorization_rule.tfEventhubAuthRule.primary_connection_string}"
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

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "tfgroup" {
    name     = "myResourceGroup"
    location = "eastus2"

    tags = {
        environment = "tf"
    }
}

resource "azurerm_eventhub_namespace" "tfEventhubNS" {
  name                = "myEventhubNS1"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.tfgroup.name
  sku                 = "standard"
}

resource "azurerm_eventhub" "tfEventhub" {
  name                = "app_tf"
  namespace_name      = azurerm_eventhub_namespace.tfEventhubNS.name
  resource_group_name = azurerm_resource_group.tfgroup.name
  partition_count     = 16
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "tfEventhubAuthRule" {
  name                = "tfEventhubClientSend"
  namespace_name      = azurerm_eventhub_namespace.tfEventhubNS.name
  eventhub_name       = azurerm_eventhub.tfEventhub.name
  resource_group_name = azurerm_resource_group.tfgroup.name
  listen              = false
  send                = true
  manage              = false
}

# Create virtual network
resource "azurerm_virtual_network" "tfnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.tfgroup.name

    tags = {
        environment = "tf"
    }
}

# Create subnet
resource "azurerm_subnet" "tfsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.tfgroup.name
    virtual_network_name = azurerm_virtual_network.tfnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "tfpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus2"
    resource_group_name          = azurerm_resource_group.tfgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "tf"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "tfnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.tfgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "tf"
    }
}

# Create network interface
resource "azurerm_network_interface" "tfnic" {
    name                      = "myNIC"
    location                  = "eastus2"
    resource_group_name       = azurerm_resource_group.tfgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.tfsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.tfpublicip.id
    }

    tags = {
        environment = "tf"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.tfnic.id
    network_security_group_id = azurerm_network_security_group.tfnsg.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "tfvm" {
    name                  = "myVM"
    location              = "eastus2"
    resource_group_name   = azurerm_resource_group.tfgroup.name
    network_interface_ids = [azurerm_network_interface.tfnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOlY9F0gLlOTPvf5XrAiXH+qGdtrNuEL6Lbd+I1TFTzpci97ozzZksJ/6GvBnC/iX1WObibQBGZNdDdnD7041kbwnfgxNn9gC/EckNgRSmMmVFN/7QkPVclcCgBDqMeKo/r7k8PZFHi8cEUeJX71Bzac4cnRgN5jQY/cp6+MN+CcN44xyP1Lubjv+tfKmfLU7wzOLVcV6TnywpCPSC/yDAVfzhy/usNxlLnejtChhAuy98v1ibKkpWXKd3LbKvl2CHDA464dHvLS7zyoB/wOfjBgCXYkjWhq+lUE/EVDAhlp5k8+HGRmGY5mcB8wvUUvZw1wfy3NyR0pf3n6G1nA5B"
    }

    custom_data = data.template_cloudinit_config.config.rendered

    tags = {
        environment = "tf"
    }
}

output "EVENTHUB_CONNECTION_STRING" {
  value = "${azurerm_eventhub_namespace.tfEventhubNS.default_primary_connection_string}"
  sensitive = true
}

output "EVENTHUB_LOCATION" {
  value = "${azurerm_eventhub_namespace.tfEventhubNS.name}.servicebus.windows.net:9093"
}
