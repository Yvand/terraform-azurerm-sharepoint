# SharePoint 2019 with front-ends

This examples provisions SharePoint 2019 with 3 servers in the SharePoint farm:
- 1 server which has the full SharePoint configuration
- 2 servers with MinRole Front-end

Since `admin_password` and `service_accounts_password` are not set, the admin password and the service accounts password will be auto-generated and written in the state file.

```hcl
module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=2.0.0"

  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "2019"
  admin_username             = "yvand"
  number_additional_frontend = 2
  add_public_ip_to_each_vm   = true
  rdp_traffic_allowed        = "10.20.30.40"
  enable_azure_bastion       = false
}
```
