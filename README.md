# terraform-azurerm-sharepoint

This module is the Terraform version of [this public ARM template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/), and can create a SharePoint Subscription / 2019 / 2016 / 2013 farm with a web application set with Windows and ADFS authentication, and some path based and host-named site collections. It also provisions User Profiles and Apps service applications and installs claims provider LDAPCP..

## Usage

```terraform
module "sharepoint" {
  source                     = "Yvand/sharepoint/azurerm"
  version                    = ">=1.3.0"

  # Below are the main variables, but additional variables can also be set
  location                   = "West Europe"
  resource_group_name        = "<xxx>"
  sharepoint_version         = "Subscription-22H2"
  admin_username             = "yvand"
  admin_password             = "<password>"
  service_accounts_password  = "<password>"
}
```
