# terraform-azurerm-sharepoint

This module creates a secure, highly customizable SharePoint Subscription / 2019 / 2016 farm, in your own Azure subscription.

The Azure resources are provisioned using [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/), and the virtual machines are configured with DSC (desired state configuration), using the [project SharePointInfraDsc](https://github.com/Yvand/SharePointInfraDsc).

## Main objectives

- A highly secure, customizable environment, under your full control (you set the AD domain name, admin account name, all accounts password).
- A SharePoint farm installed with the PU of your choice (including the latest one), and up-to-date Windows and softwares before you first log-in.
- Eliminate the burden of doing tedious configuration: Many SharePoint features and services are configured, doing this manually would take ages.
- Truly ready-to-use virtual machines right at the first log-in, with everything a SharePoint administrator needs.
- A state-of-the-art configuration that showcases the best practices for a a well-configured SharePoint farm.
- A fast deployment time: A fully configured SharePoint farm installed with the latest PU takes only about 1h15 mins to be fully ready (if you think it is not so fast, compare this with the time it takes to install a SharePoint PU in your farm).
- Easy to create, use, and destroy. You want to test a SharePoint setting/config but you are afraid to mess your existing farm? You want to test a specific SharePoint build? Or test OIDC? Use this module.

## Virtual machines

- The DC and SharePoint Subscription machines use the latest image of [Windows Server 2025 Datacenter: Azure Edition](https://marketplace.microsoft.com/en-us/product/microsoftwindowsserver.windowsserver?tab=PlansAndPrice).
- SQL machine uses the latest image of [SQL Server 2025 Standard Developer on Windows Server 2025](https://marketplace.microsoft.com/en-us/product/microsoftsqlserver.sql2025-ws2025?tab=PlansAndPrice).

About SharePoint legacy: SharePoint 2016 / 2019 use outdated images ([2016](https://marketplace.microsoft.com/en-us/product/sharepointserver.2016?tab=Overview) and [2019](https://marketplace.microsoft.com/en-us/product/sharepointserver.2019?tab=Overview)) published by SharePoint Engineering.

## Prerequisites

- An Azure subscription with at least the Azure role [**Contributor**](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#contributor), to create the resources.
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest).

## Usage

1. Create a .tf file, copy the content below, and change the values to fit your needs:

    ```terraform
    module "sharepoint" {
      source                         = "Yvand/sharepoint/azurerm"
      location                       = "francecentral"
      subscription_id                = "<your_azure_subscription_id>"
      resource_group_name            = "<resource_group_name_to_create>"
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

1. run `terraform init`
1. run `terraform apply`

## SharePoint configuration

- Variable `sharepoint_version` sets which version of SharePoint will be installed:
  - `Subscription-Latest` (default): SharePoint Subscription with the latest public update available at the time of publishing this version: March 2026 ([KB5002843](https://support.microsoft.com/help/5002843)).
  - `Subscription-25H2`: SharePoint Subscription with the [Feature Update 25H2](https://learn.microsoft.com/sharepoint/what-s-new/new-improved-features-sharepoint-server-subscription-edition-2025-h2-release) (September 2025 PU / [KB5002784](https://support.microsoft.com/help/5002784)).
  - `Subscription-25H1`: SharePoint Subscription with the [Feature Update 25H1](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-25h1-release) (March 2025 PU / [KB5002698](https://support.microsoft.com/help/5002698)).
  - `Subscription-24H2`: SharePoint Subscription with the [Feature Update 24H2](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-24h2-release) (September 2024 PU / [kb5002640](https://support.microsoft.com/help/5002640)).
  - `Subscription-24H1`: SharePoint Subscription with the [Feature Update 24H1](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-24h1-release) (March 2024 PU / [KB5002564](https://support.microsoft.com/help/5002564)).
  - `Subscription-23H2`: SharePoint Subscription with the [Feature Update 23H2](https://learn.microsoft.com/SharePoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h2-release) (September 2023 PU / [KB5002474](https://support.microsoft.com/help/5002474)).
  - `Subscription-23H1`: SharePoint Subscription with the [Feature Update 23H1](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-23h1-release) (March 2023 PU / [KB5002355](https://support.microsoft.com/help/5002355)).
  - `Subscription-22H2`: SharePoint Subscription with the [Feature Update 22H2](https://learn.microsoft.com/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-22h2-release) (September 2022 PU / [KB5002270](https://support.microsoft.com/help/5002270) and [KB5002271](https://support.microsoft.com/help/5002271)).
  - `Subscription-RTM`: SharePoint Subscription RTM [published here](https://www.microsoft.com/en-us/download/details.aspx?id=103599).
  - `2019` (deprecated): Uses the [image](https://marketplace.microsoft.com/en-us/product/sharepointserver.2019?tab=Overview) built and maintained by SharePoint Engineering.
  - `2016` (deprecated): Uses the [image](https://marketplace.microsoft.com/en-us/product/sharepointserver.2016?tab=Overview) built and maintained by SharePoint Engineering.
- Variable `sharepoint_configuration_level` sets how much configuration is done:
  - `Minimum`: Creates a web application with its default zone only.
  - `Light`: Everything in `Minimum`, plus:
    - Provisions the State Service Application.
    - Configures the trusted authentication (OIDC with ADFS).
  - `Medium`: Everything in `Light`, plus:
    - Provisions the User Profile Service Application.
    - Extends the web application in zone `Intranet`.
  - `Full`: Everything in `Medium`, plus:
    - Configures all the resources to run and deploy add-ins.
    - Creates addditional host-named site collections.
- Variable `default_zone_must_be_https`: `true` if the default zone must use HTTPS, `false` if it may use HTTP (if compatible with the configuration selected).
- Variable `front_end_servers_count` lets you add up to 4 additional SharePoint servers to the farm with the [MinRole Front-end](https://learn.microsoft.com/sharepoint/install/planning-for-a-minrole-server-deployment-in-sharepoint-server).

## Outbound access to internet

During the provisionning, virtual machines require an outbound access to internet to be able to download and apply their configuration.  
The outbound access method depends on variable `outbound_access_method`:
- `PublicIPAddress`: Virtual machines use a [Public IP](https://learn.microsoft.com/azure/virtual-network/ip-services/virtual-network-public-ip-address), associated with their network card.
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
  - As part of the public DNS name of the virtual machines, if they get a public IP (variable `outbound_access_method`), and a DNS name associated with it (variable `add_name_to_public_ip_addresses`).

- Variable `enable_hybrid_benefit_server_licenses` allows you to enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost, if you are eligible. See [this page](https://docs.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing) for more information..

## Outputs

The module stores multiple values in the state file, such as the logins, passwords, the public IP address of virtual machines, and other useful information.

## Cost of the resources deployed

By default, virtual machines use [Basv2 series](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series), ideal for such template and much cheaper than other comparable series.  
Below is the default size and storage used per virtual machine role:

- DC: Size [Standard_B2als_v2](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series) (2 vCPU / 4 GiB RAM) and OS disk is a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SQL Server: Size [Standard_B2as_v2](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series) (2 vCPU / 8 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
- SharePoint: Size [Standard_B4as_v2](https://learn.microsoft.com/azure/virtual-machines/sizes/general-purpose/basv2-series) (4 vCPU / 16 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint Subscription and SharePoint 2016), or a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds) (for SharePoint 2019).

You can use <https://azure.com/e/26eea69e35b04cb884b83ce06feadb5c> to estimate the monthly cost of deploying the resources in this module, in the region/currency of your choice, assuming it is created using the default settings and runs 24*7.

## Known issues

- The password for the User Profile directory synchronization connection (variable `other_accounts_password`) needs to be re-entered in the "Edit synchronization connection" page, otherwise the profile import fails (password decryption error in the logs).
- When setting `outbound_access_method` to `AzureFirewallProxy`, most of the softwares installed through Chocolatey fail to download and are not installed.
- The deployment of Azure Bastion fails pretty frequently. This has little impact, since it is very easy to redeploy through the portal.
- SharePoint 2016 and 2019 are outdated and deprecated. Their corresponding DSC configurations receive little maintenance to ensure they continue to deploy, but receive no improvement. As such, variables `sharepoint_configuration_level` and `default_zone_must_be_https` have no effect on them.

## Additional information

- Using the default options, the complete deployment takes about 1h (but it is worth it).
- Installing a SharePoint PU adds less than 10 minutes to the total deployment time, mostly because the PU is installed before the farm is created.
- For various (very good) reasons, in SQL and SharePoint VMs, the name of the local (not domain) administrator is in format `"l-[admin_username]"`. It is recorded in the 'Outputs' and in the state file.
