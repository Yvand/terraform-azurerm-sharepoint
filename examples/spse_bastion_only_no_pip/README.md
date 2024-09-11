# SharePoint Subscription RTM with Azure Bastion only

This examples provisions SharePoint Subscription RTM with the following configuration:

- Variable `other_accounts_password` is not set: The service accounts password will be auto-generated and written in the state file.
- Variable `add_public_ip_address` is set to `No`: Virtual machines have no public IP address and Bastion is the only way to connect to them.
- Variable `rdp_traffic_rule` is set to `No`: No rule is created on the network security groups.
- Variable `enable_azure_bastion` is set to `true`: [Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-overview) is configured.

```hcl
module "sharepoint" {
  source                     = "Yvand/sharepoint/azurerm"
  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "Subscription-RTM"
  admin_username             = "yvand"
  admin_password             = "<admin_password>"
  add_public_ip_address      = "No"
  rdp_traffic_rule        = "No"
  enable_azure_bastion       = true
}
```
