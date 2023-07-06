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
    # public_ip_address_id          = azurerm_public_ip.public_ip_1.id
  }
}

# Web VM1
resource "azurerm_virtual_machine" "webvm1" {
  name                  = "eastus_webvm1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vm1.id]
  vm_size               = "Standard_DS1_v2"

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

}


resource "azurerm_virtual_machine_extension" "custom_script_extension" {
  name                 = "custom_script_extension"
  virtual_machine_id   = azurerm_virtual_machine.webvm1.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
      {
              "commandToExecute": "apt-get update -y && apt-get install -y nginx git && git clone https://github.com/your-repo.git /app && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs && apt-get install -y npm && cd /app && npm install && npm run build && cp -r build/* /usr/share/nginx/html && echo 'backend_ip=10.0.2.34' | tee -a /etc/nginx/nginx.conf && service nginx restart"
      }
    SETTINGS
  # settings = <<SETTINGS
  #   {
  #     "commandToExecute": "apt-get update && apt-get install -y nginx"
  #   }
  # SETTINGS
}

# VM1 Interface Cards
resource "azurerm_network_interface" "nic_vm2" {
  name                = "eastus_nic_webvm_2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "eastus_nic_backend_ipconfig"
    subnet_id                     = azurerm_subnet.webtire_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_1.id
  }
}

# Web VM1
resource "azurerm_virtual_machine" "webvm2" {
  name                  = "eastus_webvm2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_vm2.id]
  vm_size               = "Standard_DS1_v2"

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
    name              = "myosdisk2"
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

}
