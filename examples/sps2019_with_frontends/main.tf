module "sharepoint" {
  source                     = "Yvand/sharepoint/azurerm"
  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "2019"
  admin_username             = "yvand"
  front_end_servers_count = 2
  add_public_ip_address      = "SharePointVMsOnly"
  rdp_traffic_rule        = "10.20.30.40"
  enable_azure_bastion       = false
}
