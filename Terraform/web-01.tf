#######
# Terraforms the web server
#######

#######
# Set up the NIC on the web server and link it to our subnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
#######
resource "azurerm_network_interface" "web-server-nic" {
  name                = "web-server-nic"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name

  ip_configuration {
    name                          = "web-server-internal-ip"
    subnet_id                     = azurerm_subnet.vulnerableADLabs-subnet.id
    private_ip_address_allocation = "static"
    private_ip_address = "10.10.10.11"

  }
}

########
# Configure the Windows web server WEB01
# Ensure that we wait for the dc to be created first
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine
########
resource "azurerm_windows_virtual_machine" "web-server-vm" {
  name                = "web01"
  computer_name = var.web-server-hostname
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  size                = var.web-server-size
  provision_vm_agent = true
  timezone = var.timezone
  admin_username      = var.windows-user
  admin_password      = random_password.password.result
  enable_automatic_updates = false

  network_interface_ids = [
    azurerm_network_interface.web-server-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 60
  }

  source_image_reference {
    # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage
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
resource "azurerm_virtual_machine_extension" "provisioning-web-server" {
  name = "provision-web-server"
  virtual_machine_id = azurerm_windows_virtual_machine.web-server-vm.id
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
    azurerm_windows_virtual_machine.web-server-vm,
    azurerm_nat_gateway.ng
  ]
}