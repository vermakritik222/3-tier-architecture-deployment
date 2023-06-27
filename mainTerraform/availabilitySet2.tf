# Availability Set 2
resource "azurerm_availability_set" "aset2" {
  name                = "availability-set2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
}

# Availability Set 2 Web Layer Subnet 
resource "azurerm_subnet" "aset2_webtire_subnet" {
  name                 = "aset2_webtire_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Availability Set 2 Web Layer NSG 
resource "azurerm_network_security_group" "aset2_webtire_nsg" {
  name                = "eastus_nsg_aset2_webtire"
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

resource "azurerm_subnet_network_security_group_association" "aset2_webtire_nsg_association" {
  subnet_id                 = azurerm_subnet.aset2_webtire_subnet.id
  network_security_group_id = azurerm_network_security_group.aset2_webtire_nsg.id
}

# Availability Set 2 VM1 Interface Cards
resource "azurerm_network_interface" "aset2_nic_vm1" {
  name                = "eastus_aset2_nic_webvm_1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "eastus_aset2_nic_backend_ipconfig"
    subnet_id                     = azurerm_subnet.aset2_webtire_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_2.id
  }
}

# Availability Set 2 Web VM1
resource "azurerm_virtual_machine" "aset2_webvm1" {
  name                  = "eastus_aset2_webvm1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.aset2_nic_vm1.id]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.aset2.id

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
    name              = "aset2_myosdisk1"
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

# Availability Set 2 Web layer Internal Loadbalancer
resource "azurerm_lb" "aset2_webtier_lb" {
  name                = "aset2_web-internal-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"


  frontend_ip_configuration {
    name      = "aset2_web-internal-lb-frontend"
    subnet_id = azurerm_subnet.aset2_webtire_subnet.id
    # public_ip_address_id = azurerm_public_ip.publicip.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.70" # Specify the desired private IP address
  }
}

resource "azurerm_lb_backend_address_pool" "aset2_webtier_backend_pool" {
  loadbalancer_id = azurerm_lb.aset2_webtier_lb.id
  name            = "aset2_my-internal-lb-backend-pool"
}

resource "azurerm_lb_probe" "aset2_webtier_probe" {
  name            = "aset2_my-internal-lb-probe"
  loadbalancer_id = azurerm_lb.aset2_webtier_lb.id

  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 1
}

resource "azurerm_lb_rule" "aset2_webtier_lb_rule" {
  name                           = "aset2_my-internal-lb-rule"
  loadbalancer_id                = azurerm_lb.aset2_webtier_lb.id
  frontend_ip_configuration_name = "aset2_web-internal-lb-frontend"

  frontend_port            = 80
  backend_port             = 80
  protocol                 = "Tcp"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.aset2_webtier_backend_pool.id]
  probe_id                 = azurerm_lb_probe.aset2_webtier_probe.id
  enable_tcp_reset         = false
  load_distribution        = "Default"
  enable_floating_ip       = false
  idle_timeout_in_minutes  = 5
}

resource "azurerm_network_interface_backend_address_pool_association" "aset2_pa1" {
  network_interface_id    = azurerm_network_interface.aset2_nic_vm1.id
  ip_configuration_name   = azurerm_network_interface.aset2_nic_vm1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.aset2_webtier_backend_pool.id
}