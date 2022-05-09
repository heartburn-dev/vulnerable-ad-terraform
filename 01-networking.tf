########
# NETWORKING INFORMATION FOR THE VULNERABLE DOMAIN
# Gets public IP of the machine that the terraform is being run from
# Applies relevant firewall rules and allows the whitelisted IP to access the network
########

########
# Create our resource group
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
########
resource "azurerm_resource_group" "primary" {
  name     = var.resource_group_name
  location = var.region
}

########
# Create a virtual network
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
######## 
resource "azurerm_virtual_network" "vnet" {
  name                = var.resource_group_vnet_name
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
}

########
# Create our subnet that the network will reside on
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
########
resource "azurerm_subnet" "vulnerableADLabs-subnet" {
  name = "vulnerableADLabsSubnet"
  address_prefixes     = ["10.10.10.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.primary.name
}

########
# Set up network security groups for traffic filtering
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
########
resource "azurerm_network_security_group" "nsg" {
  name                = "Network Security Group Policies"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name

  security_rule {
    name                       = "SSH In"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    # Allow only from our whitelisted IP
    # concat allows us to set the whitelisted-ip variable dynamically
    # chomp removes newlines at the end of a string, since we're pulling it from the body of http://ipv4.icanhazip.com
    # You can query if it was set correctly by comparing your public IP with 'terraform output whitelisted-ip'
    source_address_prefix      = var.whitelisted-ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP In"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.whitelisted-ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS In"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.whitelisted-ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP In"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.whitelisted-ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Internal Traffic (Unrestricted)"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    # Allow anyone on our subnet unrestricted TCP traffic internally
    source_address_prefix      = azurerm_subnet.vulnerableADLabs-subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

########
# Associate the network security group rules with the subnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
########
resource "azurerm_subnet_network_security_group_association" "association" {
  subnet_id                 = azurerm_subnet.vulnerableADLabs-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

########
# Set up our public IPs for the Load Balancer and outbound NAT gateway
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb
########
resource "azurerm_public_ip" "lb-public-ip" {
  name                = "loadbalancerPublicIP"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  domain_name_label   = var.domain-name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "nat-gateway-public-ip" {
  name                = "gatewayNATPublicIP"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  allocation_method   = "Static"
}

########
# Set up our Load Balancer and NAT rules
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_nat_rule
########
resource "azurerm_lb" "lb" {
  name                = "loadbalancer"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.lb-public-ip.name
    public_ip_address_id = azurerm_public_ip.lb-public-ip.id
  }
}

resource "azurerm_lb_nat_rule" "lb-rdp-nat-rule" {
  resource_group_name            = azurerm_resource_group.primary.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "RDPAccess"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = azurerm_public_ip.lb-public-ip.name
}

resource "azurerm_lb_nat_rule" "lb-http-nat-rule" {
  resource_group_name            = azurerm_resource_group.primary.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "HTTPAccess"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_public_ip.lb-public-ip.name
}

resource "azurerm_lb_nat_rule" "lb-https-nat-rule" {
  resource_group_name            = azurerm_resource_group.primary.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_public_ip.lb-public-ip.name
}

resource "azurerm_lb_nat_rule" "lb-ssh-nat-rule" {
  resource_group_name            = azurerm_resource_group.primary.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "SSHAccess"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_public_ip.lb-public-ip.name
}

######## 
# Configure the NAT gateway
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway
########
resource "azurerm_nat_gateway" "ng" {
  name                    = "nat-gateway"
  location                = azurerm_resource_group.primary.location
  resource_group_name     = azurerm_resource_group.primary.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

######## 
# Associate subnets and public IPs with eachother
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association
########
resource "azurerm_nat_gateway_public_ip_association" "nga" {
  nat_gateway_id       = azurerm_nat_gateway.ng.id
  public_ip_address_id = azurerm_public_ip.nat-gateway-public-ip.id
}

resource "azurerm_subnet_nat_gateway_association" "snga" {
  subnet_id      = azurerm_subnet.vulnerableADLabs-subnet.id
  nat_gateway_id = azurerm_nat_gateway.ng.id
}