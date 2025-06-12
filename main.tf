provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  resourceGroupNameFormatted = replace(replace(replace(replace(var.resource_group_name, ".", "-"), "(", "-"), ")", "-"), "_", "-")
  admin_password             = var.admin_password == "" ? random_password.random_admin_password.result : var.admin_password
  other_accounts_password    = var.other_accounts_password == "" ? random_password.random_service_accounts_password.result : var.other_accounts_password
  create_rdp_rule            = lower(var.rdp_traffic_rule) == "no" ? 0 : 1
  license_type               = var.enable_hybrid_benefit_server_licenses == true ? "Windows_Server" : "None"
  _artifactsLocation         = var._artifactsLocation
  _artifactsLocationSasToken = ""

  is_sharepoint_subscription = split("-", var.sharepoint_version)[0] == "Subscription" ? true : false
  sharepoint_bits_used       = local.is_sharepoint_subscription ? jsonencode(local.sharepoint_subscription_bits) : jsonencode([])
  sharepoint_subscription_bits = [
    {
      "Label" : "RTM",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/3/f/5/3f5f8a7e-462b-41ff-a5b2-04bdf5821ceb/OfficeServer.iso",
          "ChecksumType" : "SHA256",
          "Checksum" : "C576B847C573234B68FC602A0318F5794D7A61D8149EB6AE537AF04470B7FC05"
        }
      ]
    },
    {
      "Label" : "22H2",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/8/d/f/8dfcb515-6e49-42e5-b20f-5ebdfd19d8e7/wssloc-subscription-kb5002270-fullfile-x64-glb.exe",
          "ChecksumType" : "SHA256",
          "Checksum" : "7E496530EB873146650A9E0653DE835CB2CAD9AF8D154CBD7387BB0F2297C9FC"
        },
        {
          "DownloadUrl" : "https://download.microsoft.com/download/3/f/5/3f5b1ee0-3336-45d7-b2f4-1e6af977d574/sts-subscription-kb5002271-fullfile-x64-glb.exe",
          "ChecksumType" : "SHA256",
          "Checksum" : "247011443AC573D4F03B1622065A7350B8B3DAE04D6A5A6DC64C8270A3BE7636"
        }
      ]
    },
    {
      "Label" : "23H1",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/c/6/a/c6a17105-3d86-42ad-888d-49b22383bfa1/uber-subscription-kb5002355-fullfile-x64-glb.exe"
        }
      ]
    },
    {
      "Label" : "23H2",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/f/5/5/f5559e3f-8b24-419f-b238-b09cf986e927/uber-subscription-kb5002474-fullfile-x64-glb.exe"
        }
      ]
    },
    {
      "Label" : "24H1",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/b/a/b/bab0c7cc-0454-474b-8538-7927f75e6486/uber-subscription-kb5002564-fullfile-x64-glb.exe"
        }
      ]
    },
    {
      "Label" : "24H2",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/6/6/a/66a0057f-79af-4307-8263-103ee75ef5c6/uber-subscription-kb5002640-fullfile-x64-glb.exe"
        }
      ]
    },
    {
      "Label" : "25H1",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/0b131072-7ee6-41ea-b33a-b3410865f3a0/uber-subscription-kb5002698-fullfile-x64-glb.exe"
        }
      ]
    },
    {
      "Label" : "Latest",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/159a5f7c-b1ac-46c1-83e8-5949090ddcb1/uber-subscription-kb5002736-fullfile-x64-glb.exe"
        }
      ]
    }
  ]

  network_settings = {
    vNetPrivatePrefix    = "10.1.0.0/16"
    mainSubnetPrefix     = "10.1.1.0/24"
    vmDCPrivateIPAddress = "10.1.1.4"
  }

  sharepoint_images_list = {
    "Subscription" = "MicrosoftWindowsServer:WindowsServer:2025-datacenter-azure-edition:latest"
    "2019"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2019gen2smalldisk:latest"
    "2016"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2016:latest"
  }

  vms_settings = {
    vm_dc_name                          = "DC"
    vm_sql_name                         = "SQL"
    vm_sp_name                          = "SP"
    vm_fe_name                          = "FE"
    vm_dc_image                         = "MicrosoftWindowsServer:WindowsServer:2025-datacenter-azure-edition-smalldisk:latest"
    vm_sql_image                        = "MicrosoftSQLServer:sql2022-ws2022:sqldev-gen2:latest"
    vms_sharepoint_image                = lookup(local.sharepoint_images_list, split("-", var.sharepoint_version)[0])
    vms_sharepoint_trustedLaunchEnabled = var.sharepoint_version == "2016" ? false : true
  }

  dsc_settings = {
    vm_dc_fileName = "ConfigureDCVM.zip"
    vm_dc_script   = "ConfigureDCVM.ps1"
    vm_dc_function = "ConfigureDCVM"

    vm_sql_fileName = "ConfigureSQLVM.zip"
    vm_sql_script   = "ConfigureSQLVM.ps1"
    vm_sql_function = "ConfigureSQLVM"

    vm_sp_fileName = local.is_sharepoint_subscription ? "ConfigureSPSE.zip" : "ConfigureSPLegacy.zip"
    vm_sp_script   = local.is_sharepoint_subscription ? "ConfigureSPSE.ps1" : "ConfigureSPLegacy.ps1"
    vm_sp_function = "ConfigureSPVM"

    vm_fe_fileName = local.is_sharepoint_subscription ? "ConfigureFESE.zip" : "ConfigureFELegacy.zip"
    vm_fe_script   = local.is_sharepoint_subscription ? "ConfigureFESE.ps1" : "ConfigureFELegacy.ps1"
    vm_fe_function = "ConfigureFEVM"
  }

  deployment_settings = {
    sharepoint_sites_authority    = "spsites"
    sharepoint_central_admin_port = 5000
    localAdminUserName            = "l-${var.admin_username}"
    enable_analysis               = false # This enables a Python script that parses dsc logs on SharePoint VMs, to compute the time take by each resource to run
    apply_browser_policies        = true
    sqlAlias                      = "SQLAlias"
    adfsSvcUserName               = "adfssvc"
    sqlSvcUserName                = "sqlsvc"
    spSetupUserName               = "spsetup"
    spFarmUserName                = "spfarm"
    spSvcUserName                 = "spsvc"
    spAppPoolUserName             = "spapppool"
    spADDirSyncUserName           = "spdirsync"
    spSuperUserName               = "spSuperUser"
    spSuperReaderName             = "spSuperReader"
  }

  firewall_proxy_settings = {
    vNetAzureFirewallPrefix = "10.1.3.0/24"
    azureFirewallIPAddress  = "10.1.3.4"
    http_port               = 8080
    https_port              = 8443
  }

  set_proxy_script = "param([string]$proxyIp, [string]$proxyHttpPort, [string]$proxyHttpsPort, [string]$localDomainFqdn) $proxy = 'http={0}:{1};https={0}:{2}' -f $proxyIp, $proxyHttpPort, $proxyHttpsPort; $bypasslist = '*.{0};<local>' -f $localDomainFqdn; netsh winhttp set proxy proxy-server=$proxy bypass-list=$bypasslist; $proxyEnabled = 1; New-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name 'ProxySettingsPerUser' -PropertyType DWORD -Value 0 -Force; $proxyBytes = [system.Text.Encoding]::ASCII.GetBytes($proxy); $bypassBytes = [system.Text.Encoding]::ASCII.GetBytes($bypasslist); $defaultConnectionSettings = [byte[]]@(@(70, 0, 0, 0, 0, 0, 0, 0, $proxyEnabled, 0, 0, 0, $proxyBytes.Length, 0, 0, 0) + $proxyBytes + @($bypassBytes.Length, 0, 0, 0) + $bypassBytes + @(1..36 | % { 0 })); $registryPaths = @('HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings', 'HKLM:\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Internet Settings'); foreach ($registryPath in $registryPaths) { Set-ItemProperty -Path $registryPath -Name ProxyServer -Value $proxy; Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value $proxyEnabled; Set-ItemProperty -Path $registryPath -Name ProxyOverride -Value $bypasslist; Set-ItemProperty -Path '$registryPath\\Connections' -Name DefaultConnectionSettings -Value $defaultConnectionSettings; } Bitsadmin /util /setieproxy localsystem MANUAL_PROXY $proxy $bypasslist;"
}

