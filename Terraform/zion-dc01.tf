#######
# Terraforms the domain controller
#######

#######
# Set up the NIC on the DC and link it to our subnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
#######
resource "azurerm_network_interface" "zion-dc-nic" {
  name                = "zion-dc-nic"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name

  ip_configuration {
    name                          = "zion-dc-internal-ip"
    subnet_id                     = azurerm_subnet.vulnerableADLabs-subnet.id
    private_ip_address_allocation = "static"
    private_ip_address = "10.10.10.10"

  }
}

########
# Configure the Windows DC machine ZION-DC01
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine
########
resource "azurerm_windows_virtual_machine" "zion-dc-vm" {
  name                = "zion-dc01"
  computer_name = var.dc-hostname
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  size                = var.dc-size
  provision_vm_agent = true
  timezone = var.timezone
  admin_username      = var.windows-user
  admin_password      = random_password.password.result
  enable_automatic_updates = false
  

  network_interface_ids = [
    azurerm_network_interface.zion-dc-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 60
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
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
resource "azurerm_virtual_machine_extension" "provisioning-zion-dc" {
  name = "provision-zion-dc"
  virtual_machine_id = azurerm_windows_virtual_machine.zion-dc-vm.id
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
    azurerm_windows_virtual_machine.zion-dc-vm,
    azurerm_nat_gateway.ng
  ]
}