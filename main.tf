provider "azurerm" {
  features {}
}

provider "azapi" {
}

locals {
  resourceGroupNameFormatted = replace(replace(replace(replace(var.resource_group_name, ".", "-"), "(", "-"), ")", "-"), "_", "-")
  admin_password             = var.admin_password == "" ? random_password.random_admin_password.result : var.admin_password
  service_accounts_password  = var.service_accounts_password == "" ? random_password.random_service_accounts_password.result : var.service_accounts_password
  create_rdp_rule            = lower(var.rdp_traffic_allowed) == "no" ? 0 : 1
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
      "Label" : "Latest",
      "Packages" : [
        {
          "DownloadUrl" : "https://download.microsoft.com/download/2/9/0/2906b701-2c8e-4fce-abdb-e69c3f82b5cc/uber-subscription-kb5002533-fullfile-x64-glb.exe"
        }
      ]
    }
  ]

  network_settings = {
    vNetPrivatePrefix              = "10.1.0.0/16"
    vNetPrivateSubnetDCPrefix      = "10.1.1.0/24"
    vNetPrivateSubnetSQLPrefix     = "10.1.2.0/24"
    vNetPrivateSubnetSPPrefix      = "10.1.3.0/24"
    vNetPrivateSubnetBastionPrefix = "10.1.4.0/24"
    vNetAzureFirewallPrefix        = "10.1.5.0/24"
    vmDCPrivateIPAddress           = "10.1.1.4"
    azureFirewallIPAddress         = "10.1.5.4"
  }

  sharepoint_images_list = {
    "Subscription" = "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition-smalldisk:latest"
    "2019"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2019gen2smalldisk:latest"
    "2016"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2016:latest"
    "2013"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2013:latest"
  }

  vms_settings = {
    vm_dc_name           = "DC"
    vm_sql_name          = "SQL"
    vm_sp_name           = "SP"
    vm_fe_name           = "FE"
    vm_dc_image          = "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition-smalldisk:latest"
    vm_sql_image         = var.sharepoint_version == "2013" ? "MicrosoftSQLServer:sql2014sp3-ws2012r2:sqldev:latest" : "MicrosoftSQLServer:sql2022-ws2022:sqldev-gen2:latest"
    vms_sharepoint_image = lookup(local.sharepoint_images_list, split("-", var.sharepoint_version)[0])
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

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create the network security groups
resource "azurerm_network_security_group" "nsg_subnet_dc" {
  name                = "NSG-Subnet-${local.vms_settings.vm_dc_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_dc" {
  count                       = local.create_rdp_rule
  name                        = "allow-rdp-rule"
  description                 = "Allow RDP"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.rdp_traffic_allowed
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 100
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_dc.name
}

resource "azurerm_network_security_group" "nsg_subnet_sql" {
  name                = "NSG-Subnet-${local.vms_settings.vm_sql_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_sql" {
  count                       = local.create_rdp_rule
  name                        = "allow-rdp-rule"
  description                 = "Allow RDP"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.rdp_traffic_allowed
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 100
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_sql.name
}

resource "azurerm_network_security_group" "nsg_subnet_sp" {
  name                = "NSG-Subnet-${local.vms_settings.vm_sp_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_sp" {
  count                       = local.create_rdp_rule
  name                        = "allow-rdp-rule"
  description                 = "Allow RDP"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.rdp_traffic_allowed
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 100
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_sp.name
}

# Create the virtual network, 3 subnets, and associate each subnet with its Network Security Group
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.resourceGroupNameFormatted}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.network_settings["vNetPrivatePrefix"]]
}

# Subnet and NSG for DC
resource "azurerm_subnet" "subnet_dc" {
  name                            = "Subnet-${local.vms_settings.vm_dc_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [local.network_settings["vNetPrivateSubnetDCPrefix"]]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnetdc_association" {
  subnet_id                 = azurerm_subnet.subnet_dc.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_dc.id
}

resource "azurerm_subnet" "subnet_sql" {
  name                            = "Subnet-${local.vms_settings.vm_sql_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [local.network_settings["vNetPrivateSubnetSQLPrefix"]]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnetsql_association" {
  subnet_id                 = azurerm_subnet.subnet_sql.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_sql.id
}

resource "azurerm_subnet" "subnet_sp" {
  name                            = "Subnet-${local.vms_settings.vm_sp_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [local.network_settings["vNetPrivateSubnetSPPrefix"]]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnetsp_association" {
  subnet_id                 = azurerm_subnet.subnet_sp.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_sp.id
}

# Create artifacts for VM DC
resource "azurerm_public_ip" "pip_dc" {
  count               = var.internet_access_method == "PublicIPAddress" ? 1 : 0
  name                = "PublicIP-${local.vms_settings.vm_dc_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_dc_name)}"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_dc_0" {
  name                = "NIC-${local.vms_settings.vm_dc_name}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_dc.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.network_settings["vmDCPrivateIPAddress"]
    public_ip_address_id          = var.internet_access_method == "PublicIPAddress" ? azurerm_public_ip.pip_dc[0].id : null
  }
}

# Create artifacts for VM SQL
resource "azurerm_public_ip" "pip_sql" {
  count               = var.internet_access_method == "PublicIPAddress" ? 1 : 0
  name                = "PublicIP-${local.vms_settings.vm_sql_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_sql_name)}"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_sql_0" {
  name                = "NIC-${local.vms_settings.vm_sql_name}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_sql.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.internet_access_method == "PublicIPAddress" ? azurerm_public_ip.pip_sql[0].id : null
  }
}

# Create artifacts for VM SP
resource "azurerm_public_ip" "pip_sp" {
  count               = var.internet_access_method == "PublicIPAddress" ? 1 : 0
  name                = "PublicIP-${local.vms_settings.vm_sp_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_sp_name)}"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_sp_0" {
  name                = "NIC-${local.vms_settings.vm_sp_name}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_sp.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.internet_access_method == "PublicIPAddress" ? azurerm_public_ip.pip_sp[0].id : null
  }
}

# Create virtual machines
resource "azurerm_windows_virtual_machine" "vm_dc" {
  name                     = local.vms_settings.vm_dc_name
  computer_name            = local.vms_settings.vm_dc_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.nic_dc_0.id]
  size                     = var.vm_dc_size
  admin_username           = var.admin_username
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.vms_settings.vm_dc_name}-OS"
    storage_account_type = var.vm_dc_storage_account_type
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
  count              = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "VM-${local.vms_settings.vm_dc_name}-runcommand-setproxy"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_dc.id
  source {
    script = "param([string]$proxyIp = '10.1.5.4',[string]$proxyHttpPort = '8080',[string]$proxyHttpsPort = '8443',[string]$localDomainFqdn = 'contoso.local') $proxy = 'http={0}:{1};https={0}:{2}' -f $proxyIp, $proxyHttpPort, $proxyHttpsPort; $bypasslist = '*.{0};<local>' -f $localDomainFqdn; netsh winhttp set proxy proxy-server=$proxy bypass-list=$bypasslist; $proxyEnabled = 1; New-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name 'ProxySettingsPerUser' -PropertyType DWORD -Value 0 -Force; $proxyBytes = [system.Text.Encoding]::ASCII.GetBytes($proxy); $bypassBytes = [system.Text.Encoding]::ASCII.GetBytes($bypasslist); $defaultConnectionSettings = [byte[]]@(@(70, 0, 0, 0, 0, 0, 0, 0, $proxyEnabled, 0, 0, 0, $proxyBytes.Length, 0, 0, 0) + $proxyBytes + @($bypassBytes.Length, 0, 0, 0) + $bypassBytes + @(1..36 | % { 0 })); $registryPaths = @('HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings', 'HKLM:\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Internet Settings'); foreach ($registryPath in $registryPaths) { Set-ItemProperty -Path $registryPath -Name ProxyServer -Value $proxy; Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value $proxyEnabled; Set-ItemProperty -Path $registryPath -Name ProxyOverride -Value $bypasslist; Set-ItemProperty -Path '$registryPath\\Connections' -Name DefaultConnectionSettings -Value $defaultConnectionSettings; } Bitsadmin /util /setieproxy localsystem MANUAL_PROXY $proxy $bypasslist;"
  }
}

