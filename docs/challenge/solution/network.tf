# virtual network and associated subnets setup
# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-challenge"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.challenge.location
  resource_group_name = azurerm_resource_group.challenge.name
}

# Create subnets
resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.challenge.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.challenge.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Static public IP for the backend web vm
resource "azurerm_public_ip" "publicip-vm" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.challenge.location
  name                = "pip-challenge-vm"
  resource_group_name = azurerm_resource_group.challenge.name
  sku                 = "Standard"
}

# Network security group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-backend-web"
  location            = azurerm_resource_group.challenge.location
  resource_group_name = azurerm_resource_group.challenge.name
}

# Allow inbound SSH communication over TCP port 22
resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowSSH"
  priority                    = 512
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.challenge.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Allow inbound HTTP communication over TCP port 80
resource "azurerm_network_security_rule" "http" {
  name                        = "AllowHTTP"
  priority                    = 1024
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.challenge.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Create and configure the backend web server VM network interface
resource "azurerm_network_interface" "nic" {
  location            = azurerm_resource_group.challenge.location
  name                = "nic-backend-vm"
  resource_group_name = azurerm_resource_group.challenge.name

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

# Static public IP for the application gateway
resource "azurerm_public_ip" "publicip-ag" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.challenge.location
  name                = "pip-challenge-ag"
  resource_group_name = azurerm_resource_group.challenge.name
  sku                 = "Standard"
}
