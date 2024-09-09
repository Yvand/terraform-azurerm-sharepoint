module "sharepoint" {
  source                     = "Yvand/sharepoint/azurerm"
  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "Subscription-22H2"
  admin_username             = "yvand"
  admin_password             = "<admin_password>"
  other_accounts_password  = "<other_accounts_password>"
  domain_fqdn                = "contoso.local"
  time_zone                  = "Romance Standard Time"
  auto_shutdown_time         = "1900"
  front_end_server_count = 0
  add_public_ip_address      = "SharePointVMsOnly"
  rdp_traffic_rule        = "10.20.30.40"
  enable_azure_bastion       = false
}
