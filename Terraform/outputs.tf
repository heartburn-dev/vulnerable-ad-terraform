## Misc
output "region" {
  value = azurerm_resource_group.primary.location
  description = "The region in which the resources are deployed."
}

output "domain-name" {
  value = var.domain-name-dns
  description = "Domain name for the configured domain."
}

output "timezone" {
  value = var.timezone
  description = "The timezone set on the labs."
}

## Networking Outputs
output "whitelisted-ip" {
    value = var.whitelisted-ip
    description = "The IP address that can connect lab interfaces. Specified when terraforming by the user."
}

output "public-ip" {
  value = azurerm_public_ip.lb-public-ip.ip_address
  description = "The public IP address used to connect to the lab."
}

output "public-ip-dns" {
  value = azurerm_public_ip.lb-public-ip.fqdn
  description = "The public DNS name used to connect to the lab."
}

output "public-ip-outbound" {
    value = azurerm_public_ip.nat-gateway-public-ip.ip_address
    description = "Public IP for outbound traffic through the NAT gateway."
}

## Credentials and Usernames Created
output "kali-user" {
    value = var.kali-username
    description = "The SSH username used to connect to Linux machines."
}

output "windows-admin" {
    value = var.windows-user
    description = "The admin username used to connect to the Windows machine."
}

output "random-password" {
    value = random_password.password.result
    description = "The password used for admin accounts."
    sensitive = true
}

## Hostnames
output "kali-hostname" {
    value = var.kali-hostname
    description = "The hostname of the attacker/ansible VM."
}

output "dc-hostname" {
    value = var.dc-hostname
    description = "The hostname of the Domain Controller."
}

output "wkstn-1-hostname"{
    value = var.workstation-hostname[0]
    description = "The hostname of the first workstation added."
}

output "wkstn-2-hostname"{
    value = var.workstation-hostname[1]
    description = "The hostname of the second workstation added."
}

## Machine Image Sizes Used
output "workstation-size" {
  value = var.workstation-size 
  description = "The code for the size of azure image used for Windows workstations."
}

output "kali-size" {
  value = var.kali-size 
  description = "The code for the size of azure image used for the Kali box."
}

output "dc-size" {
  value = var.dc-size 
  description = "The code for the size of azure image used."
}
