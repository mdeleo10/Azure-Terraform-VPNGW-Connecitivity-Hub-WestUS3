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
  
# Create Public IP for VPN GW
  resource "azurerm_public_ip" "vpn_gw" {
    name                = "pip-vpn-gw-${azurerm_resource_group.rg.location}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Dynamic"
    # Standard SKU for Internal IPSec tunnel
#    sku               = "Standard"
  }
  
# Create VPN GW
  resource "azurerm_virtual_network_gateway" "vpn_gw" {
    name                = "vpn-gw-${var.resource_group_location}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
  
    type     = "Vpn"
    vpn_type = "RouteBased"
  
    active_active = false
    enable_bgp    = true
  # sku = "standard" for non-internal IPSec tunnel
 #   sku           = "VpnGw2AZ"
    sku            = "Standard"

    ip_configuration {
      name                          = "vnetGatewayConfig"
      public_ip_address_id          = azurerm_public_ip.vpn_gw.id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = azurerm_subnet.vpn_gw.id
    }

  # Adding support for Internal VPN - for example IPSec tunnel over Express Route
#    private_ip_address_enabled    = true
  
  # Define VPN Point-to-Site including address space and public cert key
    vpn_client_configuration {
      address_space = ["${var.vpn_gw_vpn_client_configuration_address_space}"]
  
      root_certificate {
        name = "DigiCert-Federated-ID-Root-CA"
  
        public_cert_data = <<EOF
  MIIDuzCCAqOgAwIBAgIQCHTZWCM+IlfFIRXIvyKSrjANBgkqhkiG9w0BAQsFADBn
  MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
  d3cuZGlnaWNlcnQuY29tMSYwJAYDVQQDEx1EaWdpQ2VydCBGZWRlcmF0ZWQgSUQg
  Um9vdCBDQTAeFw0xMzAxMTUxMjAwMDBaFw0zMzAxMTUxMjAwMDBaMGcxCzAJBgNV
  BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
  Y2VydC5jb20xJjAkBgNVBAMTHURpZ2lDZXJ0IEZlZGVyYXRlZCBJRCBSb290IENB
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvAEB4pcCqnNNOWE6Ur5j
  QPUH+1y1F9KdHTRSza6k5iDlXq1kGS1qAkuKtw9JsiNRrjltmFnzMZRBbX8Tlfl8
  zAhBmb6dDduDGED01kBsTkgywYPxXVTKec0WxYEEF0oMn4wSYNl0lt2eJAKHXjNf
  GTwiibdP8CUR2ghSM2sUTI8Nt1Omfc4SMHhGhYD64uJMbX98THQ/4LMGuYegou+d
  GTiahfHtjn7AboSEknwAMJHCh5RlYZZ6B1O4QbKJ+34Q0eKgnI3X6Vc9u0zf6DH8
  Dk+4zQDYRRTqTnVO3VT8jzqDlCRuNtq6YvryOWN74/dq8LQhUnXHvFyrsdMaE1X2
  DwIDAQABo2MwYTAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNV
  HQ4EFgQUGRdkFnbGt1EWjKwbUne+5OaZvRYwHwYDVR0jBBgwFoAUGRdkFnbGt1EW
  jKwbUne+5OaZvRYwDQYJKoZIhvcNAQELBQADggEBAHcqsHkrjpESqfuVTRiptJfP
  9JbdtWqRTmOf6uJi2c8YVqI6XlKXsD8C1dUUaaHKLUJzvKiazibVuBwMIT84AyqR
  QELn3e0BtgEymEygMU569b01ZPxoFSnNXc7qDZBDef8WfqAV/sxkTi8L9BkmFYfL
  uGLOhRJOFprPdoDIUBB+tmCl3oDcBy3vnUeOEioz8zAkprcb3GHwHAK+vHmmfgcn
  WsfMLH4JCLa/tRYL+Rw/N3ybCkDp00s0WUZ+AoDywSl0Q/ZEnNY0MsFiw6LyIdbq
  M/s/1JRtO3bDSzD9TazRVzn2oBqzSa8VgIo5C1nOnoAKJTlsClJKvIhnRlaLQqk=
  EOF
  
      }
  
      revoked_certificate {
        name       = "Verizon-Global-Root-CA"
        thumbprint = "912198EEF23DCAC40939312FEE97DD560BAE49B1"
      }
    }
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