resource "azurerm_virtual_machine_extension" "vm_dc_dsc" {
  depends_on = [azurerm_virtual_machine_run_command.vm_dc_runcommand_setproxy]
  # count                      = 0
  name                       = "VM-${local.vms_settings.vm_dc_name}-DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_dc.id
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
      "PrivateIP": "${local.network_settings["vmDCPrivateIPAddress"]}",
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
        "Password": "${local.service_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_dc_shutdown" {
  count              = var.auto_shutdown_time == "9999" ? 0 : 1
  virtual_machine_id = azurerm_windows_virtual_machine.vm_dc.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}

resource "azurerm_windows_virtual_machine" "vm_sql" {
  name                     = local.vms_settings.vm_sql_name
  computer_name            = local.vms_settings.vm_sql_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.nic_sql_0.id]
  size                     = var.vm_sql_size
  admin_username           = local.deployment_settings.localAdminUserName
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.vms_settings.vm_sql_name}-OS"
    storage_account_type = var.vm_sql_storage_account_type
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
  count              = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "VM-${local.vms_settings.vm_sql_name}-runcommand-setproxy"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sql.id
  source {
    script = "param([string]$proxyIp = '10.1.5.4',[string]$proxyHttpPort = '8080',[string]$proxyHttpsPort = '8443',[string]$localDomainFqdn = 'contoso.local') $proxy = 'http={0}:{1};https={0}:{2}' -f $proxyIp, $proxyHttpPort, $proxyHttpsPort; $bypasslist = '*.{0};<local>' -f $localDomainFqdn; netsh winhttp set proxy proxy-server=$proxy bypass-list=$bypasslist; $proxyEnabled = 1; New-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name 'ProxySettingsPerUser' -PropertyType DWORD -Value 0 -Force; $proxyBytes = [system.Text.Encoding]::ASCII.GetBytes($proxy); $bypassBytes = [system.Text.Encoding]::ASCII.GetBytes($bypasslist); $defaultConnectionSettings = [byte[]]@(@(70, 0, 0, 0, 0, 0, 0, 0, $proxyEnabled, 0, 0, 0, $proxyBytes.Length, 0, 0, 0) + $proxyBytes + @($bypassBytes.Length, 0, 0, 0) + $bypassBytes + @(1..36 | % { 0 })); $registryPaths = @('HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings', 'HKLM:\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Internet Settings'); foreach ($registryPath in $registryPaths) { Set-ItemProperty -Path $registryPath -Name ProxyServer -Value $proxy; Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value $proxyEnabled; Set-ItemProperty -Path $registryPath -Name ProxyOverride -Value $bypasslist; Set-ItemProperty -Path '$registryPath\\Connections' -Name DefaultConnectionSettings -Value $defaultConnectionSettings; } Bitsadmin /util /setieproxy localsystem MANUAL_PROXY $proxy $bypasslist;"
  }
}

