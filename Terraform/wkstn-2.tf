#######
# Terraforms the first workstation = WKSTN-2
#######

#######
# Set up the NIC on the workstation and link it to our subnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
#######
resource "azurerm_network_interface" "wkstn-2-nic" {
  name                = "wkstn-2-nic"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name

  ip_configuration {
    name                          = "wkstn-2-internal-ip"
    subnet_id                     = azurerm_subnet.vulnerableADLabs-subnet.id
    private_ip_address_allocation = "static"
    private_ip_address = "10.10.10.51"

  }
}

########
# Configure the Windows wkstn-1
# Ensure that we wait for the dc to be created first
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine
########
resource "azurerm_windows_virtual_machine" "wkstn-2-vm" {
  name                = "wkstn-2"
  computer_name = var.workstation-hostname[1]
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  size                = var.workstation-size
  provision_vm_agent = true
  timezone = var.timezone
  admin_username      = var.windows-user
  admin_password      = random_password.password.result
  enable_automatic_updates = false
  

  network_interface_ids = [
    azurerm_network_interface.wkstn-2-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 60
  }

  source_image_reference {
    # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-ent-g2"
    version   = "latest"
  }

  additional_unattend_content {
    content = local.autologon_data
    setting = "AutoLogon"
  }

  additional_unattend_content {
    setting = "FirstLogonCommands"
    content = local.first_logon_commands
  }
}

########
# Setup extensions to run the provisioning script for Ansible
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension
# https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows
########
resource "azurerm_virtual_machine_extension" "provisioning-wkstn-2" {
  name = "provision-wkstn-2"
  virtual_machine_id = azurerm_windows_virtual_machine.wkstn-2-vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
      "fileUris": ["https://raw.githubusercontent.com/chvancooten/CloudLabsAD/main/Terraform/files/ConfigureRemotingForAnsible.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
  }
  SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.wkstn-2-vm,
    azurerm_nat_gateway.ng
  ]
}