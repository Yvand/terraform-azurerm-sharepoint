module "sharepoint" {
  source              = "Yvand/sharepoint/azurerm"
  location            = "francecentral"
  subscription_id     = "<your_azure_subscription_id>"
  resource_group_name = "<your_resource_group_name>"
}