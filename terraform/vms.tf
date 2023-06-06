# Create virtual network
resource "azurerm_virtual_network" "net" {
    name                = "${var.prefix}-net"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.net.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "publicip" {
    count                        = "${var.node_count}"
    name                         = "${var.prefix}-ip-${count.index}"
    location                     = azurerm_resource_group.rg.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.prefix}-vm-nsg"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location

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
}

# Create network interface
resource "azurerm_network_interface" "nic" {
    count                     = "${var.node_count}"
    name                      = "${var.prefix}-nic-${count.index}"
    location                  = azurerm_resource_group.rg.location
    resource_group_name       = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "${var.prefix}-ip-config-${count.index}"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.publicip.*.id, count.index)}"
    }

    tags = {
        environment = "tf"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sga" {
    count                     = "${var.node_count}"
    network_interface_id      = "${element(azurerm_network_interface.nic.*.id, count.index)}"
    network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
    count                 = "${var.node_count}"
    name                  = "${var.prefix}-vm-${count.index}"
    location              = azurerm_resource_group.rg.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = ["${element(azurerm_network_interface.nic.*.id,count.index)}"]
    size                  = "Standard_B1s"

    os_disk {
        name              = "${var.prefix}-vm-disk-${count.index}"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "RedHat"
        offer     = "RHEL"
        sku       = "8"
        version   = "latest"
    }

    computer_name  = "${var.prefix}-vm-${count.index}"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOlY9F0gLlOTPvf5XrAiXH+qGdtrNuEL6Lbd+I1TFTzpci97ozzZksJ/6GvBnC/iX1WObibQBGZNdDdnD7041kbwnfgxNn9gC/EckNgRSmMmVFN/7QkPVclcCgBDqMeKo/r7k8PZFHi8cEUeJX71Bzac4cnRgN5jQY/cp6+MN+CcN44xyP1Lubjv+tfKmfLU7wzOLVcV6TnywpCPSC/yDAVfzhy/usNxlLnejtChhAuy98v1ibKkpWXKd3LbKvl2CHDA464dHvLS7zyoB/wOfjBgCXYkjWhq+lUE/EVDAhlp5k8+HGRmGY5mcB8wvUUvZw1wfy3NyR0pf3n6G1nA5B"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
    }

    identity {
        type = "SystemAssigned"
    }

    custom_data = data.template_cloudinit_config.config.rendered
}

resource "azurerm_virtual_machine_extension" "monitoragent" {
  count                = "${var.node_count}"
  name                 = "${var.prefix}-monitoragent-${count.index}"
  virtual_machine_id   = "${element(azurerm_linux_virtual_machine.vm.*.id,count.index)}"
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.15"
}
