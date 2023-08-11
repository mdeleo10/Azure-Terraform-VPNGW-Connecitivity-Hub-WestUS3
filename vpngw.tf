# Terraform GitHub storage account for state output
#
#
# Create Storage Account Container
# Suggestion: create tfstate-repo-name, needs to be lower case only
#
# az storage container create -n tftstate-azure-terraform-vpngw-connecitivity-hub-eastus --account-name  cloudmdterraformstate
#
terraform {
  backend "azurerm" {
    resource_group_name     = "rg-terraform-state-001"
    storage_account_name    = "cloudmdterraformstate"
    container_name          = "tftstate-azure-terraform-vpngw-connecitivity-hub-westus3"
    key                     = "tfstate"
  }
}

# Define Resource Group Name, including the Azure Region
  resource "azurerm_resource_group" "rg" {
    name      = "rg-${var.resource_group_name_prefix}-${var.resource_group_location}"
    location  = var.resource_group_location
    tags = {
        Source = "terraform"
        Environment = "development"
        CreatedDate = timestamp()
    }
  }

# Create VNET for the Azure Region
  resource "azurerm_virtual_network" "vpn_gw" {
    name                = "vnet-${var.resource_group_name_prefix}-${var.resource_group_location}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = ["${var.vnet_address_space}"]
  }
  
# Create VPN GW Subnet
  resource "azurerm_subnet" "vpn_gw" {
    name                 = "GatewaySubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vpn_gw.name
    address_prefixes     = ["${var.vpn_gw_GatewaySubnet_address}"]
  }
  
# Create Public IP 1 for VPN GW
  resource "azurerm_public_ip" "pip-gateway_1" {
    name                = "pip-1-vpn-gw-${azurerm_resource_group.rg.location}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
#    allocation_method = "Dynamic"
    allocation_method = "Static"
  
    # Standard SKU for Internal IPSec tunnel
    sku               = "Standard"
    zones             = ["1"]
  }

# Create Public IP 2 for VPN GW
  resource "azurerm_public_ip" "pip-gateway_2" {
    name                = "pip-2-vpn-gw-${azurerm_resource_group.rg.location}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
#    allocation_method = "Dynamic"
    allocation_method = "Static"
  
    # Standard SKU for Internal IPSec tunnel
    sku               = "Standard"
    zones             = ["2"]
  }

# Create VPN GW
  resource "azurerm_virtual_network_gateway" "vpn_gw" {
    name                = "vpn-gw-${var.resource_group_location}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
  
    type     = "Vpn"
    vpn_type = "RouteBased"
  
    active_active = true
    enable_bgp    = true
  # sku = "standard" for non-internal IPSec tunnel
    sku           = "VpnGw2AZ"
 #   sku            = "Standard"

    ip_configuration {
      name                          = "vnetGatewayConfig"
      public_ip_address_id          = azurerm_public_ip.pip-gateway_1.id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = azurerm_subnet.vpn_gw.id
    }

    ip_configuration {
      name                          = "vnetGatewayConfig2"
      public_ip_address_id          = azurerm_public_ip.pip-gateway_2.id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = azurerm_subnet.vpn_gw.id
    }


# Adding support for Internal VPN - for example IPSec tunnel over Express Route
    private_ip_address_enabled    = true

}
  
# Create and define Local Network Gateway for Site-to-Site connection with BGP to external IP address
resource "azurerm_local_network_gateway" "remote_net" {
    name                = "local-network-gateway-remote-${azurerm_resource_group.rg.location}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    gateway_address     = "${var.remote_gateway_address}" #--Your local device public IP here
    address_space       = ["${var.remote_gateway_address_space}"] #--Remote Address Space
    bgp_settings {
        asn             = "${var.remote_bgp_asn}"
        peer_weight = 0    
        bgp_peering_address = "${var.remote_bgp_peering_address}"
      }
}

# Create IPSec connection to remote network
resource "azurerm_virtual_network_gateway_connection" "remote_connection" {
    name                       = "vpn-connection-remote-net"
    location                   = azurerm_resource_group.rg.location
    resource_group_name        = azurerm_resource_group.rg.name
    type                       = "IPsec"
    virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gw.id
    local_network_gateway_id   = azurerm_local_network_gateway.remote_net.id
    shared_key                 = "${var.home_connection_shared_key}"
    enable_bgp                 = true
}