resource "azurerm_virtual_machine_extension" "vm_sql_dsc" {
  depends_on = [azurerm_virtual_machine_run_command.vm_sql_runcommand_setproxy]
  # count                      = 0
  name                       = "VM-${local.vms_settings.vm_sql_name}-DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_sql.id
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
      "DNSServerIP": "${local.network_settings["vmDCPrivateIPAddress"]}",
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
        "Password": "${local.service_accounts_password}"
      },
      "SPSetupCreds": {
        "UserName": "${local.deployment_settings.spSetupUserName}",
        "Password": "${local.service_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_sql_shutdown" {
  count              = var.auto_shutdown_time == "9999" ? 0 : 1
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sql.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}

resource "azurerm_windows_virtual_machine" "vm_sp" {
  name                     = local.vms_settings.vm_sp_name
  computer_name            = local.vms_settings.vm_sp_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.nic_sp_0.id]
  size                     = var.vm_sp_size
  admin_username           = local.deployment_settings.localAdminUserName
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.vms_settings.vm_sp_name}-OS"
    storage_account_type = var.vm_sp_storage_account_type
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
  count              = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "VM-${local.vms_settings.vm_sp_name}-runcommand-setproxy"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sp.id
  source {
    script = "param([string]$proxyIp = '10.1.5.4',[string]$proxyHttpPort = '8080',[string]$proxyHttpsPort = '8443',[string]$localDomainFqdn = 'contoso.local') $proxy = 'http={0}:{1};https={0}:{2}' -f $proxyIp, $proxyHttpPort, $proxyHttpsPort; $bypasslist = '*.{0};<local>' -f $localDomainFqdn; netsh winhttp set proxy proxy-server=$proxy bypass-list=$bypasslist; $proxyEnabled = 1; New-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name 'ProxySettingsPerUser' -PropertyType DWORD -Value 0 -Force; $proxyBytes = [system.Text.Encoding]::ASCII.GetBytes($proxy); $bypassBytes = [system.Text.Encoding]::ASCII.GetBytes($bypasslist); $defaultConnectionSettings = [byte[]]@(@(70, 0, 0, 0, 0, 0, 0, 0, $proxyEnabled, 0, 0, 0, $proxyBytes.Length, 0, 0, 0) + $proxyBytes + @($bypassBytes.Length, 0, 0, 0) + $bypassBytes + @(1..36 | % { 0 })); $registryPaths = @('HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings', 'HKLM:\\Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Internet Settings'); foreach ($registryPath in $registryPaths) { Set-ItemProperty -Path $registryPath -Name ProxyServer -Value $proxy; Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value $proxyEnabled; Set-ItemProperty -Path $registryPath -Name ProxyOverride -Value $bypasslist; Set-ItemProperty -Path '$registryPath\\Connections' -Name DefaultConnectionSettings -Value $defaultConnectionSettings; } Bitsadmin /util /setieproxy localsystem MANUAL_PROXY $proxy $bypasslist;"
  }
}

