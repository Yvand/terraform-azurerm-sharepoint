# SharePoint Subscription RTM with Azure Bastion only

This examples provisions SharePoint Subscription RTM and configures [Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview).  
Since `add_public_ip_to_each_vm` is set to `false`, virtual machines have no public IP address and Bastion is the only way to connect to them.
Since `service_accounts_password` is not set, the service accounts password will be auto-generated and written in the state file.

```hcl
module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=2.0.0"

  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "Subscription-RTM"
  admin_username             = "yvand"
  admin_password             = "<admin_password>"
  add_public_ip_to_each_vm   = false
  rdp_traffic_allowed        = "No"
  enable_azure_bastion       = true
}
```
