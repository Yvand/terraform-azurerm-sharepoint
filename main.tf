provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      skip_shutdown_and_force_delete = true
      delete_os_disk_on_deletion     = true
    }
    template_deployment {
      delete_nested_items_during_deletion = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
  subscription_id = var.subscription_id
}

locals {
  resourceGroupNameFormatted = replace(replace(replace(replace(var.resource_group_name, ".", "-"), "(", "-"), ")", "-"), "_", "-")
  admin_password             = var.admin_password == "" ? random_password.random_admin_password.result : var.admin_password
  other_accounts_password    = var.other_accounts_password == "" ? random_password.random_service_accounts_password.result : var.other_accounts_password
  create_rdp_rule            = lower(var.rdp_traffic_rule) == "no" ? false : true
  license_type               = var.enable_hybrid_benefit_server_licenses == true ? "Windows_Server" : "None"
  _artifactsLocation         = var._artifactsLocation
  _artifactsLocationSasToken = ""
  enable_telemetry           = true
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
          "DownloadUrl" : "https://download.microsoft.com/download/e1f1440c-1192-4096-b9c9-31970e79671c/uber-subscription-kb5002768-fullfile-x64-glb.exe"
        }
      ]
    }
  ]

  network_settings = {
    vNetPrivatePrefix    = "10.1.0.0/16"
    mainSubnetPrefix     = "10.1.1.0/24"
    vmDCPrivateIPAddress = "10.1.1.100"
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

  default_tags = {
    source            = "terraform:Yvand/sharepoint/azurerm"
    createdOn         = formatdate("YYYY-MM-DD", timestamp())
    sharePointVersion = var.sharepoint_version
  }

  tags = merge(
    var.add_default_tags ? local.default_tags : {},
    var.tags != null ? var.tags : {}
  )

  firewall_proxy_settings = {
    vNetAzureFirewallPrefix = "10.1.3.0/24"
    azureFirewallIPAddress  = "10.1.3.4"
    http_port               = 8080
    https_port              = 8443
  }

  set_proxy_script = "param([string]$proxyIp, [string]$proxyHttpPort, [string]$proxyHttpsPort, [string]$localDomainFqdn) $proxy = 'http={0}:{1};https={0}:{2}' -f $proxyIp, $proxyHttpPort, $proxyHttpsPort; $bypasslist = '*.{0};<local>' -f $localDomainFqdn; netsh winhttp set proxy proxy-server=$proxy bypass-list=$bypasslist; $proxyEnabled = 1; New-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name 'ProxySettingsPerUser' -PropertyType DWORD -Value 0 -Force; $proxyBytes = [system.Text.Encoding]::ASCII.GetBytes($proxy); $bypassBytes = [system.Text.Encoding]::ASCII.GetBytes($bypasslist); $defaultConnectionSettings = [byte[]]@(@(70, 0, 0, 0, 0, 0, 0, 0, $proxyEnabled, 0, 0, 0, $proxyBytes.Length, 0, 0, 0) + $proxyBytes + @($bypassBytes.Length, 0, 0, 0) + $bypassBytes + @(1..36 | % { 0 })); $registryPaths = @('HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings', 'HKLM:\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Internet Settings'); foreach ($registryPath in $registryPaths) { Set-ItemProperty -Path $registryPath -Name ProxyServer -Value $proxy; Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value $proxyEnabled; Set-ItemProperty -Path $registryPath -Name ProxyOverride -Value $bypasslist; Set-ItemProperty -Path '$registryPath\\Connections' -Name DefaultConnectionSettings -Value $defaultConnectionSettings; } Bitsadmin /util /setieproxy localsystem MANUAL_PROXY $proxy $bypasslist;"

  run_command_set_proxy = {
    location = azurerm_resource_group.rg.location
    name     = "runcommand-setproxy"
    script_source = {
      script = local.set_proxy_script
    }
    parameters = {
      param1 = {
        name  = "proxyIp"
        value = local.firewall_proxy_settings.azureFirewallIPAddress
      }
      param2 = {
        name  = "proxyHttpPort"
        value = local.firewall_proxy_settings.http_port
      }
      param3 = {
        name  = "proxyHttpsPort"
        value = local.firewall_proxy_settings.https_port
      }
      param4 = {
        name  = "localDomainFqdn"
        value = var.domain_fqdn
      }
    }
  }

  run_command_increase_dsc_quota = {
    location = azurerm_resource_group.rg.location
    name     = "runcommand-increase-dsc-quota"
    script_source = {
      script = "Set-Item -Path WSMan:\\localhost\\MaxEnvelopeSizeKb -Value 2048"
    }
  }

  run_commands_virtual_machines = merge(
    var.outbound_access_method == "AzureFirewallProxy" ? { run_command_set_proxy = local.run_command_set_proxy } : {},
    { run_command_increase_dsc_quota = local.run_command_increase_dsc_quota }
  )
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

module "regions" {
  source                    = "Azure/avm-utl-regions/azurerm"
  version                   = "~> 0.5"
  availability_zones_filter = true
}

resource "random_integer" "zone_index" {
  max = length(module.regions.regions_by_name[var.location].zones)
  min = 1
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
  tags     = local.tags
}

# Setup the network
module "vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "~> 0.8"
  name                = module.naming.virtual_network.name_unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  enable_telemetry    = local.enable_telemetry
  address_space       = [local.network_settings.vNetPrivatePrefix]
  subnets = {
    vm_subnet_1 = {
      name                            = "${module.naming.subnet.name_unique}-1"
      address_prefixes                = [local.network_settings.mainSubnetPrefix]
      default_outbound_access_enabled = false
      network_security_group = {
        id = module.nsg_subnet_main.resource_id
      }
    }
  }
}

