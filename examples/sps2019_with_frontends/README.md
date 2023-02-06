# SharePoint 2019 with front-ends

This examples provisions SharePoint 2019 with the following configuration:

- Variables `admin_password` and `service_accounts_password` are not set: Those passwords will be auto-generated and written in the state file.
- Variable `number_additional_frontend` is set to `2`: 2 additional SharePoint servers with MinRole Front-end are added to the farm.
- Variable `rdp_traffic_allowed` is set to `10.20.30.40`: A rule is created on the network security groups to allow RDP traffic from incoming IP `10.20.30.40`.

```hcl
module "sharepoint" {
  source  = "Yvand/sharepoint/azurerm"
  version = ">=3.2.0"

  location                   = "West Europe"
  resource_group_name        = "<resource_group_name>"
  sharepoint_version         = "2019"
  admin_username             = "yvand"
  number_additional_frontend = 2
  add_public_ip_address      = "SharePointVMsOnly"
  rdp_traffic_allowed        = "10.20.30.40"
  enable_azure_bastion       = false
}
```
