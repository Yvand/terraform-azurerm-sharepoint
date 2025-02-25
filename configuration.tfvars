location                        = "France Central"
sharepoint_version              = "Subscription-Latest" #"2019"
outbound_access_method          = "PublicIPAddress"     #"AzureFirewallProxy"
front_end_servers_count         = 1
enable_azure_bastion            = true
auto_shutdown_time              = "1830"
vm_dc_size                      = "Standard_B2als_v2"
vm_sql_size                     = "Standard_B2as_v2"
vm_sp_size                      = "Standard_B4as_v2"
add_name_to_public_ip_addresses = "SharePointVMsOnly"