# Lab 01 - Create and tear down an Azure Resource Group

## Create a Terraform workspace

A workspace is a folder on your local machine that contains your Terraform configuration files.

A Terraform project contains `*.tf` or `*.tfvars` extension files. These files are written in HashiCorp Configuration Language (HCL). HCL is a declarative language that is used to describe your infrastructure. It is similar to JSON or YAML, but with some additional features that make it easier to use for configuration.

1. On your file system, create a new folder named `terraform-workshop`.

2. Open the `terraform-workshop` folder in Visual Studio Code.

3. Create a new folder called `lab-01-hello-world`.

4. Create a new file called `main.tf` in the `lab-01-hello-world` folder.

## Include the azurerm provider

As we are going to be managing resources in Azure, we need to include the `azurerm` provider in our configuration.

1. In a web browser, visit the Terraform public registry to see the [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) provider documentation.

2. In the upper-right of the site, expand the **USE PROVIDER** button, and copy the code snippet. Paste this in the `main.tf` file.

    ```hcl
    terraform {
        required_providers {
            azurerm = {
            source = "hashicorp/azurerm"
            version = "3.79.0"
            }
        }
    }

    provider "azurerm" {
    # Configuration options
    }
    ```

3. Save the file.

## Initialize the project

When you run `terraform init`, Terraform will download the `azurerm` provider and install it in a hidden folder called `.terraform`. This folder will contain the provider binary and any other dependencies that the provider needs to run.

1. Open a terminal window in Visual Studio Code (under the View menu or using the <kbd>CTRL</kbd>+<kbd>`</kbd> shortcut).

2. Navigate to the `lab-01-hello-world` folder.

3. Initialize the project using the following command:

    ```bash
    terraform init
    ```

4. You will see a message indicating that Terraform has been initialized successfully. You will see a new folder called `.terraform` in your project folder that contains the executable for the AzureRM provider. In the root of the project, you'll aslo see a `.terraform.lock.hcl` file. This file contains hashes that represent the validity of the version of the provider that was installed through hashes.

## Add code to define the configuration of a resource group

1. In a web browser, visit the Terraform public registry to see the [resource group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) documentation. Note: all resources that can be configured are avaialble in the left menu.

2. Locate the **Example Usage** heading. Copy the code snippet under the heading and append it to the `main.tf` file.

    ```hcl
    resource "azurerm_resource_group" "example" {
        name     = "example"
        location = "West Europe"
    }
    ```

3. The first line of code declares the configuration for a resource of the type `azurerm_resource_group`. The last option in quotes is the name of the resource, think of it as a namespace. Through this namespace, you can refer to this resource in other parts of your configuration. This name has no bearing on the name of the resource that will be created in Azure. The attributes contained within the block describe the configuration of the resource group. The `name` attribute is the name of the resource group that will be created in Azure. The `location` attribute is the Azure region where the resource group will be created. Feel free to edit as desired.

    ```hcl
    resource "azurerm_resource_group" "labrg" {
        name     = "tflab01-rg"
        location = "East US"
    }
    ```

4. Save the file.

## Format the file

Terraform has a built-in command called `terraform fmt` that will format your configuration files in a standard way. This makes it easier to read and understand your configuration.

1. In the terminal window, run the following command:

    ```bash
    terraform fmt
    ```

2. You will see a message indicating the name of the file(s) that Terraform has formatted. If no formatting was necessary, the command will exit silently. The format command automatically saves the files.

## Validate the configuration

Terraform has a built-in command called `terraform validate` that will validate your configuration files. This command will check for syntax errors and other common errors that may prevent your configuration from running successfully.

1. In the terminal window, run the following command:

    ```bash
    terraform validate
    ```

2. You will see a message indicating that the configuration is valid. If there are any errors, they will be displayed in the terminal window.

## Plan the application of the configuration

Terraform has a built-in command called `terraform plan` that will show you what changes Terraform will make to your infrastructure when you apply the configuration. This command will not make any changes to your infrastructure, it will only show you what changes will be made.

1. In the terminal window, run the following command:

    ```bash
    terraform plan
    ```

2. You will see an error message indicating that the azurerm provider requires a features block. Modify the azurerm provider block in main.tf with an empty features block.

    ```hcl
    provider "azurerm" {
        features {}
    }
    ```

3. Run the plan again. This creates a speculative plan, nothing is being changed in the cloud at this point. It will output the added/changed/destroyed resources.

4. Note that there is a message indicating the output of the file is saved. This is the plan file. It is a binary file that contains the plan that Terraform will apply. This file can be used to apply the plan in a different environment. For example, you can create the plan on your local machine and apply it in a CI/CD pipeline. This is an optional setting.

## Authenticate to Azure using the CLI

Terraform needs to authenticate to Azure in order to manage resources. There are several ways to authenticate to Azure. In this lab, we will use the Azure CLI to authenticate.

1. In the terminal window, run the following command:

    ```bash
    az login
    ```

2. If you have more than one subscription, set the desired subscription using the following command:

    ```bash
    az account set --subscription <subscription id>
    ```

## Apply the configuration

Terraform has a built-in command called `terraform apply` that will apply the configuration to your infrastructure. This command will make changes to your infrastructure.

1. In the terminal window, run the following command:

    ```bash
    terraform apply
    ```

2. You will see a message indicating that Terraform will perform the following actions:

    ```bash
    Terraform will perform the following actions:

    # azurerm_resource_group.labrg will be created
    + resource "azurerm_resource_group" "labrg" {
        + id       = (known after apply)
        + location = "eastus"
        + name     = "tflab01-rg"
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value:
    ```

3. Type `yes` and press <kbd>ENTER</kbd> to apply the configuration.

4. In a few moments, you will see a message indicating that the configuration was successfully applied.

5. Visit the Azure Portal and navigate to the resource group that was created. You will see that the resource group was created successfully.

## Modify the resource group by adding tags

1. In the `main.tf` file, add the following code to the `azurerm_resource_group` block:

    ```hcl
    tags = {
        environment = "dev"
        costcenter  = "it"
    }
    ```

2. Save the file.

3. Run `terraform fmt`, `terraform validate`, and `terraform plan` to verify that the configuration is valid.

4. Run `terraform apply` to apply the configuration.

5. After the configuration has been applied, revisit the resource group in the Azure Portal. You will see that the tags have been added to the resource group. The portal loves to cache, so you may need to exit the resource group screen and re-enter it to see the tags.

## Destroy the resource group

Terraform has a built-in command called `terraform destroy` that will destroy the resources that were created by the configuration. This command will make changes to your infrastructure.

1. In the terminal window, run the following command:

    ```bash
    terraform destroy
    ```

2. Once complete, verify in the Azure portal that the resource group is no longer there.

Congratulations, you've completed Lab 1.