# Network security group
module "nsg_subnet_main" {
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version             = "~> 0.4"
  name                = module.naming.network_security_group.name_unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  enable_telemetry    = local.enable_telemetry
  security_rules = local.create_rdp_rule ? {
    allow_rdp_rule = {
      name                       = "allow-rdp-rule"
      description                = "Allow RDP"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = var.rdp_traffic_rule
      destination_address_prefix = "*"
      access                     = "Allow"
      priority                   = 100
      direction                  = "Inbound"
    }
  } : {}
}

// Create resources for VM DC
module "vm_dc_def" {
  source                     = "Azure/avm-res-compute-virtualmachine/azurerm"
  version                    = "~> 0.19"
  name                       = "vm-dc"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tags                       = local.tags
  enable_telemetry           = local.enable_telemetry
  computer_name              = local.vms_settings.vm_dc_name
  os_type                    = "Windows"
  sku_size                   = var.vm_dc_size
  timezone                   = var.time_zone
  license_type               = local.license_type
  zone                       = random_integer.zone_index.result
  encryption_at_host_enabled = false
  patch_mode                 = "AutomaticByPlatform"
  secure_boot_enabled        = true
  vtpm_enabled               = true
  network_interfaces = {
    network_interface_1 = {
      name = "vm-dc-${module.naming.network_interface.name_unique}"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "vm-dc-${module.naming.network_interface.name_unique}-ipconfig1"
          private_ip_subnet_resource_id = module.vnet.subnets["vm_subnet_1"].resource_id
          private_ip_address_allocation = "Static"
          private_ip_address            = local.network_settings.vmDCPrivateIPAddress
          create_public_ip_address      = var.outbound_access_method == "PublicIPAddress" ? true : false
          public_ip_address_name        = "vm-dc-${module.naming.public_ip.name_unique}"
        }
      }
    }
  }
  public_ip_configuration_details = {
    domain_name_label = var.add_name_to_public_ip_addresses == "Yes" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_dc_name)}" : null
  }
  account_credentials = {
    admin_credentials = {
      username                           = var.admin_username
      password                           = local.admin_password
      generate_admin_password_or_ssh_key = false
    }
  }
  os_disk = {
    name                 = "vm-dc-${module.naming.managed_disk.name_unique}"
    storage_account_type = var.vm_dc_storage
    caching              = "ReadWrite"
  }
  source_image_reference = {
    publisher = split(":", local.vms_settings.vm_dc_image)[0]
    offer     = split(":", local.vms_settings.vm_dc_image)[1]
    sku       = split(":", local.vms_settings.vm_dc_image)[2]
    version   = split(":", local.vms_settings.vm_dc_image)[3]
  }
  shutdown_schedules = {
    auto_shutdown = {
      enabled               = var.auto_shutdown_time == "9999" ? false : true
      daily_recurrence_time = var.auto_shutdown_time == "9999" ? "0000" : var.auto_shutdown_time
      timezone              = var.time_zone
      notification_settings = {
        enabled = false
      }
    }
  }
  run_commands = local.run_commands_virtual_machines
}

