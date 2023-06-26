# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "eastus_rg_1"
  location = "eastus"
}

# resource "azurerm_public_ip" "publicip" {
#   name                = "public-ip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

resource "azurerm_public_ip" "publicip2" {
  name                = "public-ip2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "app_gateway_public_ip" {
  name                = "app_gateway_public_ip"
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

# Availability Set
resource "azurerm_availability_set" "aset1" {
  name                = "availability-set1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
}

# Web Layer Subnet 
resource "azurerm_subnet" "webtire_subnet" {
  name                 = "webtire_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  # security_group = azurerm_network_security_group.example.id
}

# Web Layer NSG 
resource "azurerm_network_security_group" "webtire_nsg" {
  name                = "eastus_nsg_webtire"
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

resource "azurerm_subnet_network_security_group_association" "backend_nsg_association" {
  subnet_id                 = azurerm_subnet.webtire_subnet.id
  network_security_group_id = azurerm_network_security_group.webtire_nsg.id
}

# VM1 Interface Cards
resource "azurerm_network_interface" "nic_vm1" {
  name                = "eastus_nic_webvm_1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "eastus_nic_backend_ipconfig"
    subnet_id                     = azurerm_subnet.webtire_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip2.id
  }
}

# # VM2 Interface Cards
# resource "azurerm_network_interface" "nic_vm2" {
#   name                = "eastus_nic_webvm_2"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "eastus_nic_backend_ipconfig"
#     subnet_id                     = azurerm_subnet.webtire_subnet.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# Web VM1
resource "azurerm_virtual_machine" "webvm1" {
  name                  = "eastus_webvm1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vm1.id]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.aset1.id

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo apt-get update",
  #     "sudo apt-get install -y nginx"
  #   ]
  # }

  # connection {
  #   type        = "ssh"
  #   host        = azurerm_virtual_machine.jumpbox.private_ip_address
  #   user        = "adminuser"
  #   password    = "Password1234!"
  #   port        = 22
  #   agent       = false
  #   timeout     = "1m"
  # }

}

# Web VM2 
# resource "azurerm_virtual_machine" "webvm2" {
#   name                  = "eastus_webvm2"
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   network_interface_ids = [azurerm_network_interface.nic_vm2.id]
#   vm_size               = "Standard_DS1_v2"
#   availability_set_id   = azurerm_availability_set.aset1.id

#   # Uncomment this line to delete the OS disk automatically when deleting the VM
#   delete_os_disk_on_termination = true

#   # Uncomment this line to delete the data disks automatically when deleting the VM
#   delete_data_disks_on_termination = true

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   storage_os_disk {
#     name              = "myosdisk1"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }

#   os_profile {
#     computer_name  = "hostname"
#     admin_username = "testadmin"
#     admin_password = "Password1234!"
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }

# }

# Web layer Internal Loadbalancer
resource "azurerm_lb" "webtier_lb" {
  name                = "web-internal-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"


  frontend_ip_configuration {
    name      = "web-internal-lb-frontend"
    subnet_id = azurerm_subnet.webtire_subnet.id
    # public_ip_address_id = azurerm_public_ip.publicip.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.1.78" # Specify the desired private IP address
  }
}

resource "azurerm_lb_backend_address_pool" "webtier_backend_pool" {
  loadbalancer_id = azurerm_lb.webtier_lb.id
  name            = "my-internal-lb-backend-pool"
}

resource "azurerm_lb_probe" "webtier_probe" {
  name            = "my-internal-lb-probe"
  loadbalancer_id = azurerm_lb.webtier_lb.id

  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 1
}

resource "azurerm_lb_rule" "webtier_lb_rule" {
  name                           = "my-internal-lb-rule"
  loadbalancer_id                = azurerm_lb.webtier_lb.id
  frontend_ip_configuration_name = "web-internal-lb-frontend"

  frontend_port            = 80
  backend_port             = 80
  protocol                 = "Tcp"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.webtier_backend_pool.id]
  probe_id                 = azurerm_lb_probe.webtier_probe.id
  enable_tcp_reset         = false
  load_distribution        = "Default"
  enable_floating_ip       = false
  idle_timeout_in_minutes  = 5
}

resource "azurerm_network_interface_backend_address_pool_association" "pa1" {
  network_interface_id    = azurerm_network_interface.nic_vm1.id
  ip_configuration_name   = azurerm_network_interface.nic_vm1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.webtier_backend_pool.id
}

# resource "azurerm_network_interface_backend_address_pool_association" "pa2" {
#   network_interface_id    = azurerm_virtual_machine.webvm2.network_interface_ids[0]
#   ip_configuration_name   = azurerm_virtual_machine.webvm2.network_interface_ids[0].ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb.webtier_lb.backend_address_pool.id
# }

# Locals

locals {
  backend_address_pool_name      = "backend-pool"
  frontend_port_name             = "frontend-port"
  frontend_ip_configuration_name = "frontend-ip-config"
  http_setting_name              = "backend-http-settings"
  listener_name                  = "http-listener"
  request_routing_rule_name      = "routing-rule"
  # redirect_configuration_name    = "${azurerm_virtual_network.example.name}-rdrcfg"
}

# Application gateway Subnet 

resource "azurerm_subnet" "application_gateway_subnet" {
  name                 = "application_gateway_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = "application_gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 50
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.application_gateway_subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    ip_addresses = [
      "10.0.1.78",
    ]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }
}

# resource "azurerm_application_gateway_backend_address_pool" "backend_pool" {
#   name                = "example-backend-pool"
#   resource_group_name = azurerm_resource_group.example.name
#   application_gateway_name = azurerm_application_gateway.app_gateway.name

#   ip_addresses = [
#     "10.0.0.10",
#     "10.0.0.11",
#     "10.0.0.12"
#   ]
# }
