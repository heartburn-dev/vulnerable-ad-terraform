### INITIALIZATION FILES
### CONTAINS THE INITIAL PROVIDER AND SETS OUR SECURE CREDENTIALS
### ##############################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

########
#### Set a random password for the administrator
########
resource "random_password" "password" {
    length  = 16
    special = true
}

# Specify where the custom data file is for WinRM initialization
locals {
    custom_data_content  = base64encode(file("${path.module}/scripts/ConfigureRemotingForAnsible.ps1"))
}