resource "azurerm_virtual_machine_extension" "vm_dc_ext_applydsc" {
  depends_on                 = [module.vm_dc_def]
  name                       = "apply-dsc"
  virtual_machine_id         = module.vm_dc_def.resource_id
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

// Create resources for VM SQL
module "vm_sql_def" {
  source                     = "Azure/avm-res-compute-virtualmachine/azurerm"
  version                    = "~> 0.19"
  name                       = "vm-sql"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tags                       = local.tags
  enable_telemetry           = local.enable_telemetry
  computer_name              = local.vms_settings.vm_sql_name
  os_type                    = "Windows"
  sku_size                   = var.vm_sql_size
  timezone                   = var.time_zone
  license_type               = local.license_type
  zone                       = random_integer.zone_index.result
  encryption_at_host_enabled = false
  patch_mode                 = "AutomaticByOS"
  secure_boot_enabled        = true
  vtpm_enabled               = true
  network_interfaces = {
    network_interface_1 = {
      name = "vm-sql-${module.naming.network_interface.name_unique}"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "vm-sql-${module.naming.network_interface.name_unique}-ipconfig1"
          private_ip_subnet_resource_id = module.vnet.subnets["vm_subnet_1"].resource_id
          private_ip_address_allocation = "Dynamic"
          create_public_ip_address      = var.outbound_access_method == "PublicIPAddress" ? true : false
          public_ip_address_name        = "vm-sql-${module.naming.public_ip.name_unique}"
        }
      }
    }
  }
  public_ip_configuration_details = {
    domain_name_label = var.add_name_to_public_ip_addresses == "Yes" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_sql_name)}" : null
  }
  account_credentials = {
    admin_credentials = {
      username                           = local.deployment_settings.localAdminUserName
      password                           = local.admin_password
      generate_admin_password_or_ssh_key = false
    }
  }
  os_disk = {
    name                 = "vm-sql-${module.naming.managed_disk.name_unique}"
    storage_account_type = var.vm_sql_storage
    caching              = "ReadWrite"
  }
  source_image_reference = {
    publisher = split(":", local.vms_settings.vm_sql_image)[0]
    offer     = split(":", local.vms_settings.vm_sql_image)[1]
    sku       = split(":", local.vms_settings.vm_sql_image)[2]
    version   = split(":", local.vms_settings.vm_sql_image)[3]
  }
  shutdown_schedules = {
    auto_shutdown = {
      enabled               = var.auto_shutdown_time == "9999" ? false : true
      daily_recurrence_time = var.auto_shutdown_time == "9999" ? "0000" : var.auto_shutdown_time
      timezone              = var.time_zone
      notification_settings = {
        enabled = false
      }
    }
  }
  run_commands = local.run_commands_virtual_machines
}

