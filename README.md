# terraform-azurerm-sharepoint

This module is the Terraform version of [this public ARM template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/), and can create a SharePoint Subscription / 2019 / 2016 / 2013 farm with a web application set with Windows and ADFS authentication, and some path based and host-named site collections. It also provisions User Profiles and Apps service applications and installs claims provider LDAPCP.

## Prerequisites

- Access to an **Azure subscription**.

## Usage

```terraform
module "sharepoint" {
  source                     = "Yvand/sharepoint/azurerm"
  version                    = ">=1.3.1"

  # Below are the main variables, other variables can also be set
  location                   = "West Europe"
  resource_group_name        = "<resourceGroupName>"
  sharepoint_version         = "Subscription-22H2"
  admin_username             = "yvand"
  admin_password             = "<password>"
}
```

## Key variables

- Variable `sharepoint_version` lets you choose which version of SharePoint to install:
  - `Subscription-22H2` (default): SharePoint Subscription RTM is downloaded and installed, and then the [Feature Update 22H2](https://learn.microsoft.com/en-us/sharepoint/what-s-new/new-and-improved-features-in-sharepoint-server-subscription-edition-22h2-release) (September 2022 CU) is also downloaded and installed. Installing this update adds an extra 12-15 minutes to the total deployment time.
  - `Subscription-RTM`: SharePoint Subscription RTM is downloaded and installed
  - `2019`: An image maintained by SharePoint Engineering, built with SharePoint 2019 bits installed is deployed
  - `2016`: An image maintained by SharePoint Engineering, built with SharePoint 2016 bits installed is deployed
  - `2013`: An image maintained by SharePoint Engineering, built with SharePoint 2013 bits installed is deployed
- Variables `admin_password` and `service_accounts_password` require a strong password [as documented here](https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-), but they can be left empty to use an auto-generated password that will be recorded in state file.
- Variable `rdp_traffic_allowed` specifies if RDP traffic is allowed:
  - If 'No' (default): Firewall denies all incoming RDP traffic from Internet.
  - If '*' or 'Internet': Firewall accepts all incoming RDP traffic from Internet.
  - If 'ServiceTagName': Firewall accepts all incoming RDP traffic from the specified 'ServiceTagName'.
  - If 'xx.xx.xx.xx': Firewall accepts incoming RDP traffic only from the IP 'xx.xx.xx.xx'.

Using the default options, the complete deployment takes about 1h (but it is worth it).  

## Features

Regardless of the SharePoint version selected, an extensive configuration is performed, with some differences depending on the version:

### Common

- Active Directory forest is created, and AD CS and AD FS are installed and configured. LDAPS (LDAP over SSL) is also conigured.
- 

### Specific to SharePoint Subscription

- HTTTPS site certificate is managed by SharePoint: It has the private key and sets the binding itself in the IIS site
- Federated authentication is configured using OpenID Connect

### Specific to SharePoint 2019 / 2016 / 2013

- Federated authentication is configured using SAML 1.1

## Cost of the resources deployed

By default, virtual machines use [B-series burstable](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable), ideal for such template and much cheaper than other comparable series.
Here is the default size and storage type per virtual machine role:

* DC: Size [Standard_B2s](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 4 GiB RAM) and OS disk is a 32 GiB [standard SSD E4](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
* SQL Server: Size [Standard_B2ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (2 vCPU / 8 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).
* SharePoint: Size [Standard_B4ms](https://docs.microsoft.com/azure/virtual-machines/sizes-b-series-burstable) (4 vCPU / 16 GiB RAM) and OS disk is a 128 GiB [standard SSD E10](https://learn.microsoft.com/azure/virtual-machines/disks-types#standard-ssds).

You can visit <https://azure.com/e/c86a94bb7e3943fe96e2c71cf8ece33a> to view the monthly cost of the template, assuming it is using the default settings and running 24*7, in the region/currency of your choice.
