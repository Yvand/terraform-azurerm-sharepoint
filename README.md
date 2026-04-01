# terraform-azurerm-sharepoint

This module creates a highly customizable SharePoint Subscription / 2019 / 2016 farm, where you define the accounts password (it can be randomly generated), the AD domain and admin account names, and how much SharePoint configuration is performed.  
The Azure resources are provisioned using [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/), and the virtual machines are configured from scratch using the DSC configuration files in [project SharePointInfraDsc](https://github.com/Yvand/SharePointInfraDsc).  

The virtual machines for the DC and SharePoint Subscription use the latest image of [Windows Server 2025 Datacenter: Azure Edition](https://marketplace.microsoft.com/en-us/product/microsoftwindowsserver.windowsserver?tab=PlansAndPrice), and SQL uses [SQL Server 2025 Standard Developer on Windows Server 2025](https://marketplace.microsoft.com/en-us/product/microsoftsqlserver.sql2025-ws2025?tab=PlansAndPrice), so they are always up-to-date when deployed.  
Note: The legacy versions of SharePoint use images published by SharePoint Engineering ([2016](https://marketplace.microsoft.com/en-us/product/sharepointserver.2016?tab=Overview) and [2019](https://marketplace.microsoft.com/en-us/product/sharepointserver.2019?tab=Overview)) which are outdated (and those versions are deprecated).

## Prerequisites

- An Azure subscription with at least the Azure role [**Contributor**](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#contributor), to create the resources (including a resource group).
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest).

## Usage

```terraform
module "sharepoint" {
  source                         = "Yvand/sharepoint/azurerm"
  location                       = "francecentral"
  subscription_id                = "<your_azure_subscription_id>"
  resource_group_name            = "<your_resource_group_name>"
  sharepoint_version             = "Subscription-Latest"
  sharepoint_configuration_level = "Medium"
  front_end_servers_count        = 0
  domain_fqdn                    = "contoso.local"
  admin_username                 = "yvand"
  admin_password                 = "<password>"
  outbound_access_method         = "PublicIPAddress"
  rdp_traffic_rule               = "<your_internet_public_ip>"
}
```

## SharePoint configuration

- Variable `sharepoint_version` sets which version of SharePoint will be installed:
  - `Subscription-Latest` (default): latest cumulative update available at the time of publishing this version: March 2026 ([KB5002843](https://support.microsoft.com/help/5002843)).
  - `Subscription-25H2`: [Feature Update 25H2](https://learn.microsoft.com/sharepoint/what-s-new/new-improved-features-sharepoint-server-subscription-edition-2025-h2-release) (September 2025 CU / [KB5002784](https://support.microsoft.com/help/5002784)).
  - `Subscription-25H1`: [Feature Update 25H1](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-25h1-release) (March 2025 CU / [KB5002698](https://support.microsoft.com/help/5002698)).
  - `Subscription-24H2`: [Feature Update 24H2](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-24h2-release) (September 2024 CU / [kb5002640](https://support.microsoft.com/help/5002640)).
  - `Subscription-24H1`: [Feature Update 24H1](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-24h1-release) (March 2024 CU / [KB5002564](https://support.microsoft.com/help/5002564)).
  - `Subscription-23H2`: [Feature Update 23H2](https://learn.microsoft.com/SharePoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h2-release) (September 2023 CU / [KB5002474](https://support.microsoft.com/help/5002474)).
  - `Subscription-23H1`: [Feature Update 23H1](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h1-release) (March 2023 CU / [KB5002355](https://support.microsoft.com/help/5002355)).
  - `Subscription-22H2`: [Feature Update 22H2](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-22h2-release) (September 2022 CU / [KB5002270](https://support.microsoft.com/help/5002270) and [KB5002271](https://support.microsoft.com/help/5002271)).
  - `Subscription-RTM`: SharePoint Subscription RTM available for [public download](https://www.microsoft.com/en-us/download/details.aspx?id=103599).
  - `2019` (deprecated): Uses the [image](https://marketplace.microsoft.com/en-us/product/sharepointserver.2019?tab=Overview) built and maintained by SharePoint Engineering.
  - `2016` (deprecated): Uses the [image](https://marketplace.microsoft.com/en-us/product/sharepointserver.2016?tab=Overview) built and maintained by SharePoint Engineering.
- Variable `sharepoint_configuration_level` sets how much configuration is done:
  - `Minimum`: Creates a web application with its default zone only
  - `Light`: Everything in `Minimum` and:
    - Provisions the State Service Application
    - Configures the trusted authentication
  - `Medium`: Everything in `Light` and:
    - Provisions the User Profile Service Application
    - Extends the web application in zone `Intranet`
  - `Full`: Everything in `Medium` and:
    - Configures all the resources to run and deploy add-ins
    - Create addditional host-named site collections
- Variable `default_zone_must_be_https`: `true` if the default zone must use HTTPS, `false` if it may use HTTP (if compatible with the configuration selected).
- Variable `front_end_servers_count` lets you add up to 4 additional SharePoint servers to the farm with the [MinRole Front-end](https://learn.microsoft.com/sharepoint/install/planning-for-a-minrole-server-deployment-in-sharepoint-server).

## Outbound access to internet

During the provisionning, virtual machines require an outbound access to internet to be able to download and apply their configuration.  
The outbound access method depends on variable `outbound_access_method`:
- `PublicIPAddress`: Virtual machines use a [Public IP](https://learn.microsoft.com/azure/virtual-network/ip-services/virtual-network-public-ip-address), associated to their network card.
- `AzureFirewallProxy`: Virtual machines use [Azure Firewall](https://azure.microsoft.com/products/azure-firewall/) as an [HTTP proxy](https://learn.microsoft.com/azure/firewall/explicit-proxy).

## Remote access

The remote access to the virtual machines depends on the following variables:

- Variable `rdp_traffic_rule` specifies if a rule in the network security groups should allow the inbound RDP traffic:
    - `No` (default): No rule is created, RDP traffic is blocked.
    - `*` or `Internet`: RDP traffic is allowed from everywhere.
    - CIDR notation (e.g. `192.168.99.0/24` or `2001:1234::/64`) or an IP address (e.g. `192.168.99.0` or `2001:1234::`): RDP traffic is allowed from the IP address / pattern specified.
- Variable `enable_azure_bastion`:
  - if `true`: Configure service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) with Basic SKU, to allow a secure remote access to virtual machines.
  - if `false` (default): Service [Azure Bastion](https://azure.microsoft.com/services/azure-bastion/) is not created.

IMPORTANT: If you set variable `outbound_access_method` to `AzureFirewallProxy`, you have to either enable Azure Bastion, or manually add a public IP address later, to be able to connect to a virtual machine.

## Other input variables

- Variable `resource_group_name` is used:
  - As the name of the Azure resource group which hosts all the resources that will be created.
  - As part of the public DNS name of the virtual machines, if a public IP is created (depends on variable `add_public_ip_address`).

- Variable `enable_hybrid_benefit_server_licenses` allows you to enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost, if you are eligible. See [this page](https://docs.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing) for more information..

## Outputs

The module returns multiple variables to record the logins, passwords and the public IP address of virtual machines.

## Cost of the resources deployed

By default, virtual machines use [Basv2 series](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series), ideal for such template and much cheaper than other comparable series.  
Here is the default size and storage type per virtual machine role:

- DC: Size [Standard_B2als_v2](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series) (2 vCPU / 4 GiB RAM) and OS disk is a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SQL Server: Size [Standard_B2as_v2](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series) (2 vCPU / 8 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SharePoint: Size [Standard_B4as_v2](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series) (4 vCPU / 16 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint Subscription SharePoint 2016), or a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint 2019).

You can use <https://azure.com/e/26eea69e35b04cb884b83ce06feadb5c> to estimate the monthly cost of deploying the resources in this module, in the region/currency of your choice, assuming it is created using the default settings and runs 24*7.

## Known issues

- The password for the User Profile directory synchronization connection (variable `other_accounts_password`) needs to be re-entered in the "Edit synchronization connection" page, otherwise the profile import fails (password decryption error in the logs).
- When setting `outbound_access_method` to `AzureFirewallProxy`, most of the softwares installed through Chocolatey fail to download and are not installed.
- The deployment of Azure Bastion fails pretty frequently. This has little impact, since it is very easy to redeploy through the portal.
- SharePoint 2016 and 2019 are outdated and deprecated. Their corresponding DSC configuration receive little maintenance to ensure they continue to deploy, but receive no improvement. As such, variables `sharepoint_configuration_level` and `default_zone_must_be_https` have no effect on them.

## More information

Additional notes:

- Using the default options, the complete deployment takes about 1h (but it is worth it).
- Deploying any post-RTM SharePoint Subscription build adds only an extra 5-10 minutes to the total deployment time (compared to RTM), partly because the updates are installed before the farm is created.
- Once it is completed, the template will return valuable information in the 'Outputs' of the deployment.
- For various (very good) reasons, in SQL and SharePoint VMs, the name of the local (not domain) administrator is in format `"l-[admin_username]"`. It is recorded in the 'Outputs' and in the state file.
