# Lab 08 - State

In this lab, we're going to store Terraform state in a container in Azure. This is a good practice for a number of reasons:
    1. It's a central location for all of your state
    2. Multiple people can access the state
    3. Locking is built in to prevent multiple people from modifying the state at the same time

This is just one of a number of ways to store state. For more information, see [this page](https://www.terraform.io/docs/state/remote.html).

## Create a resource group and storage account for storing state

1. In the Azure portal, create a resource group named `tfstate-rg` in the `East US` region.

2. In the Azure portal, within the `tfstate-rg`create a standard LRS storage account with a unique name.

3. Once deployed, navigate to the storage account and select `Containers` from the left-hand menu. Create a container named `lab08state`.

4. Retrieve the storage account 

## Setup the lab files

1. In Visual Studio Code, create the folder `lab-08-state`.
2. In the `lab-08-state` folder, create the file `main.tf`.
3. Add the following code to `main.tf` - this configuration will create a resource group and a network security group:

    ```hcl
   terraform {
        required_providers {
            azurerm = {
                source  = "hashicorp/azurerm"
                version = "3.79.0"
            }
        }
    }

    provider "azurerm" {
        # Configuration options
        features {}
    }

    resource "azurerm_resource_group" "labrg" {
        name     = "tflab07-rg"
        location = "East US"
        tags = {
            environment = "dev"
            costcenter  = "it"
        }
    }

    resource "azurerm_network_security_group" "network" {
        name                = "lab07-nsg"
        location            = azurerm_resource_group.labrg.location
        resource_group_name = azurerm_resource_group.labrg.name

        dynamic "security_rule" {
            for_each = {
                rdp = {
                    name      = "rdp-inbound"
                    direction = "Inbound"
                    priority  = 100
                    port      = 3389
                },
                http = {
                    name      = "https-outbound"
                    direction = "Outbound"
                    priority  = 101
                    port      = 443
                }
            }
            content {
                name                       = security_rule.value["name"]
                priority                   = security_rule.value["priority"]
                direction                  = security_rule.value["direction"]
                access                     = "Allow"
                protocol                   = "Tcp"
                source_address_prefix      = "*"
                destination_address_prefix = "*"
                source_port_range          = "*"
                destination_port_range     = security_rule.value["port"]
            }
        }
    }
    ```