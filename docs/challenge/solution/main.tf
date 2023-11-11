resource "azurerm_resource_group" "challenge" {
  location = var.preferred_location
  name     = var.resource_group_name
}

