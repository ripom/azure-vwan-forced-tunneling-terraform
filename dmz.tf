# DMZ Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-dmz"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    security_control_tag = "Ignore"
  }
}

# Firewall Subnet
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Azure Firewall Public IP for vnet-dmz
resource "azurerm_public_ip" "firewall_dmz" {
  name                = "pip-fw-dmz"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    security_control_tag = "Ignore"
  }
}

# Azure Firewall in vnet-dmz
resource "azurerm_firewall" "dmz" {
  name                = "fw-dmz"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.dmz.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_dmz.id
  }

  tags = {
    security_control_tag = "Ignore"
  }
}

# Firewall Policy for vnet-dmz
resource "azurerm_firewall_policy" "dmz" {
  name                = "fwpolicy-dmz"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  tags = {
    security_control_tag = "Ignore"
  }
}

# Network Rule Collection for vnet-dmz Firewall
resource "azurerm_firewall_policy_rule_collection_group" "dmz" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.dmz.id
  priority           = 100

  network_rule_collection {
    name     = "AllowHTTP"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-http-outbound"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["80"]
    }
  }
}

# Route Table for AzureFirewallSubnet
resource "azurerm_route_table" "firewall" {
  name                = "rt-azfw-dmz"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  route {
    name           = "internet-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = {
    security_control_tag = "Ignore"
  }
}

# Associate Route Table with AzureFirewallSubnet
resource "azurerm_subnet_route_table_association" "firewall" {
  subnet_id      = azurerm_subnet.firewall.id
  route_table_id = azurerm_route_table.firewall.id
}
