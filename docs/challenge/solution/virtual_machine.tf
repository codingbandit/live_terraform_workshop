# Create the backend web server virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  location                        = azurerm_resource_group.challenge.location
  name                            = "backend-webserver-vm"
  network_interface_ids           = [azurerm_network_interface.nic.id]
  resource_group_name             = azurerm_resource_group.challenge.name
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