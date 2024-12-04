# terraform-azurerm-sharepoint

This module is the Terraform version of [this public ARM template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/).  
It creates a DC, a SQL Server 2022, and from 1 to 5 server(s) hosting a SharePoint Subscription / 2019 / 2016 farm with an extensive configuration, including trusted authentication, user profiles with personal sites, an OAuth trust (using a certificate), a dedicated IIS site for hosting high-trust add-ins, etc...  
The latest version of key softwares (including Fiddler, vscode, np++, 7zip, ULS Viewer) is installed.  
SharePoint machines have additional fine-tuning to make them immediately usable (remote administration tools, custom policies for Edge and Chrome, shortcuts, etc...).

## Prerequisites

- Access to an Azure subscription.

## Usage

```terraform
module "sharepoint" {
  source                 = "Yvand/sharepoint/azurerm"
  location               = "France Central"
  subscription_id        = "<your_azure_subscription_id>"
  resource_group_name    = "<resource_group_name>"
  sharepoint_version     = "Subscription-Latest"
  admin_username         = "yvand"
  admin_password         = "<password>"
  outbound_access_method = "PublicIPAddress"
  rdp_traffic_rule       = "<your_internet_public_ip>"
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

## Outbound access to internet

During the provisionning, virtual machines require an outbound access to internet to be able to download and apply their configuration.  
The outbound access method depends on variable `outbound_access_method`:
- `PublicIPAddress`: Virtual machines use a [Public IP](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/virtual-network-public-ip-address), associated to their network card.
- `AzureFirewallProxy`: Virtual machines use [Azure Firewall](https://azure.microsoft.com/en-us/products/azure-firewall/) as an [HTTP proxy](https://learn.microsoft.com/en-us/azure/firewall/explicit-proxy).

## Remote access

The remote access to the virtual machines depends on the following parameters:

- Parameter `rdp_traffic_rule` specifies if a rule in the network security groups should allow the inbound RDP traffic:
    - `No` (default): No rule is created, RDP traffic is blocked.
    - `*` or `Internet`: RDP traffic is allowed from everywhere.
    - CIDR notation (e.g. `192.168.99.0/24` or `2001:1234::/64`) or an IP address (e.g. `192.168.99.0` or `2001:1234::`): RDP traffic is allowed from the IP address / pattern specified.
- parameter `enable_azure_bastion`:
  - if `true`: Configure service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) to allow a secure remote access to virtual machines.
  - if `false` (default): Service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) is not created.

IMPORTANT: If you set variable `outbound_access_method` to `AzureFirewallProxy`, you have to either enable Azure Bastion, or manually add a public IP address later, to be able to connect to a virtual machine.

## Input variables

- Variable `resource_group_name` is used:
  - As the name of the Azure resource group which hosts all the resources that will be created.
  - As part of the public DNS name of the virtual machines, if a public IP is created (depends on variable `add_public_ip_address`).
- Variable `sharepoint_version` lets you choose which version of SharePoint to install:
  - `Subscription-Latest` (default): Same as `Subscription-RTM`, then installs the latest cumulative update available at the time of publishing this version: November 2024 ([KB5002651](https://support.microsoft.com/help/5002651)).
  - `Subscription-24H2`: Same as `Subscription-RTM`, then installs the [Feature Update 24H2](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-24h2-release) (September 2024 CU / [kb5002640](https://support.microsoft.com/help/5002640)).
  - `Subscription-24H1`: Same as `Subscription-RTM`, then installs the [Feature Update 24H1](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-24h1-release) (March 2024 CU / [KB5002564](https://support.microsoft.com/help/5002564)).
  - `Subscription-23H2`: Same as `Subscription-RTM`, then installs the [Feature Update 23H2](https://learn.microsoft.com/en-us/SharePoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h2-release) (September 2023 CU / [KB5002474](https://support.microsoft.com/help/5002474)).
  - `Subscription-23H1`: Same as `Subscription-RTM`, then installs the [Feature Update 23H1](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h1-release) (March 2023 CU / [KB5002355](https://support.microsoft.com/help/5002355)).
  - `Subscription-22H2`: Same as `Subscription-RTM`, then installs the [Feature Update 22H2](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-22h2-release) (September 2022 CU / [KB5002270](https://support.microsoft.com/help/5002270) and [KB5002271](https://support.microsoft.com/help/5002271)).
  - `Subscription-RTM`: Uses a fresh Windows Server 2022 image, on which SharePoint Subscription RTM is downloaded and installed.
  - `2019`: Uses an image built and maintained by SharePoint Engineering, with SharePoint 2019 bits already installed.
  - `2016`: Uses an image built and maintained by SharePoint Engineering, with SharePoint 2016 bits already installed.
- Variable `front_end_servers_count` lets you add up to 4 additional SharePoint servers to the farm with the [MinRole Front-end](https://learn.microsoft.com/en-us/sharepoint/install/planning-for-a-minrole-server-deployment-in-sharepoint-server).
- Variable `enable_hybrid_benefit_server_licenses` allows you to enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost, if you are eligible. See [this page](https://docs.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing) for more information..

## Outputs

The module returns multiple variables to record the logins, passwords and the public IP address of virtual machines.

## Cost of the resources deployed

By default, virtual machines use [B-series burstable](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable), ideal for such template and much cheaper than other comparable series.  
Here is the default size and storage type per virtual machine role:

- DC: Size [Standard_B2s](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 4 GiB RAM) and OS disk is a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SQL Server: Size [Standard_B2ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 8 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SharePoint: Size [Standard_B4ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (4 vCPU / 16 GiB RAM) and OS disk is either a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint Subscription and 2019), or a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint 2016).

You can visit <https://azure.com/e/ec984bb923214cd1b8ee36d7ffc54e8e> to estimate the monthly cost of the template in the region/currency of your choice, assuming it is created using the default settings and runs 24*7.

## Known issues

- The password for the User Profile directory synchronization connection (parameter `other_accounts_password`) needs to be re-entered in the "Edit synchronization connection" page, otherwise the profile import fails (password decryption error in the logs).
- When setting `outbound_access_method` to `AzureFirewallProxy`, most of the softwares installed through Chocolatey failed to download and are not installed.
- When deploying SharePoint 2016 or 2019, the trial enterprise license has already expired, so you must enter your own in the central administration, then run iisreset and restart the SPTimerV4 service on all the servers.

## More information

Additional notes:

- Using the default options, the complete deployment takes about 1h (but it is worth it).
- Deploying any post-RTM SharePoint Subscription build adds only an extra 5-10 minutes to the total deployment time (compared to RTM), partly because the updates are installed before the farm is created.
- Once it is completed, the template will return valuable information in the 'Outputs' of the deployment.
- For various (very good) reasons, in SQL and SharePoint VMs, the name of the local (not domain) administrator is in format `"l-[admin_username]"`. It is recorded in the 'Outputs' and in the state file.
