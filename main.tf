# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "${local.project_prifix}_${local.project_location}_resource_group"
  location = local.project_location
}

# Public Ips
resource "azurerm_public_ip" "app_gateway_public_ip" {
  name                = "${local.project_prifix}_app_gateway_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Virtual Networks
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.project_prifix}_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

# Subnet
resource "azurerm_subnet" "application_gateway_subnet" {
  name                 = local.application_gateway_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}
resource "azurerm_subnet" "webtire_subnet" {
  name                 = "${local.project_prifix}_webtire_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "apptire_subnet" {
  name                 = "${local.project_prifix}_apptire_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}


# Network Security Group
resource "azurerm_network_security_group" "webtire_nsg" {
  name                = "${local.project_prifix}_nsg_webtire"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "apptire_nsg" {
  name                = "${local.project_prifix}_nsg_apptire"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "BaclendHTTP"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefixes    = ["0.0.0.0/0"]
    destination_address_prefix = "*"
  }

}

# Network Security Group Assocuation
resource "azurerm_subnet_network_security_group_association" "webtier_nsg_association" {
  subnet_id                 = azurerm_subnet.webtire_subnet.id
  network_security_group_id = azurerm_network_security_group.webtire_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "apptier_nsg_association" {
  subnet_id                 = azurerm_subnet.apptire_subnet.id
  network_security_group_id = azurerm_network_security_group.apptire_nsg.id
}

