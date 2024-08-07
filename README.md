# terraform-azurerm-sharepoint

This module is the Terraform version of [this public ARM template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/).  
It creates a SharePoint Subscription / 2019 / 2016 farm with an extensive configuration that would take ages to perform manually, including a federated authentication with ADFS, an OAuth trust, the User Profiles service and a web application with 2 zones and multiple path based and host-named site collections.  
On the SharePoint virtual machines, [Chocolatey](https://chocolatey.org/) is used to install the latest version of Notepad++, Visual Studio Code, Azure Data Studio, Fiddler, ULS Viewer and 7-Zip.

## Prerequisites

- Access to an **Azure subscription**.

## Usage

```terraform
module "sharepoint" {
  source               = "Yvand/sharepoint/azurerm"
  location              = "West Europe"
  resource_group_name   = "<resourceGroupName>"
  sharepoint_version    = "Subscription-Latest"
  admin_username        = "yvand"
  admin_password        = "<password>"
  add_public_ip_address = "SharePointVMsOnly"
  rdp_traffic_allowed   = "<yourInternetPublicIP>"
}
```

## Features

There are some differences in the configuration, depending on the SharePoint version:

### Common to all SharePoint versions

- An Active Directory forest with AD CS and AD FS configured. LDAPS (LDAP over SSL) is also configured.
- SharePoint service applications configured: User Profiles, add-ins, session state.
- SharePoint User Profiles service is configured with a directory synchronization connection, and the MySite host is a host-named site collection.
- SharePoint has 1 web application with path based and host-named site collections, and contains 2 zones:
  - Default zone: HTTP using Windows authentication.
  - Intranet zone: HTTPS using federated (ADFS) authentication.
- An OAuth trust is created, as well as a custom IIS site to host your high-trust add-ins.
- Custom claims provider [LDAPCP](https://www.ldapcp.com/) is installed and configured.

### Specific to SharePoint Subscription

- SharePoint virtual machines are created using the latest disk image of [Windows Server 2022 Azure Edition](https://learn.microsoft.com/windows-server/get-started/editions-comparison-windows-server-2022) available, and SharePoint binaries (install + cumulative updates) are downloaded and installed from scratch.
- The HTTPS site certificate is managed by SharePoint, which has the private key and sets the binding itself in the IIS site.
- Federated authentication with ADFS is configured using OpenID Connect.

### Specific to SharePoint 2019 / 2016

- SharePoint virtual machines are created using a disk image built and maintained by SharePoint Engineering.
- The HTTPS site certificate is positioned by the DSC script.
- Federated authentication with ADFS is configured using SAML 1.1.

## Key variables

### Input variables

- Variable `resource_group_name` is used:
  - As the name of the Azure resource group which hosts all the resources that will be created.
  - As part of the public DNS name of the virtual machines, if a public IP is created (depends on variable `add_public_ip_address`).
- Variable `sharepoint_version` lets you choose which version of SharePoint to install:
  - `Subscription-Latest` (default): Same as `Subscription-RTM`, then installs the latest cumulative update available at the time of publishing this version: July 2024 ([kb5002606](https://support.microsoft.com/help/5002606)).
  - `Subscription-24H1`: Same as `Subscription-RTM`, then installs the [Feature Update 24H1](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-24h1-release) (March 2024 CU / [KB5002564](https://support.microsoft.com/help/5002564)).
  - `Subscription-23H2`: Same as `Subscription-RTM`, then installs the [Feature Update 23H2](https://learn.microsoft.com/en-us/SharePoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h2-release) (September 2023 CU / [KB5002474](https://support.microsoft.com/help/5002474)).
  - `Subscription-23H1`: Same as `Subscription-RTM`, then installs the [Feature Update 23H1](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h1-release) (March 2023 CU / [KB5002355](https://support.microsoft.com/help/5002355)).
  - `Subscription-22H2`: Same as `Subscription-RTM`, then installs the [Feature Update 22H2](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-22h2-release) (September 2022 CU / [KB5002270](https://support.microsoft.com/help/5002270) and [KB5002271](https://support.microsoft.com/help/5002271)).
  - `Subscription-RTM`: Uses a fresh Windows Server 2022 image, on which SharePoint Subscription RTM is downloaded and installed.
  - `2019`: Uses an image built and maintained by SharePoint Engineering, with SharePoint 2019 bits already installed.
  - `2016`: Uses an image built and maintained by SharePoint Engineering, with SharePoint 2016 bits already installed.
- Variables `addPublicIPAddress` and `rdp_traffic_allowed`: See [this section](#remote-access-and-security) for detailed information.
- Variable `number_additional_frontend` lets you add up to 4 additional SharePoint servers to the farm with the [MinRole Front-end](https://learn.microsoft.com/en-us/sharepoint/install/planning-for-a-minrole-server-deployment-in-sharepoint-server).
- Variable `enable_hybrid_benefit_server_licenses` allows you to enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost, if you are eligible. See [this page](https://docs.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing) for more information..

### Output variables

The module returns multiple variables to record the logins, passwords and the public IP address of virtual machines.

## Remote access and security

The template creates 1 virtual network with 3 subnets (+1 if [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) is enabled), and each subnet is protected by a [Network Security Group](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview) which denies all incoming traffic by default.  
The following variables configure how to connect to the virtual machines, and the level of network security:

- Variables `admin_password` and `service_accounts_password` require a [strong password](https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-) with **at least 8 characters**, or they can be left empty to use an auto-generated password that will be recorded in the state file.
- Variable `addPublicIPAddress`:
  - if `"SharePointVMsOnly"` (default): Only SharePoint virtual machines get a public IP address with a DNS name and can be reached from Internet.
  - If `"Yes"`: All virtual machines get a public IP address with a DNS name, and can be reached from Internet.
  - if `"No"`: No public IP resource is created.
  - The DNS name format of virtual machines is `"[resource_group_name]-[vm_name].[region].cloudapp.azure.com"` and is recorded as output in the state file.
- Variable `rdp_traffic_allowed` specifies if RDP traffic is allowed:
  - If `"No"` (default): Firewall denies all incoming RDP traffic.
  - If `"*"` or `"Internet"`: Firewall accepts all incoming RDP traffic from Internet (very, very much not recommended) (but hey you are the boss).
  - If CIDR notation (e.g. `"192.168.99.0/24"` or `"2001:1234::/64"`) or IP address (e.g. `"192.168.99.0"` or `"2001:1234::"`): Firewall accepts incoming RDP traffic from the IP addresses specified.
- Variable `enable_azure_bastion`:
  - if `true`: Configure service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) to allow a secure remote access to virtual machines.
  - if `false` (default): Service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) is not created.

## Cost of the resources deployed

By default, virtual machines use [B-series burstable](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable), ideal for such template and much cheaper than other comparable series.  
Here is the default size and storage type per virtual machine role:

- DC: Size [Standard_B2s](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 4 GiB RAM) and OS disk is a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SQL Server: Size [Standard_B2ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 8 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SharePoint: Size [Standard_B4ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (4 vCPU / 16 GiB RAM) and OS disk is either a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint Subscription and 2019), or a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint 2016).

You can visit <https://azure.com/e/c494029b0b034b8ca356c926dfd2688a> to estimate the monthly cost of the template in the region/currency of your choice, assuming it is created using the default settings and runs 24*7.

## Known issues

- The password for the User Profile directory synchronization connection (value of parameter `service_accounts_password`) needs to be re-entered in the "Edit synchronization connection" page, otherwise the import fails (password decryption error).

## More information

Additional notes:

- Using the default options, the complete deployment takes about 1h15 (but it is worth it).
- Deploying any post-RTM SharePoint Subscription build adds only an extra 5-10 minutes to the total deployment time (compared to RTM), partly because the updates are installed before the farm is created.
- Once it is completed, the template will return valuable information in the 'Outputs' of the deployment.
- For various (very good) reasons, in SQL and SharePoint VMs, the name of the local (not domain) administrator is in format `"l-[admin_username]"`. It is recorded in the 'Outputs' and in the state file.