resource "random_password" "random_admin_password" {
  length           = 8
  special          = true
  override_special = "!#$%*()-_=+[]{}:?" # Do not include special characters '&<>' because they get encoded in the result
  min_lower        = 1
  min_numeric      = 1
  min_upper        = 1
  min_special      = 1
}

resource "random_password" "random_service_accounts_password" {
  length           = 8
  special          = true
  override_special = "!#$%*()-_=+[]{}:?" # Do not include special characters '&<>' because they get encoded in the result
  min_lower        = 1
  min_numeric      = 1
  min_upper        = 1
  min_special      = 1
}

# Start creating resources
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Setup the network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.resourceGroupNameFormatted}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.network_settings.vNetPrivatePrefix]
}

# Network security group
resource "azurerm_network_security_group" "nsg_subnet_main" {
  name                = "vnet-subnet-dc-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_main" {
  count                       = local.create_rdp_rule
  name                        = "allow-rdp-rule"
  description                 = "Allow RDP"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.rdp_traffic_rule
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 100
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_main.name
}

# Subnet
resource "azurerm_subnet" "subnet_main" {
  name                            = "Subnet-${local.vms_settings.vm_dc_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [local.network_settings.mainSubnetPrefix]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet_network_security_group_association" "subnet_main_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet_main.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_main.id
}

// Create resources for VM DC
resource "azurerm_public_ip" "vm_dc_pip" {
  count               = var.outbound_access_method == "PublicIPAddress" ? 1 : 0
  name                = "vm-dc-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = var.add_name_to_public_ip_addresses == "Yes" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_dc_name)}" : null
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "vm_dc_nic" {
  name                           = "vm-dc-nic"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.network_settings.vmDCPrivateIPAddress
    public_ip_address_id          = var.outbound_access_method == "PublicIPAddress" ? azurerm_public_ip.vm_dc_pip[0].id : null
  }
}

resource "azurerm_windows_virtual_machine" "vm_dc_def" {
  name                     = "vm-dc"
  location                 = azurerm_resource_group.rg.location
  computer_name            = local.vms_settings.vm_dc_name
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.vm_dc_nic.id]
  size                     = var.vm_dc_size
  admin_username           = var.admin_username
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  patch_mode               = "AutomaticByPlatform"
  provision_vm_agent       = true
  secure_boot_enabled      = true
  vtpm_enabled             = true

  os_disk {
    name                 = "vm-dc-disk-os"
    storage_account_type = var.vm_dc_storage
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = split(":", local.vms_settings.vm_dc_image)[0]
    offer     = split(":", local.vms_settings.vm_dc_image)[1]
    sku       = split(":", local.vms_settings.vm_dc_image)[2]
    version   = split(":", local.vms_settings.vm_dc_image)[3]
  }
}

