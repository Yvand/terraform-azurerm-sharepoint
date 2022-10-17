output "resource_group_name" {
  value = var.resource_group_name
}

output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "vm_dc_dns" {
  value = var.add_public_ip_to_each_vm ? azurerm_public_ip.pip_dc[0].id : null
}

output "vm_sql_dns" {
  value = var.add_public_ip_to_each_vm ? azurerm_public_ip.pip_sql[0].id : null
}

output "vm_sp_dns" {
  value = var.add_public_ip_to_each_vm ? azurerm_public_ip.pip_sp[0].id : null
}

output "vm_fe_dns" {
  value = azurerm_public_ip.pip_fe[*].fqdn
}

output "domain_admin_account" {
  value = "${split(".", var.domain_fqdn)[0]}\\${var.admin_username}"
}

output "domain_admin_account_format_bastion" {
  value = "${var.admin_username}@${var.domain_fqdn}"
}

output "local_admin_username" {
  value = azurerm_windows_virtual_machine.vm_sp.admin_username
}

output "admin_password" {
  value     = local.admin_password
  sensitive = true
}

output "service_accounts_password" {
  value     = local.service_accounts_password
  sensitive = true
}