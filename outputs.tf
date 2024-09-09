output "resource_group_name" {
  value       = var.resource_group_name
  description = "Name of the resource group created"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "Id of the resource group created"
}

output "vm_dc_dns" {
  value       = var.outbound_access_method == "PublicIPAddress" ? azurerm_public_ip.vm_dc_pip[0].fqdn : null
  description = "Public DNS name of the DC VM"
}

output "vm_sql_dns" {
  value       = var.outbound_access_method == "PublicIPAddress" ? azurerm_public_ip.vm_sql_pip[0].fqdn : null
  description = "Public DNS name of the SQL VM"
}

output "vm_sp_dns" {
  value       = var.outbound_access_method == "PublicIPAddress" ? azurerm_public_ip.vm_sp_pip[0].fqdn : null
  description = "Public DNS name of the SP VM"
}

output "vm_fe_dns" {
  value       = azurerm_public_ip.vm_fe_pip[*].fqdn
  description = "Public DNS names of the FE VMs"
}

output "domain_admin_account" {
  value       = "${split(".", var.domain_fqdn)[0]}\\${var.admin_username}"
  description = "Domain administrator account in format domain\\username"
}

output "domain_admin_account_format_bastion" {
  value       = "${var.admin_username}@${var.domain_fqdn}"
  description = "Domain administrator account in the format required by Azure Bastion: 'username@domain_fqdn'"
}

output "local_admin_username" {
  value       = azurerm_windows_virtual_machine.vm_sp_def.admin_username
  description = "Local (not domain) administrator of SQL and SharePoint VMs"
}

output "admin_password" {
  value       = local.admin_password
  sensitive   = true
  description = "Password of the local and domain administrator"
}

output "other_accounts_password" {
  value       = local.other_accounts_password
  sensitive   = true
  description = "Password of all Active Directory service accounts"
}