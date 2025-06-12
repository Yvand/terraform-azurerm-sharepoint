# SharePoint farm with VM internet access through their public IP address

This example demonstrates the creation of an up-to-date SharePoint Subscription farm, where the virtual machines connect to internet through their public IP address.

```hcl
module "sharepoint" {
  source                  = "Yvand/sharepoint/azurerm"
  location                = "francecentral"
  subscription_id         = "<your_azure_subscription_id>"
  resource_group_name     = "<your_resource_group_name>"
  sharepoint_version      = "Subscription-Latest"
  outbound_access_method  = "PublicIPAddress"
  enable_azure_bastion    = true
  admin_username          = "<your_admin_username>"
  admin_password          = "<your_admin_password>"
  other_accounts_password = "<your_other_accounts_password>"
}
```
