# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "eastus_rg_1"
  location = "eastus"
}

# Public Ips
resource "azurerm_public_ip" "public_ip_1" {
  name                = "public_ip_1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Virtual Networks
resource "azurerm_virtual_network" "vnet" {
  name                = "eastus_vnet_1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # dns_servers         = ["10.0.0.4", "10.0.0.5"]
}
