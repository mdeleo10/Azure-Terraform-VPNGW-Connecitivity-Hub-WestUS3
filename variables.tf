
variable "resource_group_name_prefix" {
  default       = "Connectivity-Hub"
  description   = "Prefix of the resource group name that's combined with a region"
}

variable "resource_group_location" {
  default       = "westus3"
  description   = "Location of the resource group."
}

variable "vnet_address_space" {
  default       = "10.113.0.0/16"
  description   = "Vnet Address Space"
}

variable "vpn_gw_GatewaySubnet_address"  {
  default       = "10.113.3.0/24"
  description   = "VPN GW Subnet Address Space"
}

variable "vpn_gw_vpn_client_configuration_address_space"  {
  default       = "10.114.2.0/24"
  description   = "VPN GW Client P2S Subnet Address Space"
}

variable remote_gateway_address {
  default       = "73.138.235.109"  
  description   = "Remote IPv4 address external peering"
}

variable remote_gateway_address_space {
  default       = "192.168.0.0/16"  
  description   = "Remote IPv4 address space"
}

variable remote_bgp_asn {
  default       = 65200
  description    = "Remote BGP ASN"
}

variable remote_bgp_peering_address {
  default       = "192.168.99.1" 
  description   = "Remote IPv4 address bgp peering - internal address"
}

variable home_connection_shared_key {
  default       = "92234411ABC1234ab" 
  description   = "IPSec Shared Key"
}