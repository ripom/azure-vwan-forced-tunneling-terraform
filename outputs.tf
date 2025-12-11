output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "firewall_dmz_private_ip" {
  description = "Private IP address of Azure Firewall in vnet-dmz"
  value       = azurerm_firewall.dmz.ip_configuration[0].private_ip_address
}

output "virtual_wan_id" {
  description = "ID of the Virtual WAN"
  value       = azurerm_virtual_wan.main.id
}

output "virtual_hub_id" {
  description = "ID of the Virtual Hub"
  value       = azurerm_virtual_hub.main.id
}

output "firewall_name" {
  description = "Name of the Azure Firewall"
  value       = azurerm_firewall.main.name
}

output "spoke_vnet_name" {
  description = "Name of the spoke VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "spoke_vm_private_ip" {
  description = "Private IP address of Spoke VM"
  value       = azurerm_network_interface.spoke.private_ip_address
}
