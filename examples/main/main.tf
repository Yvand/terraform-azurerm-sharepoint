module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=3.3.0"

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
  add_public_ip_address      = "SharePointVMsOnly"
  rdp_traffic_allowed        = "10.20.30.40"
  enable_azure_bastion       = false
}