resource "azurerm_virtual_machine_extension" "vm_sql_ext_applydsc" {
  depends_on                 = [module.vm_sql_def]
  name                       = "apply-dsc"
  virtual_machine_id         = module.vm_sql_def.resource_id
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

// Create resources for VM SP
module "vm_sp_def" {
  source                     = "Azure/avm-res-compute-virtualmachine/azurerm"
  version                    = "~> 0.19"
  name                       = "vm-sp"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tags                       = local.tags
  enable_telemetry           = local.enable_telemetry
  computer_name              = local.vms_settings.vm_sp_name
  os_type                    = "Windows"
  sku_size                   = var.vm_sp_size
  timezone                   = var.time_zone
  license_type               = local.license_type
  zone                       = random_integer.zone_index.result
  encryption_at_host_enabled = false
  patch_mode                 = local.is_sharepoint_subscription ? "AutomaticByPlatform" : "AutomaticByOS"
  secure_boot_enabled        = local.vms_settings.vms_sharepoint_trustedLaunchEnabled
  vtpm_enabled               = local.vms_settings.vms_sharepoint_trustedLaunchEnabled
  network_interfaces = {
    network_interface_1 = {
      name = "vm-sp-${module.naming.network_interface.name_unique}"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "vm-sp-${module.naming.network_interface.name_unique}-ipconfig1"
          private_ip_subnet_resource_id = module.vnet.subnets["vm_subnet_1"].resource_id
          private_ip_address_allocation = "Dynamic"
          create_public_ip_address      = var.outbound_access_method == "PublicIPAddress" ? true : false
          public_ip_address_name        = "vm-sp-${module.naming.public_ip.name_unique}"
        }
      }
    }
  }
  public_ip_configuration_details = {
    domain_name_label = var.add_name_to_public_ip_addresses == "Yes" || var.add_name_to_public_ip_addresses == "SharePointVMsOnly" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_sp_name)}" : null
  }
  account_credentials = {
    admin_credentials = {
      username                           = local.deployment_settings.localAdminUserName
      password                           = local.admin_password
      generate_admin_password_or_ssh_key = false
    }
  }
  os_disk = {
    name                 = "vm-sp-${module.naming.managed_disk.name_unique}"
    storage_account_type = var.vm_sql_storage
    caching              = "ReadWrite"
  }
  source_image_reference = {
    publisher = split(":", local.vms_settings.vms_sharepoint_image)[0]
    offer     = split(":", local.vms_settings.vms_sharepoint_image)[1]
    sku       = split(":", local.vms_settings.vms_sharepoint_image)[2]
    version   = split(":", local.vms_settings.vms_sharepoint_image)[3]
  }
  shutdown_schedules = {
    auto_shutdown = {
      enabled               = var.auto_shutdown_time == "9999" ? false : true
      daily_recurrence_time = var.auto_shutdown_time == "9999" ? "0000" : var.auto_shutdown_time
      timezone              = var.time_zone
      notification_settings = {
        enabled = false
      }
    }
  }
  run_commands = local.run_commands_virtual_machines
}

resource "azurerm_virtual_machine_extension" "vm_sp_ext_applydsc" {
  depends_on                 = [module.vm_sp_def]
  name                       = "apply-dsc"
  virtual_machine_id         = module.vm_sp_def.resource_id
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

// Create resources for VMs FEs
module "vm_fe_def" {
  count                      = var.front_end_servers_count
  source                     = "Azure/avm-res-compute-virtualmachine/azurerm"
  version                    = "~> 0.19"
  name                       = "vm-fe${count.index}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tags                       = local.tags
  enable_telemetry           = local.enable_telemetry
  computer_name              = "${local.vms_settings.vm_fe_name}-${count.index}"
  os_type                    = "Windows"
  sku_size                   = var.vm_sp_size
  timezone                   = var.time_zone
  license_type               = local.license_type
  zone                       = random_integer.zone_index.result
  encryption_at_host_enabled = false
  patch_mode                 = local.is_sharepoint_subscription ? "AutomaticByPlatform" : "AutomaticByOS"
  secure_boot_enabled        = local.vms_settings.vms_sharepoint_trustedLaunchEnabled
  vtpm_enabled               = local.vms_settings.vms_sharepoint_trustedLaunchEnabled
  network_interfaces = {
    network_interface_1 = {
      name = "vm-fe${count.index}-${module.naming.network_interface.name_unique}"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "vm-fe${count.index}-${module.naming.network_interface.name_unique}-ipconfig1"
          private_ip_subnet_resource_id = module.vnet.subnets["vm_subnet_1"].resource_id
          private_ip_address_allocation = "Dynamic"
          create_public_ip_address      = var.outbound_access_method == "PublicIPAddress" ? true : false
          public_ip_address_name        = "vm-fe${count.index}-${module.naming.public_ip.name_unique}"
        }
      }
    }
  }
  public_ip_configuration_details = {
    domain_name_label = var.add_name_to_public_ip_addresses == "Yes" || var.add_name_to_public_ip_addresses == "SharePointVMsOnly" ? "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_fe_name)}-${count.index}" : null
  }
  account_credentials = {
    admin_credentials = {
      username                           = local.deployment_settings.localAdminUserName
      password                           = local.admin_password
      generate_admin_password_or_ssh_key = false
    }
  }
  os_disk = {
    name                 = "vm-fe${count.index}-${module.naming.managed_disk.name_unique}"
    storage_account_type = var.vm_sql_storage
    caching              = "ReadWrite"
  }
  source_image_reference = {
    publisher = split(":", local.vms_settings.vms_sharepoint_image)[0]
    offer     = split(":", local.vms_settings.vms_sharepoint_image)[1]
    sku       = split(":", local.vms_settings.vms_sharepoint_image)[2]
    version   = split(":", local.vms_settings.vms_sharepoint_image)[3]
  }
  shutdown_schedules = {
    auto_shutdown = {
      enabled               = var.auto_shutdown_time == "9999" ? false : true
      daily_recurrence_time = var.auto_shutdown_time == "9999" ? "0000" : var.auto_shutdown_time
      timezone              = var.time_zone
      notification_settings = {
        enabled = false
      }
    }
  }
  run_commands = local.run_commands_virtual_machines
}

