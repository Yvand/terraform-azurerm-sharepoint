# Minimal

This example demonstrates the smallest possible input for the module with only defaults defined. The minimal defaults create a SharePoint Subscription farm updated to the latest CU available at the time of publishing the module.

```hcl
module "sharepoint" {
  source              = "Yvand/sharepoint/azurerm"
  location            = "francecentral"
  subscription_id     = "<your_azure_subscription_id>"
  resource_group_name = "<your_resource_group_name>"
}
```

In this configuration:
- The `admin_username` will be the default value (yvand)
- Both the `admin_password` and `other_accounts_password` will be auto-generated, and their values written in the state file
- The VMs will connect to internet through their public IP address
- No inbound RDP connection to the VMs is allowed. You may connect to the VMs through Azure Bastion, or by creating a JIT policy