resource "azurerm_virtual_machine_run_command" "vm_sp_runcommand_increasemaxenvelopesizequota" {
  # count                      = 0
  name               = "VM-${local.vms_settings.vm_sp_name}-runcommand-IncreaseMaxEnvelopeSizeQuota"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sp.id
  source {
    script = "Set-Item -Path WSMan:\\localhost\\MaxEnvelopeSizeKb -Value 2048"
  }
}

resource "azurerm_virtual_machine_extension" "vm_sp_dsc" {
  # count                      = 0
  depends_on                 = [azurerm_virtual_machine_run_command.vm_sp_runcommand_setproxy, azurerm_virtual_machine_run_command.vm_sp_runcommand_increasemaxenvelopesizequota]
  name                       = "VM-${local.vms_settings.vm_sp_name}-DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_sp.id
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
      "DNSServerIP": "${local.network_settings["vmDCPrivateIPAddress"]}",
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
        "Password": "${local.service_accounts_password}"
      },
      "SPFarmCreds": {
        "UserName": "${local.deployment_settings.spFarmUserName}",
        "Password": "${local.service_accounts_password}"
      },
      "SPSvcCreds": {
        "UserName": "${local.deployment_settings.spSvcUserName}",
        "Password": "${local.service_accounts_password}"
      },
      "SPAppPoolCreds": {
        "UserName": "${local.deployment_settings.spAppPoolUserName}",
        "Password": "${local.service_accounts_password}"
      },
      "SPADDirSyncCreds": {
        "UserName": "${local.deployment_settings.spADDirSyncUserName}",
        "Password": "${local.service_accounts_password}"
      },
      "SPPassphraseCreds": {
        "UserName": "Passphrase",
        "Password": "${local.service_accounts_password}"
      },
      "SPSuperUserCreds": {
        "UserName": "${local.deployment_settings.spSuperUserName}",
        "Password": "${local.service_accounts_password}"
      },
      "SPSuperReaderCreds": {
        "UserName": "${local.deployment_settings.spSuperReaderName}",
        "Password": "${local.service_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_sp_shutdown" {
  count              = var.auto_shutdown_time == "9999" ? 0 : 1
  virtual_machine_id = azurerm_windows_virtual_machine.vm_sp.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}

# Can create 0 to var.number_additional_frontend FE VMs
resource "azurerm_public_ip" "pip_fe" {
  count               = var.internet_access_method == "PublicIPAddress" ? var.number_additional_frontend : 0
  name                = "PublicIP-${local.vms_settings.vm_fe_name}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(local.resourceGroupNameFormatted)}-${lower(local.vms_settings.vm_fe_name)}-${count.index}"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_fe_0" {
  count               = var.number_additional_frontend
  name                = "NIC-${local.vms_settings.vm_fe_name}-${count.index}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_sp.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.internet_access_method == "PublicIPAddress" ? element(azurerm_public_ip.pip_fe.*.id, count.index) : null
  }
}