resource "azurerm_virtual_machine_run_command" "vm_dc_runcommand_setproxy" {
  count              = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "runcommand-setproxy"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_dc_def.id
  source {
    script = local.set_proxy_script
  }
  parameter {
    name  = "proxyIp"
    value = local.firewall_proxy_settings.azureFirewallIPAddress
  }
  parameter {
    name  = "proxyHttpPort"
    value = local.firewall_proxy_settings.http_port
  }
  parameter {
    name  = "proxyHttpsPort"
    value = local.firewall_proxy_settings.https_port
  }
  parameter {
    name  = "localDomainFqdn"
    value = var.domain_fqdn
  }
}

resource "azurerm_virtual_machine_extension" "vm_dc_ext_applydsc" {
  depends_on = [azurerm_virtual_machine_run_command.vm_dc_runcommand_setproxy]
  # count                      = 0
  name                       = "apply-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_dc_def.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.9"
  auto_upgrade_minor_version = true

  timeouts {
    create = "45m"
  }

  settings = <<SETTINGS
  {
    "wmfVersion": "latest",
    "configuration": {
	    "url": "${local._artifactsLocation}${local.dsc_settings["vm_dc_fileName"]}${local._artifactsLocationSasToken}",
	    "function": "${local.dsc_settings["vm_dc_function"]}",
	    "script": "${local.dsc_settings["vm_dc_script"]}"
    },
    "configurationArguments": {
      "domainFQDN": "${var.domain_fqdn}",
      "PrivateIP": "${local.network_settings.vmDCPrivateIPAddress}",
      "SPServerName": "${local.vms_settings.vm_sp_name}",
      "SharePointSitesAuthority": "${local.deployment_settings.sharepoint_sites_authority}",
      "SharePointCentralAdminPort": "${local.deployment_settings.sharepoint_central_admin_port}",
      "ApplyBrowserPolicies": ${local.deployment_settings.apply_browser_policies}
    },
    "privacy": {
      "dataCollection": "enable"
    }
  }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "configurationArguments": {
      "AdminCreds": {
        "UserName": "${var.admin_username}",
        "Password": "${local.admin_password}"
      },
      "AdfsSvcCreds": {
        "UserName": "${local.deployment_settings.adfsSvcUserName}",
        "Password": "${local.other_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_dc_autoshutdown" {
  count              = var.auto_shutdown_time == "9999" ? 0 : 1
  virtual_machine_id = azurerm_windows_virtual_machine.vm_dc_def.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}

// Create resources for VM SQL
resource "azurerm_public_ip" "vm_sql_pip" {
  count               = var.outbound_access_method == "PublicIPAddress" ? 1 : 0
  name                = "vm-sql-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = var.add_name_to_public_ip_addresses == "Yes" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_sql_name)}" : null
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "vm_sql_nic" {
  name                           = "vm-sql-nic"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  depends_on                     = [azurerm_network_interface.vm_dc_nic]
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.outbound_access_method == "PublicIPAddress" ? azurerm_public_ip.vm_sql_pip[0].id : null
  }
}

resource "azurerm_windows_virtual_machine" "vm_sql_def" {
  name                     = "vm-sql"
  location                 = azurerm_resource_group.rg.location
  computer_name            = local.vms_settings.vm_sql_name
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.vm_sql_nic.id]
  size                     = var.vm_sql_size
  admin_username           = local.deployment_settings.localAdminUserName
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true
  secure_boot_enabled      = true
  vtpm_enabled             = true

  os_disk {
    name                 = "vm-sql-disk-os"
    storage_account_type = var.vm_sql_storage
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = split(":", local.vms_settings.vm_sql_image)[0]
    offer     = split(":", local.vms_settings.vm_sql_image)[1]
    sku       = split(":", local.vms_settings.vm_sql_image)[2]
    version   = split(":", local.vms_settings.vm_sql_image)[3]
  }
}

resource "azurerm_virtual_machine_run_command" "vm_sql_runcommand_setproxy" {
  count              = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "runcommand-setproxy"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sql_def.id
  source {
    script = local.set_proxy_script
  }
  parameter {
    name  = "proxyIp"
    value = local.firewall_proxy_settings.azureFirewallIPAddress
  }
  parameter {
    name  = "proxyHttpPort"
    value = local.firewall_proxy_settings.http_port
  }
  parameter {
    name  = "proxyHttpsPort"
    value = local.firewall_proxy_settings.https_port
  }
  parameter {
    name  = "localDomainFqdn"
    value = var.domain_fqdn
  }
}

resource "azurerm_virtual_machine_extension" "vm_sql_ext_applydsc" {
  depends_on = [azurerm_virtual_machine_run_command.vm_sql_runcommand_setproxy]
  # count                      = 0
  name                       = "apply-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_sql_def.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.9"
  auto_upgrade_minor_version = true

  timeouts {
    create = "45m"
  }

  settings = <<SETTINGS
  {
    "wmfVersion": "latest",
    "configuration": {
	    "url": "${local._artifactsLocation}${local.dsc_settings["vm_sql_fileName"]}${local._artifactsLocationSasToken}",
	    "function": "${local.dsc_settings["vm_sql_function"]}",
	    "script": "${local.dsc_settings["vm_sql_script"]}"
    },
    "configurationArguments": {
      "DNSServerIP": "${local.network_settings.vmDCPrivateIPAddress}",
      "DomainFQDN": "${var.domain_fqdn}"
    },
    "privacy": {
      "dataCollection": "enable"
    }
  }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "configurationArguments": {
      "DomainAdminCreds": {
        "UserName": "${var.admin_username}",
        "Password": "${local.admin_password}"
      },
      "SqlSvcCreds": {
        "UserName": "${local.deployment_settings.sqlSvcUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPSetupCreds": {
        "UserName": "${local.deployment_settings.spSetupUserName}",
        "Password": "${local.other_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_sql_autoshutdown" {
  count              = var.auto_shutdown_time == "9999" ? 0 : 1
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sql_def.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}


// Create resources for VM SP
resource "azurerm_public_ip" "vm_sp_pip" {
  count               = var.outbound_access_method == "PublicIPAddress" ? 1 : 0
  name                = "vm-sp-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = var.add_name_to_public_ip_addresses == "Yes" || var.add_name_to_public_ip_addresses == "SharePointVMsOnly" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_sp_name)}" : null
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "vm_sp_nic" {
  name                           = "vm-sp-nic"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  depends_on                     = [azurerm_network_interface.vm_dc_nic]
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.outbound_access_method == "PublicIPAddress" ? azurerm_public_ip.vm_sp_pip[0].id : null
  }
}

resource "azurerm_windows_virtual_machine" "vm_sp_def" {
  name                     = "vm-sp"
  location                 = azurerm_resource_group.rg.location
  computer_name            = local.vms_settings.vm_sp_name
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.vm_sp_nic.id]
  size                     = var.vm_sp_size
  admin_username           = local.deployment_settings.localAdminUserName
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  patch_mode               = local.is_sharepoint_subscription ? "AutomaticByPlatform" : "AutomaticByOS"
  provision_vm_agent       = true
  secure_boot_enabled      = local.vms_settings.vms_sharepoint_trustedLaunchEnabled
  vtpm_enabled             = local.vms_settings.vms_sharepoint_trustedLaunchEnabled

  os_disk {
    name                 = "vm-sp-disk-os"
    storage_account_type = var.vm_sp_storage
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = split(":", local.vms_settings.vms_sharepoint_image)[0]
    offer     = split(":", local.vms_settings.vms_sharepoint_image)[1]
    sku       = split(":", local.vms_settings.vms_sharepoint_image)[2]
    version   = split(":", local.vms_settings.vms_sharepoint_image)[3]
  }
}

resource "azurerm_virtual_machine_run_command" "vm_sp_runcommand_setproxy" {
  count              = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "runcommand-setproxy"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sp_def.id
  source {
    script = local.set_proxy_script
  }
  parameter {
    name  = "proxyIp"
    value = local.firewall_proxy_settings.azureFirewallIPAddress
  }
  parameter {
    name  = "proxyHttpPort"
    value = local.firewall_proxy_settings.http_port
  }
  parameter {
    name  = "proxyHttpsPort"
    value = local.firewall_proxy_settings.https_port
  }
  parameter {
    name  = "localDomainFqdn"
    value = var.domain_fqdn
  }
}

resource "azurerm_virtual_machine_run_command" "vm_sp_runcommand_increase_dsc_quota" {
  # count                      = 0
  name               = "runcommand-increase-dsc-quota"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sp_def.id
  source {
    script = "Set-Item -Path WSMan:\\localhost\\MaxEnvelopeSizeKb -Value 2048"
  }
}

resource "azurerm_virtual_machine_extension" "vm_sp_ext_applydsc" {
  # count                      = 0
  depends_on                 = [azurerm_virtual_machine_run_command.vm_sp_runcommand_setproxy, azurerm_virtual_machine_run_command.vm_sp_runcommand_increase_dsc_quota]
  name                       = "apply-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_sp_def.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.9"
  auto_upgrade_minor_version = true

  timeouts {
    create = "120m"
  }

  settings = <<SETTINGS
  {
    "wmfVersion": "latest",
    "configuration": {
	    "url": "${local._artifactsLocation}${local.dsc_settings["vm_sp_fileName"]}${local._artifactsLocationSasToken}",
	    "function": "${local.dsc_settings["vm_sp_function"]}",
	    "script": "${local.dsc_settings["vm_sp_script"]}"
    },
    "configurationArguments": {
      "DNSServerIP": "${local.network_settings.vmDCPrivateIPAddress}",
      "DomainFQDN": "${var.domain_fqdn}",
      "DCServerName": "${local.vms_settings.vm_dc_name}",
      "SQLServerName": "${local.vms_settings.vm_sql_name}",
      "SQLAlias": "${local.deployment_settings.sqlAlias}",
      "SharePointVersion": "${var.sharepoint_version}",
      "SharePointSitesAuthority": "${local.deployment_settings.sharepoint_sites_authority}",
      "SharePointCentralAdminPort": "${local.deployment_settings.sharepoint_central_admin_port}",
      "EnableAnalysis": ${local.deployment_settings.enable_analysis},
      "SharePointBits": ${local.sharepoint_bits_used}
    },
    "privacy": {
      "dataCollection": "enable"
    }
  }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "configurationArguments": {
      "DomainAdminCreds": {
        "UserName": "${var.admin_username}",
        "Password": "${local.admin_password}"
      },
      "SPSetupCreds": {
        "UserName": "${local.deployment_settings.spSetupUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPFarmCreds": {
        "UserName": "${local.deployment_settings.spFarmUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPSvcCreds": {
        "UserName": "${local.deployment_settings.spSvcUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPAppPoolCreds": {
        "UserName": "${local.deployment_settings.spAppPoolUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPADDirSyncCreds": {
        "UserName": "${local.deployment_settings.spADDirSyncUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPPassphraseCreds": {
        "UserName": "Passphrase",
        "Password": "${local.other_accounts_password}"
      },
      "SPSuperUserCreds": {
        "UserName": "${local.deployment_settings.spSuperUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPSuperReaderCreds": {
        "UserName": "${local.deployment_settings.spSuperReaderName}",
        "Password": "${local.other_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_sp_autoshutdown" {
  count              = var.auto_shutdown_time == "9999" ? 0 : 1
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sp_def.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}

// Create resources for VMs FEs
resource "azurerm_public_ip" "vm_fe_pip" {
  count               = var.outbound_access_method == "PublicIPAddress" ? var.front_end_servers_count : 0
  name                = "vm-fe${count.index}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = var.add_name_to_public_ip_addresses == "Yes" || var.add_name_to_public_ip_addresses == "SharePointVMsOnly" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_fe_name)}-${count.index}" : null
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "vm_fe_nic" {
  count                          = var.front_end_servers_count
  name                           = "vm-fe${count.index}-nic"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  depends_on                     = [azurerm_network_interface.vm_dc_nic]
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.outbound_access_method == "PublicIPAddress" ? element(azurerm_public_ip.vm_fe_pip.*.id, count.index) : null
  }
}

resource "azurerm_windows_virtual_machine" "vm_fe_def" {
  count                    = var.front_end_servers_count
  name                     = "vm-fe${count.index}"
  location                 = azurerm_resource_group.rg.location
  computer_name            = "${local.vms_settings.vm_fe_name}-${count.index}"
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [element(azurerm_network_interface.vm_fe_nic.*.id, count.index)]
  size                     = var.vm_sp_size
  admin_username           = local.deployment_settings.localAdminUserName
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  patch_mode               = local.is_sharepoint_subscription ? "AutomaticByPlatform" : "AutomaticByOS"
  provision_vm_agent       = true
  secure_boot_enabled      = local.vms_settings.vms_sharepoint_trustedLaunchEnabled
  vtpm_enabled             = local.vms_settings.vms_sharepoint_trustedLaunchEnabled

  os_disk {
    name                 = "vm-fe${count.index}-disk-os"
    storage_account_type = var.vm_sp_storage
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = split(":", local.vms_settings.vms_sharepoint_image)[0]
    offer     = split(":", local.vms_settings.vms_sharepoint_image)[1]
    sku       = split(":", local.vms_settings.vms_sharepoint_image)[2]
    version   = split(":", local.vms_settings.vms_sharepoint_image)[3]
  }
}

resource "azurerm_virtual_machine_run_command" "vm_fe_runcommand_setproxy" {
  # count                      = 0
  count              = var.outbound_access_method == "AzureFirewallProxy" ? var.front_end_servers_count : 0
  name               = "runcommand-setproxy"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = element(azurerm_windows_virtual_machine.vm_fe_def.*.id, count.index)
  source {
    script = local.set_proxy_script
  }
  parameter {
    name  = "proxyIp"
    value = local.firewall_proxy_settings.azureFirewallIPAddress
  }
  parameter {
    name  = "proxyHttpPort"
    value = local.firewall_proxy_settings.http_port
  }
  parameter {
    name  = "proxyHttpsPort"
    value = local.firewall_proxy_settings.https_port
  }
  parameter {
    name  = "localDomainFqdn"
    value = var.domain_fqdn
  }
}

resource "azurerm_virtual_machine_extension" "vm_fe_ext_applydsc" {
  depends_on = [azurerm_virtual_machine_run_command.vm_fe_runcommand_setproxy]
  # count                      = 0
  count                      = var.front_end_servers_count
  name                       = "apply-dsc"
  virtual_machine_id         = element(azurerm_windows_virtual_machine.vm_fe_def.*.id, count.index)
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.9"
  auto_upgrade_minor_version = true

  timeouts {
    create = "120m"
  }

  settings = <<SETTINGS
  {
    "wmfVersion": "latest",
    "configuration": {
	    "url": "${local._artifactsLocation}${local.dsc_settings["vm_fe_fileName"]}${local._artifactsLocationSasToken}",
	    "function": "${local.dsc_settings["vm_fe_function"]}",
	    "script": "${local.dsc_settings["vm_fe_script"]}"
    },
    "configurationArguments": {
      "DNSServerIP": "${local.network_settings.vmDCPrivateIPAddress}",
      "DomainFQDN": "${var.domain_fqdn}",
      "DCServerName": "${local.vms_settings.vm_dc_name}",
      "SQLServerName": "${local.vms_settings.vm_sql_name}",
      "SQLAlias": "${local.deployment_settings.sqlAlias}",
      "SharePointVersion": "${var.sharepoint_version}",
      "SharePointSitesAuthority": "${local.deployment_settings.sharepoint_sites_authority}",
      "EnableAnalysis": ${local.deployment_settings.enable_analysis},
      "SharePointBits": ${local.sharepoint_bits_used}
    },
    "privacy": {
      "dataCollection": "enable"
    }
  }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "configurationArguments": {
      "DomainAdminCreds": {
        "UserName": "${var.admin_username}",
        "Password": "${local.admin_password}"
      },
      "SPSetupCreds": {
        "UserName": "${local.deployment_settings.spSetupUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPFarmCreds": {
        "UserName": "${local.deployment_settings.spFarmUserName}",
        "Password": "${local.other_accounts_password}"
      },
      "SPPassphraseCreds": {
        "UserName": "Passphrase",
        "Password": "${local.other_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_fe_autoshutdown" {
  count              = var.front_end_servers_count > 0 && var.auto_shutdown_time != "9999" ? var.front_end_servers_count : 0
  virtual_machine_id = element(azurerm_windows_virtual_machine.vm_fe_def.*.id, count.index)
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}

# Resources for Azure Bastion Developer SKU
resource "azurerm_bastion_host" "bastion_def" {
  count               = var.enable_azure_bastion ? 1 : 0
  name                = "bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_id  = azurerm_virtual_network.vnet.id
  sku                 = "Developer"
}

# Resources for Azure Firewall
resource "azurerm_subnet" "firewall_subnet" {
  count                           = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name                            = "AzureFirewallSubnet"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [local.firewall_proxy_settings.vNetAzureFirewallPrefix]
  default_outbound_access_enabled = false
}

resource "azurerm_public_ip" "firewall_pip" {
  count               = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name                = "firewall-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(local.resourceGroupNameFormatted)}-firewall"
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_firewall_policy" "firewall_policy_proxy" {
  count               = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name                = "firewall-policy-proxy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  explicit_proxy {
    enabled         = true
    http_port       = local.firewall_proxy_settings.http_port
    https_port      = local.firewall_proxy_settings.https_port
    enable_pac_file = false
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "firewall_proxy_rules" {
  count              = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "rules"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy_proxy[0].id
  priority           = 100

  application_rule_collection {
    name     = "proxy-rules"
    priority = 100
    action   = "Allow"
    rule {
      name = "proxy-allow-all-outbound"
      source_addresses = [
        "*",
      ]
      destination_fqdns = [
        "*",
      ]
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
    }
  }
}

resource "azurerm_firewall" "firewall_def" {
  count               = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  name                = "firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.firewall_policy_proxy[0].id

  ip_configuration {
    name                 = "IpConf"
    subnet_id            = azurerm_subnet.firewall_subnet[0].id
    public_ip_address_id = azurerm_public_ip.firewall_pip[0].id
  }
}
