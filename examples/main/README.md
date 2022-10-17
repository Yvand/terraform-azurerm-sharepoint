# SharePoint Subscription 22H2

This examples provisions SharePoint Subscription 22H2 and configures [Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview).  

```hcl
module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=2.0.0"

  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "Subscription-22H2"
  admin_username             = "yvand"
  admin_password             = "<admin_password>"
  service_accounts_password  = "<service_accounts_password>"
  domain_fqdn                = "contoso.local"
  time_zone                  = "Romance Standard Time"
  auto_shutdown_time         = "1900"
  number_additional_frontend = 0
  add_public_ip_to_each_vm   = true
  rdp_traffic_allowed        = "10.20.30.40"
  enable_azure_bastion       = true
}
```
