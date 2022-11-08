# SharePoint Subscription 22H2

This examples provisions SharePoint Subscription 22H2 with the following configuration:

- Variable `number_additional_frontend` is set to `0`: SharePoint farm will have 1 server running everything.
- Variable `rdp_traffic_allowed` is set to `10.20.30.40`: A rule is created on the network security groups to allow RDP traffic from incoming IP `10.20.30.40`.
- Variable `enable_azure_bastion` is set to `true`: [Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview) is configured.


```hcl
module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=2.1.0"

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
  add_public_ip_address   = "SharePointVMsOnly"
  rdp_traffic_allowed        = "10.20.30.40"
  enable_azure_bastion       = true
}
```
