########
# Setup for the Ansible / Jumpbox Linux machine on the network
########

#######
# Set up the NIC on the ansible and link it to our subnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
#######
resource "azurerm_network_interface" "kali-nic" {
  name                = "kali-nic"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name

  ip_configuration {
    name                          = "kali-internal-nic"
    subnet_id                     = azurerm_subnet.vulnerableADLabs-subnet.id
    private_ip_address_allocation = "static"
    private_ip_address = "10.10.10.100"
  }
}

########
# Associate the SSH in rule with this box
########
resource "azurerm_network_interface_nat_rule_association" "kali-nic-nat" {
  network_interface_id  = azurerm_network_interface.kali-nic.id
  ip_configuration_name = "kali-nic-config"
  nat_rule_id           = azurerm_lb_nat_rule.lb-ssh-nat-rule.id
}


########
# Configure the ansible jumpbox vm
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
########
resource "azurerm_linux_virtual_machine" "kali-vm" {
  name                = "kali-vm"
  computer_name = var.kali-hostname
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  size                = var.kali-size
  disable_password_authentication = false
  admin_username      = var.kali-username
  admin_password = random_password.password.result
  network_interface_ids = [
    azurerm_network_interface.kali-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 40 
  }

  source_image_reference {
    publisher = "techlatest"
    offer     = "desktop-linux-kali"
    sku       = "desktop-linux-kali"
    version   = "latest"
  }
}

########
# Obtain the variables needed to populate the windows.tmpl file
########

data "template_file" "ansible-groupvars-windows" {
  template = "${file("../Ansible/group_variables/windows_template.tmpl")}"

  depends_on = [
    var.windows-user,
    var.domain-name-dns,
    random_password.password
  ]
  
  vars = {
    username    = var.windows-user
    password    = random_password.password.result
    domain_name = var.domain-name-dns
  }
}

########
# Render the template with the above variables
########
resource "null_resource" "ansible-groupvars-windows-creation" {
  triggers = {
    template_rendered = "${data.template_file.ansible-groupvars-windows.rendered}"
  }
  
  provisioner "local-exec" {
    command = "echo '${data.template_file.ansible-groupvars-windows.rendered}' > ../Ansible/group_vars/windows.yml"
  }
}

########
# Provision using Ansible
# Triggers ensure that all VM's are ready before provisioning starts
########
resource "null_resource" "ansible-provisioning" {

  # All VMs have to be up before provisioning can be initiated, and we always trigger
  triggers = {
    always_run = "${timestamp()}"
    zion_dc_id = azurerm_windows_virtual_machine.zion-dc-vm.id
    winserv2019_id = azurerm_windows_virtual_machine.web-server-vm.id
    wkstn_1_id = azurerm_windows_virtual_machine.wkstn-1-vm.id
    wkstn_2_id = azurerm_windows_virtual_machine.wkstn-2-vm.id
    kali_id = azurerm_linux_virtual_machine.kali-vm.id
  }

  connection {
    type  = "ssh"
    host  = azurerm_public_ip.lb-public-ip.ip_address
    user  = var.kali-username
    password = random_password.password.result
  }

  provisioner "file" {
    source      = "../Ansible"
    destination = "/dev/shm"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt -qq update >/dev/null && sudo apt -qq install -y git ansible sshpass >/dev/null",
      "ansible-galaxy collection install ansible.windows community.general >/dev/null",
      "cd /dev/shm/Ansible",
      "ansible-playbook -v vulnAD.yml"
    ]
  }
}