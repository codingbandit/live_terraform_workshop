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

## Replace a single resource with current configuration

If you were to run a `terraform plan` right now (in the lab06 folder), there wouldn't be any change. However we know that the currently deployed NSG in Azure has changed.

In this first scenario, we're going to assume that we want what we currently have in configuration to prevail and to reset the NSG in Azure to what we have in Terraform state.

1. In the lab06 terminal, type the following command:

    ```bash
    terraform apply -replace "azurerm_network_security_group.network"
    ```

2. Wait for the operation to complete, then verify in Azure that the **AllowSSL** rule is no longer there.