resource "azurerm_virtual_machine_extension" "vm_fe_ext_applydsc" {
  depends_on                 = [module.vm_fe_def]
  count                      = var.front_end_servers_count
  name                       = "apply-dsc"
  virtual_machine_id         = element(module.vm_fe_def.*.resource_id, count.index)
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

# Resources for Azure Bastion Developer SKU
module "azure_bastion" {
  count               = var.enable_azure_bastion ? 1 : 0
  source              = "Azure/avm-res-network-bastionhost/azurerm"
  version             = "~> 0.7"
  name                = module.naming.bastion_host.name_unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  enable_telemetry    = local.enable_telemetry
  virtual_network_id  = module.vnet.resource_id
  sku                 = "Developer"
  zones               = []
}

# Resources for Azure Firewall
resource "azurerm_subnet" "firewall_subnet" {
  count                           = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  depends_on                      = [module.vnet]
  name                            = "AzureFirewallSubnet"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = module.vnet.name
  address_prefixes                = [local.firewall_proxy_settings.vNetAzureFirewallPrefix]
  default_outbound_access_enabled = false
}

module "firewall_pip" {
  count               = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  source              = "Azure/avm-res-network-publicipaddress/azurerm"
  version             = "~> 0.2"
  name                = "${module.naming.public_ip.name_unique}-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  enable_telemetry    = local.enable_telemetry
  allocation_method   = "Static"
  sku                 = "Standard"
}

module "firewall_policy" {
  count               = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  source              = "Azure/avm-res-network-firewallpolicy/azurerm"
  version             = "~> 0.3"
  name                = module.naming.firewall_policy.name_unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  enable_telemetry    = local.enable_telemetry
  firewall_policy_explicit_proxy = {
    enabled         = true
    http_port       = local.firewall_proxy_settings.http_port
    https_port      = local.firewall_proxy_settings.https_port
    enable_pac_file = false
  }
}

module "rule_collection_group" {
  count                                                    = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  source                                                   = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version                                                  = "~> 0.3"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy[0].resource_id
  firewall_policy_rule_collection_group_name               = "NetworkRuleCollectionGroup"
  firewall_policy_rule_collection_group_priority           = 100
  firewall_policy_rule_collection_group_application_rule_collection = [
    {
      action   = "Allow"
      name     = "ProxyApplicationRules"
      priority = 100
      rule = [
        {
          name              = "proxy-allow-all-outbound"
          description       = "Allow all outbound traffic"
          destination_fqdns = ["*"]
          source_addresses  = ["*"]
          protocols = [
            {
              port = 443
              type = "Https"
            },
            {
              port = 80
              type = "Http"
            }
          ]
        }
      ]
    }
  ]
}

module "firewall_def" {
  count               = var.outbound_access_method == "AzureFirewallProxy" ? 1 : 0
  source              = "Azure/avm-res-network-azurefirewall/azurerm"
  version             = "~> 0.3"
  name                = module.naming.firewall.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  enable_telemetry    = local.enable_telemetry
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Standard"
  firewall_policy_id  = module.firewall_policy[0].resource_id
  firewall_ip_configuration = [
    {
      name                 = "ipconfig1"
      subnet_id            = azurerm_subnet.firewall_subnet[0].id
      public_ip_address_id = module.firewall_pip[0].resource_id
    }
  ]
}
