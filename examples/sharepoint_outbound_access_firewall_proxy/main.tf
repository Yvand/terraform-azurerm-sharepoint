module "sharepoint" {
  source                  = "Yvand/sharepoint/azurerm"
  location                = "francecentral"
  subscription_id         = "<your_azure_subscription_id>"
  resource_group_name     = "<your_resource_group_name>"
  sharepoint_version      = "Subscription-Latest"
  outbound_access_method  = "AzureFirewallProxy"
  enable_azure_bastion    = true
  admin_username          = "<your_admin_username>"
  admin_password          = "<your_admin_password>"
  other_accounts_password = "<your_other_accounts_password>"
}