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
