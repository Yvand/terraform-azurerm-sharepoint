module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=3.6.0"

  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "2019"
  admin_username             = "yvand"
  number_additional_frontend = 2
  add_public_ip_address      = "SharePointVMsOnly"
  rdp_traffic_allowed        = "10.20.30.40"
  enable_azure_bastion       = false
}
