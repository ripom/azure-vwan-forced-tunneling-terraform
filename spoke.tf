# Spoke VNet
resource "azurerm_virtual_network" "spoke" {
  name                = "hub-spoke"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    security_control_tag = "Ignore"
  }
}

# Spoke Subnet
resource "azurerm_subnet" "spoke" {
  name                 = "subnet-spoke"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.2.0.0/24"]
}

# Network Interface for Spoke VM
resource "azurerm_network_interface" "spoke" {
  name                = "vm-spokeVMNic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    security_control_tag = "Ignore"
  }
}

# Spoke VM
resource "azurerm_linux_virtual_machine" "spoke" {
  name                            = "vm-spoke"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.spoke.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {}

  tags = {
    security_control_tag = "Ignore"
  }
}