resource "azurerm_windows_virtual_machine" "vm_fe" {
  count                    = var.number_additional_frontend
  name                     = "${local.vms_settings.vm_fe_name}-${count.index}"
  computer_name            = "${local.vms_settings.vm_fe_name}-${count.index}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [element(azurerm_network_interface.nic_fe_0.*.id, count.index)]
  size                     = var.vm_sp_size
  admin_username           = local.deployment_settings.localAdminUserName
  admin_password           = local.admin_password
  license_type             = local.license_type
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.vms_settings.vm_fe_name}-${count.index}-OS"
    storage_account_type = var.vm_sp_storage_account_type
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = split(":", local.vms_settings.vms_sharepoint_image)[0]
    offer     = split(":", local.vms_settings.vms_sharepoint_image)[1]
    sku       = split(":", local.vms_settings.vms_sharepoint_image)[2]
    version   = split(":", local.vms_settings.vms_sharepoint_image)[3]
  }
}

resource "azurerm_virtual_machine_extension" "vm_fe_dsc" {
  # count                      = 0
  count                      = var.number_additional_frontend
  name                       = "VM-${local.vms_settings.vm_fe_name}-${count.index}-DSC"
  virtual_machine_id         = element(azurerm_windows_virtual_machine.vm_fe.*.id, count.index)
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
      "DNSServerIP": "${local.network_settings["vmDCPrivateIPAddress"]}",
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
        "Password": "${local.service_accounts_password}"
      },
      "SPFarmCreds": {
        "UserName": "${local.deployment_settings.spFarmUserName}",
        "Password": "${local.service_accounts_password}"
      },
      "SPPassphraseCreds": {
        "UserName": "Passphrase",
        "Password": "${local.service_accounts_password}"
      }
    }
  }
PROTECTED_SETTINGS
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_fe_shutdown" {
  count              = var.number_additional_frontend > 0 && var.auto_shutdown_time != "9999" ? var.number_additional_frontend : 0
  virtual_machine_id = element(azurerm_windows_virtual_machine.vm_fe.*.id, count.index)
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.time_zone

  notification_settings {
    enabled = false
  }
}

