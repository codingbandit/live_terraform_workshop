resource "azurerm_resource_group" "lab_1" {
  location = var.preferred_location
  name     = var.resource_group_name
}

# virtual network and associated subnets setup
# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-lab-1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab_1.location
  resource_group_name = azurerm_resource_group.lab_1.name
}

# Create subnets
resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.lab_1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.lab_1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Static public IP for the backend web vm
resource "azurerm_public_ip" "publicip-vm" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.lab_1.location
  name                = "pip-lab-1-vm"
  resource_group_name = azurerm_resource_group.lab_1.name
  sku                 = "Standard"
}

# Network security group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-backend-web"
  location            = azurerm_resource_group.lab_1.location
  resource_group_name = azurerm_resource_group.lab_1.name
}

# Allow inbound SSH communication over TCP port 22
resource "azurerm_network_security_rule" "ssh" {
  name                        = "Allow SSH"
  priority                    = 512
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab_1.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Allow inbound HTTP communication over TCP port 80
resource "azurerm_network_security_rule" "http" {
  name                        = "Allow HTTP"
  priority                    = 1024
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.lab_1.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Create and configure the backend web server VM network interface
resource "azurerm_network_interface" "nic" {
  location            = azurerm_resource_group.lab_1.location
  name                = "nic-backend-vm"
  resource_group_name = azurerm_resource_group.lab_1.name

  ip_configuration {
    name                          = "vm-nic-config"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip-vm.id
    subnet_id                     = azurerm_subnet.backend.id
  }
}

# Add nic to nsg
resource "azurerm_network_interface_security_group_association" "nsg_to_nic" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create the backend web server virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  location                        = azurerm_resource_group.lab_1.location
  name                            = "backend-webserver-vm"
  network_interface_ids           = [azurerm_network_interface.nic.id]
  resource_group_name             = azurerm_resource_group.lab_1.name
  size                            = "Standard_DS1_v2"
  disable_password_authentication = false
  admin_password                  = "Password1234!"
  admin_username                  = "plankton"
  computer_name                   = "backend-webserver-vm"
  custom_data                     = base64encode(file("scripts/install-nginx.sh"))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    name                 = "os-backend-webserver-vm"
  }

  source_image_reference {
    offer     = "UbuntuServer"
    publisher = "Canonical"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }
}

# Static public IP for the application gateway
resource "azurerm_public_ip" "publicip-ag" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.lab_1.location
  name                = "pip-lab-1-ag"
  resource_group_name = azurerm_resource_group.lab_1.name
  sku                 = "Standard"
}

# Define naming values for use through the application gateway configuration
locals {
  application_gateway_name       = "agw-lab-1"
  backend_address_pool_name      = "${local.application_gateway_name}-beap"
  frontend_port_name             = "${local.application_gateway_name}-feport"
  frontend_ip_configuration_name = "${local.application_gateway_name}-feip"
  http_setting_name              = "${local.application_gateway_name}-be-htst"
  listener_name                  = "${local.application_gateway_name}-httplstn"
  request_routing_rule_name      = "${local.application_gateway_name}-rqrt"
  redirect_configuration_name    = "${local.application_gateway_name}-rdrcfg"
}

# Create and configure the Application Gateway
resource "azurerm_application_gateway" "ag" {
  name                = local.application_gateway_name
  resource_group_name = azurerm_resource_group.lab_1.name
  location            = azurerm_resource_group.lab_1.location

  # Utilize the Web Application Firewall v2 SKU
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  # Assign the gateway to the frontend subnet
  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  # The front_end (application gateway) port will listen on port 80
  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  # Associate the application gateway public IP
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.publicip-ag.id
  }

  # The backend address pool consists of the backend web server IP address
  backend_address_pool {
    name = local.backend_address_pool_name
    ip_addresses = [
      azurerm_public_ip.publicip-vm.ip_address
    ]
  }

  # The application gateway will communicate with the backend web server using HTTP protocol over port 80
  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  # The application gateway will listen on the public IP for HTTP traffic
  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # The application gateway will route all http traffic to the backend web server
  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  # Leverage a predefined SSL policy (TLSv1_1)
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  # Configure the firewall with the OWASP 3.1 rule set
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"
  }
}