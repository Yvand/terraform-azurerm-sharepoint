module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=3.0.0"

  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "Subscription-RTM"
  admin_username             = "yvand"
  admin_password             = "<admin_password>"
  add_public_ip_address   = false
  rdp_traffic_allowed        = "No"
  enable_azure_bastion       = true
}