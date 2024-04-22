# Azure-Terraform-VPNGW-Hub-EastUS

This Azure Terraform template creates in Azure a VPN Gateway, the connectivity hub vnet and a local network gateway connection for Site-to-Site using BGP

While this creates a single VNET, it can serve as a connectivity hub for the following:
- Part of a hub and spoke model between vnets - yes the VPN GW can serve as an hub router if needed, but there are other choices as well
- Connectivity to offsite via a VPN connection for Site-to-Site or Point-to-Site
- To increase the security and make this a "Secure Hub" an Azure FW or third party NVA can be added
- This is a simple example, refer to Azure's Enterprise Scale Landing Zone Architecture for a better enterprise scale implementation with recommended best practices aadditional features in a production environment - see https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
- Since connectivity hubs are typically region based for high availability purposes and cost management. A similar deployment might be used for another region

It has the following variables defined in the file variables.rf
- Resource Group Name
- Resource Region Location
- Vnet Address Space
- VPN GW Subnet Address Space
- VPN GW Client P2S Subnet Address Space
- Remote IPv4 address external peering
- Remote IPv4 address space
- Remote BGP ASN (default is a private ASN)
- Remote IPv4 address bgp peering - internal address
- IPSec Shared Key
- The active-active is turned on to support redundant tunnels (and gateways)
- private_ip_address_enabled is set to true, this allows  visiblity the internal IP address to deploy IPSec tunnel over Express Route (or demo vnets)

TBD:
Guthub is setup for a workflow to to run Actions upon code change (push). It will deploy/redeploy as needed. Check the .github/workflows folder to see it if needed.

## Prerequistes:

Action Secrets:
- AZURE_AD_CLIENT_ID (Service Principal)
- AZURE_AD_CLIENT_SECRET (Service Principal Password)
- AZURE_AD_TENANT_ID
- AZURE_SUBSCRIPTION_ID

### Note: The Service Principal needs to have the RBAC rights over the subscription to 
- Create a Resource Group
- Create A Vnet and subnet
- Create Public IP address
- Create NSG
- Create a VPNGW and Local Network Gateway

### Note 2: Also needed access to the existing Resource Group rg-terraform-state-001 for the following:
- Storage Account and IAM access, for example contributor, for cloudmdterraformstate in RG rg-terraform-state-001.
- Key Vault kv-terraform-script-001 in RG rg-terraform-state-001, with secret "sshIDpub" in the ssh public key string format example "ssh-rsa KKKKKKeyKKKKK userid@xxx.com". Note need to add IAM access, for example Key Vault Administrator to access and read keys 

### See     .github/workflows/terraform.yml file for Action execution

### Note on deployment time: Creating a virtual network gateway can take up to **30 minutes** to complete.

### Post VPN Gateway creation

- Once the VPN gateway is successfully deployed, the remote IPSec router/firewall/gateway needs to be configured for the Site-to-Site termination. The major vendors (Cisco, Juuniper, Generic Samples, Sentrium, Ubiquiti, Allied Telesis, etc.) configurations can be dowloaded from the Resource Group/Connection then under the tab section use Download configuration. This should work to configure the remote network device.

## For Point-to-Site use, see ..

# References:
- [Azure Cloud Adoption Framework - Enterprise Scale Landing Zone Architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone)
- [Terraform Registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/point_to_site_vpn_gateway)
- [Virtual network Gateway](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways)
- [Terraform AzureRM Provider Documentation](https://www.terraform.io/docs/providers/azurerm/index.html)
- https://github.com/kumarvna/terraform-azurerm-vpn-gateway/
- [Configuring Multiple IPSec VPN Tunnels with BGP Between Cisco CSR 1000v and Azure VPN Gateway](https://github.com/jocortems/azurehybridnetworking/tree/main/Multiple-VPN-Tunnels-From-CiscoCSR-to-AzureVNG) See also the Introduction about IPSec discussion




