# Virtual WAN
resource "azurerm_virtual_wan" "main" {
  name                = "vwan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    security_control_tag = "Ignore"
  }
}

# Virtual Hub
resource "azurerm_virtual_hub" "main" {
  name                = "vhub"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  virtual_wan_id      = azurerm_virtual_wan.main.id
  address_prefix      = "10.1.0.0/16"

  tags = {
    security_control_tag = "Ignore"
  }
}

# Azure Firewall Policy
resource "azurerm_firewall_policy" "main" {
  name                = "fwpolicy-hub"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  private_ip_ranges   = ["0.0.0.0/0"]

  tags = {
    security_control_tag = "Ignore"
  }
}

# Network Rule Collection for Virtual Hub Firewall
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.main.id
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

# Azure Firewall in Virtual Hub
resource "azurerm_firewall" "main" {
  name                = "fw-hub"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.main.id

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.main.id
    public_ip_count = 1
  }

  tags = {
    security_control_tag = "Ignore"
  }
}

# Virtual Hub Routing Intent
resource "azurerm_virtual_hub_routing_intent" "main" {
  name           = "routing-intent"
  virtual_hub_id = azurerm_virtual_hub.main.id

  routing_policy {
    name         = "PrivateTraffic"
    destinations = ["PrivateTraffic"]
    next_hop     = azurerm_firewall.main.id
  }
}

# Virtual Hub Connection for vnet-dmz
resource "azurerm_virtual_hub_connection" "vnet1" {
  name                      = "vhub-conn-vnet1"
  virtual_hub_id            = azurerm_virtual_hub.main.id
  remote_virtual_network_id = azurerm_virtual_network.main.id
  internet_security_enabled = false

  routing {
    associated_route_table_id = azurerm_virtual_hub.main.default_route_table_id
    propagated_route_table {
      route_table_ids = []
      labels          = []
    }

    static_vnet_route {
      name                = "default-route"
      address_prefixes    = ["0.0.0.0/0"]
      next_hop_ip_address = azurerm_firewall.dmz.ip_configuration[0].private_ip_address
    }
  }
}

# Virtual Hub Connection for hub-spoke
resource "azurerm_virtual_hub_connection" "spoke" {
  name                      = "vhub-conn-spoke"
  virtual_hub_id            = azurerm_virtual_hub.main.id
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  internet_security_enabled = true
}
