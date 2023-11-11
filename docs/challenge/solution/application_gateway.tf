# Define naming values for use through the application gateway configuration
locals {
  application_gateway_name       = "agw-challenge"
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
  resource_group_name = azurerm_resource_group.challenge.name
  location            = azurerm_resource_group.challenge.location

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
    priority                   = 100
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