# Configuration for Azure Bastion
resource "azurerm_network_security_group" "nsg_subnet_bastion" {
  count               = var.enable_azure_bastion ? 1 : 0
  name                = "NSG-Subnet-AzureBastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_https_inbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowHttpsInBound"
  description                 = "Allow Https InBound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "Internet"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 100
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_gatewaymanager_inbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowGatewayManagerInBound"
  description                 = "Allow Gateway Manager InBound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "GatewayManager"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 110
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_loadbalancer_inbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowLoadBalancerInBound"
  description                 = "Allow Load Balancer InBound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 120
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_bastionhostcommunication_inbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowBastionHostCommunicationInBound"
  description                 = "Allow Bastion Host Communication InBound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_ranges     = ["8080", "5701"]
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  priority                    = 130
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_deny_all_inbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "DenyAllInBound"
  description                 = "Deny All InBound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  access                      = "Deny"
  priority                    = 1000
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_sshrdp_outbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowSshRdpOutBound"
  description                 = "Allow Ssh Rdp OutBound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_ranges     = ["22", "3389"]
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  priority                    = 100
  direction                   = "Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_azurecloud_outbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowAzureCloudCommunicationOutBound"
  description                 = "Allow Azure Cloud Communication OutBound"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "443"
  destination_address_prefix  = "AzureCloud"
  access                      = "Allow"
  priority                    = 110
  direction                   = "Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_bastionhost_outbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowBastionHostCommunicationOutBound"
  description                 = "Allow Bastion Host Communication OutBound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_ranges     = ["8080", "5701"]
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  priority                    = 120
  direction                   = "Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_allow_getsessioninformation_outbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "AllowGetSessionInformationOutBound"
  description                 = "Allow Get Session Information OutBound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_ranges     = ["80", "443"]
  destination_address_prefix  = "Internet"
  access                      = "Allow"
  priority                    = 130
  direction                   = "Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_deny_all_outbound" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "DenyAllOutBound"
  description                 = "Deny All OutBound"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  access                      = "Deny"
  priority                    = 1000
  direction                   = "Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_subnet" "subnet_bastion" {
  count                = var.enable_azure_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.network_settings.vNetPrivateSubnetBastionPrefix]
}

# resource "azurerm_subnet_network_security_group_association" "nsg_subnet_bastion_association" {
#   count                     = var.enable_azure_bastion ? 1 : 0
#   subnet_id                 = azurerm_subnet.subnet_bastion[0].id
#   network_security_group_id = azurerm_network_security_group.nsg_subnet_bastion[0].id
# }

resource "azurerm_public_ip" "pip_bastion" {
  count               = var.enable_azure_bastion ? 1 : 0
  name                = "PublicIP-Bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(local.resourceGroupNameFormatted)}-bastion"
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_bastion_host" "Bastion" {
  count               = var.enable_azure_bastion ? 1 : 0
  name                = "Bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet_bastion[0].id
    public_ip_address_id = azurerm_public_ip.pip_bastion[0].id
  }
}

# Resources for Azure Firewall
resource "azurerm_subnet" "subnet_azfirewall" {
  count                           = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name                            = "AzureFirewallSubnet"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [local.network_settings["vNetAzureFirewallPrefix"]]
  default_outbound_access_enabled = false
}

resource "azurerm_public_ip" "pip_azfirewall" {
  count               = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name                = "PublicIP-azfirewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(local.resourceGroupNameFormatted)}-azfirewall"
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_firewall" "azfirewall" {
  count               = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name                = "Azure-Firewall-Proxy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.azfirewall_policy[0].id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet_azfirewall[0].id
    public_ip_address_id = azurerm_public_ip.pip_azfirewall[0].id
  }
}

resource "azurerm_firewall_policy" "azfirewall_policy" {
  count               = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name                = "Azure_Firewall_policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  explicit_proxy {
    enabled         = true
    http_port       = 8080
    https_port      = 8443
    enable_pac_file = false
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "azfirewall_proxy_rules" {
  count              = var.internet_access_method == "AzureFirewallProxy" ? 1 : 0
  name               = "proxy-rules-collection"
  firewall_policy_id = azurerm_firewall_policy.azfirewall_policy[0].id
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