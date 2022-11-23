# terraform-azurerm-sharepoint

This module is the Terraform version of [this public ARM template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/), and can create a SharePoint Subscription / 2019 / 2016 / 2013 farm with a web application set with Windows and ADFS authentication, and some path based and host-named site collections. It also provisions User Profiles and Apps service applications and installs claims provider LDAPCP.

## Prerequisites

- Access to an **Azure subscription**.

## Usage

```terraform
module "sharepoint" {
  source                     = "Yvand/sharepoint/azurerm"
  version                    = ">=3.0.0"

  # Below are the main variables, other variables can also be set
  location                   = "West Europe"
  resource_group_name        = "<resourceGroupName>"
  sharepoint_version         = "Subscription-22H2"
  admin_username             = "yvand"
  admin_password             = "<password>"
}
```

## Features

Regardless of the SharePoint version selected, an extensive configuration is performed, with some differences depending on the version:

### Common to all SharePoint versions

- Active Directory forest created, AD CS and AD FS are installed and configured. LDAPS (LDAP over SSL) is also conigured.
- SharePoint service applications configured: User Profile, add-ins, session state.
- SharePoint has 1 web application with path based and host-named site collections. There are 2 zones:
  - Default zone: HTTP with Windows authentication.
  - Intranet zone: HTTPS with federated (ADFS) authentication. Custom claims provider [LDAPCP](https://www.ldapcp.com/) is installed and configured.
- An OAuth trust is created, and a dedicated IIS site is created with 2 bindings (HTTP + HTTPS) to host custom high-trust add-ins.

### Specific to SharePoint Subscription

- HTTPS site certificate is managed by SharePoint: It has the private key and sets the binding itself in the IIS site
- Federated authentication with ADFS is configured using OpenID Connect

### Specific to SharePoint 2019 / 2016 / 2013

- Federated authentication with ADFS is configured using SAML 1.1

## Key variables

### Input variables

- Variable `resource_group_name` is used:
  - As the name of the Azure resource group which hosts all the resources that will be created.
  - As part of the public DNS name of the virtual machines, if a public IP is created.
- Variable `sharepoint_version` lets you choose which version of SharePoint to install:
  - `Subscription-22H2` (default): Uses a fresh Windows Server 2022 image, on which SharePoint Subscription RTM is downloaded and installed, and then the [Feature Update 22H2](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-22h2-release) (September 2022 CU) is also downloaded and installed. Installing this update adds an extra 12-15 minutes to the total deployment time.
  - `Subscription-RTM`: Uses a fresh Windows Server 2022 image, on which SharePoint Subscription RTM is downloaded and installed.
  - `2019`: Uses an image built and maintained by SharePoint Engineering, with SharePoint 2019 bits installed.
  - `2016`: Uses an image built and maintained by SharePoint Engineering, with SharePoint 2016 bits installed.
  - `2013`: Uses an image built and maintained by SharePoint Engineering, with SharePoint 2013 bits installed.
- Variables `admin_password` and `service_accounts_password` require a [strong password](https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-), but they can be left empty to use an auto-generated password that will be recorded in state file.
- Variables `addPublicIPAddress` and `rdp_traffic_allowed`: See [this section](#remote-access-and-security) for detailed information.
- Variable `number_additional_frontend` lets you add up to 4 additional SharePoint servers to the farm with the [MinRole Front-end](https://learn.microsoft.com/en-us/sharepoint/install/planning-for-a-minrole-server-deployment-in-sharepoint-server) (except on SharePoint 2013, which does not support MinRole).
- Variable `enable_hybrid_benefit_server_licenses` allows you to enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost, if you are eligible. See [this page](https://docs.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing) for more information..

### Output variables

Valuable output variables are returned by the module and recorded in the state file, including the login, passwords and the public IP address of each virtual machine.

## Remote access and security

The template creates 1 virtual network with 3 subnets (+1 if [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) is enabled), and each subnet is protected by a [Network Security Group](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview) which denies all incoming traffic by default.  
Use the following variables to configure how to connect to the virtual machines, and the level of network security:

- Variable `addPublicIPAddress`:
  - if `"SharePointVMsOnly"` (default): Only SharePoint virtual machines get a public IP address with a DNS name and can be reached from Internet.
  - If `"Yes"`: All virtual machines get a public IP address with a DNS name, and can be reached from Internet.
  - if `"No"`: No public IP resource is created.
  - The DNS name format of virtual machines is `"[resource_group_name]-[vm_name].[region].cloudapp.azure.com"` and is recorded as output in the state file.
- Variable `rdp_traffic_allowed` specifies if RDP traffic is allowed:
  - If `"No"` (default): Firewall denies all incoming RDP traffic.
  - If `"*"` or 'Internet': Firewall accepts all incoming RDP traffic from Internet.
  - If CIDR notation (e.g. `"192.168.99.0/24"` or `"2001:1234::/64"`) or IP address (e.g. `"192.168.99.0"` or `"2001:1234::"`): Firewall accepts incoming RDP traffic from the IP addresses specified.
- Variable `enable_azure_bastion`:
  - if `true`: Configure service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) to allow a secure remote access to virtual machines.
  - if `false` (default): Service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) is not created.

## Cost of the resources deployed

By default, virtual machines use [B-series burstable](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable), ideal for such template and much cheaper than other comparable series.  
Here is the default size and storage type per virtual machine role:

- DC: Size [Standard_B2s](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 4 GiB RAM) and OS disk is a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SQL Server: Size [Standard_B2ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 8 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SharePoint: Size [Standard_B4ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (4 vCPU / 16 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).

You can visit <https://azure.com/e/c86a94bb7e3943fe96e2c71cf8ece33a> to view the monthly cost of the template, assuming it is using the default settings and running 24*7, in the region/currency of your choice.

## More information

Additional notes:

- Using the default options, the complete deployment takes about 1h (but it is worth it).
- Once it is completed, the template will return valuable information in the 'Outputs' of the deployment.
- For various (very good) reasons, in SQL and SharePoint VMs, the name of the local (not domain) administrator is in format `"local-[admin_username]"`. It is recorded in the 'Outputs' and in the state file.
