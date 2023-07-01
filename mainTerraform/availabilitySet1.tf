# Availability Set
resource "azurerm_availability_set" "aset1" {
  name                = "${local.project_prifix}_${local.aset1_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
}

resource "azurerm_network_interface" "aset1_nic_web_vm1" {
  name                = "${local.project_prifix}_nic_${local.aset1_web_vm1_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.project_prifix}_nic_${local.aset1_web_vm1_name}_ipconfig"
    subnet_id                     = azurerm_subnet.webtire_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Web VM1
resource "azurerm_virtual_machine" "aset1_webvm1" {
  name                  = "${local.project_prifix}_${local.aset1_web_vm1_name}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.aset1_nic_web_vm1.id]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.aset1.id
  
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.project_prifix}_${local.aset1_web_vm1_name}_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "${local.aset1_web_vm1_name}admin"
    admin_password = local.vm_pass
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "aset1_webvm1_extension" {
  name                 = "${local.project_prifix}_${local.aset1_web_vm1_name}_extension"
  virtual_machine_id   = azurerm_virtual_machine.aset1_webvm1.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
      "commandToExecute": "apt-get update -y && apt-get install -y nginx git && git clone https://github.com/path/to/github/your/repo /app && cd /app/bash && bash init.sh"
    }
  SETTINGS

}


# Web layer Internal Loadbalancer
resource "azurerm_lb" "aset1_webtier_lb" {
  name                = "${local.project_prifix}_${local.aset1_web_lb_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"


  frontend_ip_configuration {
    name                          = "${local.project_prifix}_${local.aset1_web_lb_name}_frontend"
    subnet_id                     = azurerm_subnet.webtire_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.aset1_web_lb_private_static_ip
  }
}

resource "azurerm_lb_backend_address_pool" "aset1_webtier_backend_pool" {
  loadbalancer_id = azurerm_lb.aset1_webtier_lb.id
  name            = "${local.project_prifix}_${local.aset1_web_lb_name}_backend_pool"
}

resource "azurerm_lb_probe" "aset1_webtier_probe" {
  name            = "${local.project_prifix}_${local.aset1_web_lb_name}_probe"
  loadbalancer_id = azurerm_lb.aset1_webtier_lb.id

  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 1
}

resource "azurerm_lb_rule" "aset1_webtier_lb_rule" {
  name                           = "${local.project_prifix}_${local.aset1_web_lb_name}_rule"
  loadbalancer_id                = azurerm_lb.aset1_webtier_lb.id
  frontend_ip_configuration_name = "${local.project_prifix}_${local.aset1_web_lb_name}_frontend"

  frontend_port            = 80
  backend_port             = 80
  protocol                 = "Tcp"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.aset1_webtier_backend_pool.id]
  probe_id                 = azurerm_lb_probe.aset1_webtier_probe.id
  enable_tcp_reset         = false
  load_distribution        = "Default"
  enable_floating_ip       = false
  idle_timeout_in_minutes  = 5
}

resource "azurerm_network_interface_backend_address_pool_association" "aset1_nic_backend_pool_assiciation_1" {
  network_interface_id    = azurerm_network_interface.aset1_nic_web_vm1.id
  ip_configuration_name   = azurerm_network_interface.aset1_nic_web_vm1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.aset1_webtier_backend_pool.id
}


resource "azurerm_network_interface" "aset1_nic_app_vm1" {
  name                = "${local.project_prifix}_nic_${local.aset1_app_vm1_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.project_prifix}_nic_${local.aset1_app_vm1_name}_ipconfig"
    subnet_id                     = azurerm_subnet.apptire_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# App VM1
resource "azurerm_virtual_machine" "aset1_appvm1" {
  name                  = "${local.project_prifix}_${local.aset1_app_vm1_name}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.aset1_nic_app_vm1.id]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.aset1.id
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.project_prifix}_${local.aset1_app_vm1_name}_osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "${local.aset1_app_vm1_name}admin"
    admin_password = local.vm_pass
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "aset1_appvm1_extension" {
  name                 = "${local.project_prifix}_${local.aset1_app_vm1_name}_extension"
  virtual_machine_id   = azurerm_virtual_machine.aset1_appvm1.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
      "commandToExecute": "apt-get update -y && apt-get install -y nginx git"
    }
  SETTINGS

}

# Web layer Internal Loadbalancer
resource "azurerm_lb" "aset1_apptier_lb" {
  name                = "${local.project_prifix}_${local.aset1_app_lb_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"


  frontend_ip_configuration {
    name                          = "${local.project_prifix}_${local.aset1_app_lb_name}_frontend"
    subnet_id                     = azurerm_subnet.apptire_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.aset1_app_lb_private_static_ip
  }
}

resource "azurerm_lb_backend_address_pool" "apptier_backend_pool" {
  loadbalancer_id = azurerm_lb.aset1_apptier_lb.id
  name            = "${local.project_prifix}_${local.aset1_app_lb_name}_backend_pool"
}

resource "azurerm_lb_probe" "apptier_probe" {
  name            = "${local.project_prifix}_${local.aset1_app_lb_name}_probe"
  loadbalancer_id = azurerm_lb.aset1_apptier_lb.id

  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 1
}

resource "azurerm_lb_rule" "aset1_apptier_lb_rule" {
  name                           = "${local.project_prifix}_${local.aset1_app_lb_name}_rule"
  loadbalancer_id                = azurerm_lb.aset1_apptier_lb.id
  frontend_ip_configuration_name = "${local.project_prifix}_${local.aset1_app_lb_name}_frontend"

  frontend_port            = 80
  backend_port             = 80
  protocol                 = "Tcp"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.apptier_backend_pool.id]
  probe_id                 = azurerm_lb_probe.apptier_probe.id
  enable_tcp_reset         = false
  load_distribution        = "Default"
  enable_floating_ip       = false
  idle_timeout_in_minutes  = 5
}

resource "azurerm_network_interface_backend_address_pool_association" "aset1_nic_backend_pool_assiciation_2" {
  network_interface_id    = azurerm_network_interface.aset1_nic_app_vm1.id
  ip_configuration_name   = azurerm_network_interface.aset1_nic_app_vm1.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.apptier_backend_pool.id
}

