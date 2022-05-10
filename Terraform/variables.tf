variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
  default     = "vulnerableADLab"
}

variable "resource_group_vnet_name" {
  type        = string
  description = "Name of the virtual network resource group."
  default     = "vulnerableADLab_vnet"
}

variable "domain-name" {
  type        = string
  description = "Domain name of the labs."
  default     = "matrix"
}

variable "domain-name-dns" {
  type        = string
  description = "DNS name of the AD lab."
  default     = "matrix.local"
}

variable "whitelisted-ip" {
  type        = string
  description = "Enter your public IPv4. Obtain it at http://ipv4.icanhazip.com/. This is the IP that we create the terraform from will be whitelisted for access to the external IP's."
}

variable "timezone" {
  type        = string
  description = "Default timezone being set on the labs."
  default     = "GMT Standard Time"
}

variable "dc-hostname" {
  type        = string
  description = "Hostname of the domain controller."
  default     = "ZION-DC01"
}

variable "workstation-hostname" {
  type        = list(string)
  description = "Hostnames of the client machines in the matrix domain."
  default     = ["WKSTN-01", "WKSTN-02"]
}

variable "kali-hostname" {
  type        = string
  description = "Name of the attacking machine."
  default     = "MACHINES"
}

variable "kali-username" {
  type        = string
  description = "Account on the attacking machine used to access the infrasucture."
  default     = "smith"
}

variable "windows-user" {
  type        = string
  description = "User account for the Administrative duties on the Windows workstations."
  default     = "trinity" 
}

variable "region" {
  type        = string
  description = "Location of Azure infrastructure."
  default     = "ukwest"
}

variable "dc-size" {
  type        = string
  description = "The machine size of the Windows Server 2019 DC VM."
  default     = "Standard_D2as_v4"
}

variable "workstation-size" {
  type        = string
  description = "The machine size of the Windows 10 VM."
  default     = "Standard_B2s"
}

variable "kali-size" {
  type        = string
  description = "The machine size of the jumpbox VM."
  default     = "Standard_F2"
}

locals {
  first_logon_commands = file("${path.module}/scripts/FirstLogonCommands.xml")
  autologon_data = "<AutoLogon><Password><Value>${random_password.password.result}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.windows-user}</Username></AutoLogon>"
}