# Lab 7 - Drift

In this lab, we'll visit how to handle drift between Terraform state and the resources deployed to Azure.

>**Note:**: This lab builds upon the previous lab (lab 6). Please complete that lab prior to continuing with this one.

## Make a change in the Azure portal

1. In the Azure Portal, open the `lab06-rg` resource group.

2. Locate and open the network security group resource `lab06-nsg`.

3. On the left menu, beneath the **Settings** heading, select the **Inbound security rules** menu item.

4. Create a new rule allowing for inbound port 443, name it `AllowSSL`. For fields not specified, retain the defaults.Press **Add** once complete.
   1. **Destination port ranges**, enter `443`.
   2. **Protocol**, select `TCP`.
   3. **Name**, enter `AllowSSL`.

## Replace a single resource with the current configuration

If you were to run a `terraform plan` right now (in the lab06 folder), there wouldn't be any change. However we know that the currently deployed NSG in Azure has changed.

In this first scenario, we're going to assume that we want what we currently have in configuration to prevail and to reset the NSG in Azure to what we have in Terraform state.

1. In the lab06 terminal, type the following command:

    ```bash
    terraform apply -replace "azurerm_network_security_group.network"
    ```

2. Wait for the operation to complete, then verify in Azure that the **AllowSSL** rule is no longer there.

## Make a change in the Azure portal (again)

1. In the Azure Portal, open the `lab06-rg` resource group.

2. Locate and open the network security group resource `lab06-nsg`.

3. On the left menu, beneath the **Settings** heading, select the **Inbound security rules** menu item.

4. Create a new rule allowing for inbound port 443, name it `AllowSSL`. For fields not specified, retain the defaults.Press **Add** once complete.
   1. **Destination port ranges**, enter `443`.
   2. **Protocol**, select `TCP`.
   3. **Name**, enter `AllowSSL`.

## Refresh changed resources into Terraform state

In this exercise, we're going to assume that we want what we currently have in Azure to prevail and to update the Terraform state to match what is currently deployed.

1. In the Visual Studio Code terminal, type the following command:

    ```bash
    terraform apply -refresh-only    
    ```

2. Wait for the operation to complete, then verify in Azure that the **AllowSSL** rule is in the `terraform.tfstate` file. Notice how the actual configuration file for the NSG has not changed. You can add this value to the current definition of the NSG using copy and paste. If you don't the next time you run apply, the rule will be removed since it isn't in configuration.

## Importing existing resources into Terraform state

In this exercise, we're going to assume that we want what we currently have in Azure to prevail and to update the Terraform state to match what is currently deployed. In this case, we'll start with a clean project and start importing resources using the import functionality. We'll import the resource group from lab-06.

1. Create a new folder called `lab-07-import`.

2. In the `lab-07-import` folder, create a new file called `main.tf`. Initialize it with the following code:

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
    ```

3. In the `main.tf` file, start by creating a resource for the resource group.

    ```hcl
    resource "azurerm_resource_group" "lab-rg" {
        
    }
    ```

4. In the Azure portal, open the `lab06-rg` resource group.

5. From the left menu, select the **Properties** menu item.

6. Locate the **Resource ID** field and copy the value.

7. Import the resource group into Terraform state by typing the following command in the terminal, replacing `<resource-id>` with the value copied in the previous step:

    ```bash
    terraform import azurerm_resource_group.lab-rg <resource-id>
    ```

8. Wait a moment for the import to complete, then verify the resource group exists in the `terraform.tfstate` file.

9. Issue the `terraform destroy` command in the lab 6 folder.
