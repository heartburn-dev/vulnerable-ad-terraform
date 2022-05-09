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
#### Set a random password for the windows administrator
########
resource "random_password" "windowspass" {
  length = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

########
#### Set a random password for the Linux user
########
resource "random_password" "linuxpass" {
  length = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}