variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-hubenv-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "southcentralus"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2s"
}
