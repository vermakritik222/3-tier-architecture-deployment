# Project locals
locals {
  project_prifix   = "multitier_diployment_demo"
  project_location = "eastus"
  vm_pass          = "Password1234!"
}

# Application Gateway Locals
locals {
  backend_address_pool_name       = "backend-pool"
  frontend_port_name              = "frontend-port"
  frontend_ip_configuration_name  = "frontend-ip-config"
  http_setting_name               = "backend-http-settings"
  listener_name                   = "http-listener"
  request_routing_rule_name       = "routing-rule"
  application_gateway_subnet_name = "application_gateway_subnet"
  application_gateway_name        = "application_gateway"
  gateway_ip_configuration_name   = "gateway-ip-config"
}

# Availability Set 1 Locals
locals {
  aset1_name                     = "availability_set_1"
  aset1_web_vm1_name             = "availability_set_1_web_vm_1"
  aset1_web_lb_name              = "availability_set_1_web_internal_lb"
  aset1_web_lb_private_static_ip = "10.0.1.70"
  aset1_app_vm1_name             = "availability_set_1_app_vm_1"
  aset1_app_lb_name              = "availability_set_1_app_internal_lb"
  aset1_app_lb_private_static_ip = "10.0.2.70"

}

# Availability Set 2 Locals
locals {
  aset2_name                     = "availability_set_2"
  aset2_web_vm1_name             = "availability_set_2_web_vm_1"
  aset2_web_lb_name              = "availability_set_2_web_internal_lb"
  aset2_web_lb_private_static_ip = "10.0.1.60"
  aset2_app_vm1_name             = "availability_set_2_app_vm_1"
  aset2_app_lb_name              = "availability_set_2_app_internal_lb"
  aset2_app_lb_private_static_ip = "10.0.2.60"
}
