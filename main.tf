provider "azurerm" {
  features {}
}

locals {
  config_sp_image                       = lookup(local.config_sp_image_list, split("-", var.sharepoint_version)[0])
  config_sp_dsc                         = split("-", var.sharepoint_version)[0] == "Subscription" ? local.config_sp_se_dsc : local.config_sp_legacy_dsc
  config_fe_dsc                         = split("-", var.sharepoint_version)[0] == "Subscription" ? local.config_fe_se_dsc : local.config_fe_legacy_dsc
  create_rdp_rule                       = lower(var.rdp_traffic_allowed) == "no" ? 0 : 1
  admin_password                        = var.admin_password == "" ? random_password.random_admin_password.result : var.admin_password
  service_accounts_password             = var.service_accounts_password == "" ? random_password.random_service_accounts_password.result : var.service_accounts_password
  enable_hybrid_benefit_server_licenses = var.enable_hybrid_benefit_server_licenses == true ? "Windows_Server" : "None"

  general_settings = {
    dscScriptsFolder      = "dsc"
    adfsSvcUserName       = "adfssvc"
    sqlSvcUserName        = "sqlsvc"
    spSetupUserName       = "spsetup"
    spFarmUserName        = "spfarm"
    spSvcUserName         = "spsvc"
    spAppPoolUserName     = "spapppool"
    spADDirSyncUserName   = "spdirsync"
    spSuperUserName       = "spSuperUser"
    spSuperReaderName     = "spSuperReader"
    sqlAlias              = "SQLAlias"
    bastion_publicip_name = "${lower(azurerm_resource_group.rg.name)}-bastion"
  }

  network_settings = {
    vNetPrivatePrefix              = "10.1.0.0/16"
    vNetPrivateSubnetDCPrefix      = "10.1.1.0/24"
    vNetPrivateSubnetSQLPrefix     = "10.1.2.0/24"
    vNetPrivateSubnetSPPrefix      = "10.1.3.0/24"
    vNetPrivateSubnetBastionPrefix = "10.1.4.0/24"
    vmDCPrivateIPAddress           = "10.1.1.4"
  }

  config_dc = {
    vmName             = "DC"
    vmSize             = var.vm_dc_size
    vmImagePublisher   = "MicrosoftWindowsServer"
    vmImageOffer       = "WindowsServer"
    vmImageSKU         = "2022-datacenter-azure-edition-smalldisk"
    storageAccountType = var.vm_dc_storage_account_type
  }

  config_sql = {
    vmName             = "SQL"
    vmSize             = var.vm_sql_size
    vmImagePublisher   = "MicrosoftSQLServer"
    vmImageOffer       = "sql2019-ws2022"
    vmImageSKU         = "sqldev-gen2"
    storageAccountType = var.vm_sql_storage_account_type
  }

  config_sp = {
    vmName             = "SP"
    vmSize             = var.vm_sp_size
    storageAccountType = var.vm_sp_storage_account_type
  }

  config_sp_image_list = {
    "Subscription" = "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest"
    "2019"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2019:latest"
    "2016"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2016:latest"
    "2013"         = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2013:latest"
  }

  config_fe = {
    vmName = "FE"
    vmSize = var.vm_sp_size
  }

  config_dc_dsc = {
    fileName       = "ConfigureDCVM.zip"
    script         = "ConfigureDCVM.ps1"
    function       = "ConfigureDCVM"
    forceUpdateTag = "1.0"
  }

  config_sql_dsc = {
    fileName       = "ConfigureSQLVM.zip"
    script         = "ConfigureSQLVM.ps1"
    function       = "ConfigureSQLVM"
    forceUpdateTag = "1.0"
  }

  config_sp_legacy_dsc = {
    fileName       = "ConfigureSPLegacy.zip"
    script         = "ConfigureSPLegacy.ps1"
    function       = "ConfigureSPVM"
    forceUpdateTag = "1.0"
  }

  config_sp_se_dsc = {
    fileName       = "ConfigureSPSE.zip"
    script         = "ConfigureSPSE.ps1"
    function       = "ConfigureSPVM"
    forceUpdateTag = "1.0"
  }

  config_fe_legacy_dsc = {
    fileName       = "ConfigureFELegacy.zip"
    script         = "ConfigureFELegacy.ps1"
    function       = "ConfigureFEVM"
    forceUpdateTag = "1.0"
  }

  config_fe_se_dsc = {
    fileName       = "ConfigureFESE.zip"
    script         = "ConfigureFESE.ps1"
    function       = "ConfigureFEVM"
    forceUpdateTag = "1.0"
  }
}

# Service account password
resource "random_password" "random_admin_password" {
  length           = 8
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "random_service_accounts_password" {
  length           = 8
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create the network security groups
resource "azurerm_network_security_group" "nsg_subnet_dc" {
  name                = "NSG-Subnet-${local.config_dc["vmName"]}"
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
  name                = "NSG-Subnet-${local.config_sql["vmName"]}"
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
  name                = "NSG-Subnet-${local.config_sp["vmName"]}"
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
  name                = "${azurerm_resource_group.rg.name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.network_settings["vNetPrivatePrefix"]]
}

# Subnet and NSG for DC
resource "azurerm_subnet" "subnet_dc" {
  name                 = "Subnet-${local.config_dc["vmName"]}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.network_settings["vNetPrivateSubnetDCPrefix"]]
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnetdc_association" {
  subnet_id                 = azurerm_subnet.subnet_dc.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_dc.id
}

resource "azurerm_subnet" "subnet_sql" {
  name                 = "Subnet-${local.config_sql["vmName"]}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.network_settings["vNetPrivateSubnetSQLPrefix"]]
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnetsql_association" {
  subnet_id                 = azurerm_subnet.subnet_sql.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_sql.id
}

resource "azurerm_subnet" "subnet_sp" {
  name                 = "Subnet-${local.config_sp["vmName"]}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.network_settings["vNetPrivateSubnetSPPrefix"]]
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnetsp_association" {
  subnet_id                 = azurerm_subnet.subnet_sp.id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_sp.id
}

# Create artifacts for VM DC
resource "azurerm_public_ip" "pip_dc" {
  count               = var.add_public_ip_to_each_vm ? 1 : 0
  name                = "PublicIP-${local.config_dc["vmName"]}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(var.resource_group_name)}-${lower(local.config_dc["vmName"])}"
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_dc_0" {
  name                = "NIC-${local.config_dc["vmName"]}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_dc.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.network_settings["vmDCPrivateIPAddress"]
    public_ip_address_id          = var.add_public_ip_to_each_vm ? azurerm_public_ip.pip_dc[0].id : null
  }
}

# Create artifacts for VM SQL
resource "azurerm_public_ip" "pip_sql" {
  count               = var.add_public_ip_to_each_vm ? 1 : 0
  name                = "PublicIP-${local.config_sql["vmName"]}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(var.resource_group_name)}-${lower(local.config_sql["vmName"])}"
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_sql_0" {
  name                = "NIC-${local.config_sql["vmName"]}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_sql.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.add_public_ip_to_each_vm ? azurerm_public_ip.pip_sql[0].id : null
  }
}

# Create artifacts for VM SP
resource "azurerm_public_ip" "pip_sp" {
  count               = var.add_public_ip_to_each_vm ? 1 : 0
  name                = "PublicIP-${local.config_sp["vmName"]}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(var.resource_group_name)}-${lower(local.config_sp["vmName"])}"
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_sp_0" {
  name                = "NIC-${local.config_sp["vmName"]}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_sp.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.add_public_ip_to_each_vm ? azurerm_public_ip.pip_sp[0].id : null
  }
}

# Create virtual machines
resource "azurerm_windows_virtual_machine" "vm_dc" {
  name                     = local.config_dc["vmName"]
  computer_name            = local.config_dc["vmName"]
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.nic_dc_0.id]
  size                     = local.config_dc["vmSize"]
  admin_username           = var.admin_username
  admin_password           = local.admin_password
  license_type             = local.enable_hybrid_benefit_server_licenses
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.config_dc["vmName"]}-OS"
    storage_account_type = local.config_dc["storageAccountType"]
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = local.config_dc["vmImagePublisher"]
    offer     = local.config_dc["vmImageOffer"]
    sku       = local.config_dc["vmImageSKU"]
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_dc_dsc" {
  # count                      = 0
  name                       = "VM-${local.config_dc["vmName"]}-DSC"
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
	    "url": "${var._artifactsLocation}${local.general_settings["dscScriptsFolder"]}/${local.config_dc_dsc["fileName"]}${var._artifactsLocationSasToken}",
	    "function": "${local.config_dc_dsc["function"]}",
	    "script": "${local.config_dc_dsc["script"]}"
    },
    "configurationArguments": {
      "domainFQDN": "${var.domain_fqdn}",
      "PrivateIP": "${local.network_settings["vmDCPrivateIPAddress"]}"
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
        "UserName": "${local.general_settings["adfsSvcUserName"]}",
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
  name                     = local.config_sql["vmName"]
  computer_name            = local.config_sql["vmName"]
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.nic_sql_0.id]
  size                     = local.config_sql["vmSize"]
  admin_username           = "local-${var.admin_username}"
  admin_password           = local.admin_password
  license_type             = local.enable_hybrid_benefit_server_licenses
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.config_sql["vmName"]}-OS"
    storage_account_type = local.config_sql["storageAccountType"]
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = local.config_sql["vmImagePublisher"]
    offer     = local.config_sql["vmImageOffer"]
    sku       = local.config_sql["vmImageSKU"]
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_sql_dsc" {
  # count                      = 0
  name                       = "VM-${local.config_sql["vmName"]}-DSC"
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
	    "url": "${var._artifactsLocation}${local.general_settings["dscScriptsFolder"]}/${local.config_sql_dsc["fileName"]}${var._artifactsLocationSasToken}",
	    "function": "${local.config_sql_dsc["function"]}",
	    "script": "${local.config_sql_dsc["script"]}"
    },
    "configurationArguments": {
      "DNSServer": "${local.network_settings["vmDCPrivateIPAddress"]}",
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
        "UserName": "${local.general_settings["sqlSvcUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPSetupCreds": {
        "UserName": "${local.general_settings["spSetupUserName"]}",
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
  name                     = local.config_sp["vmName"]
  computer_name            = local.config_sp["vmName"]
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [azurerm_network_interface.nic_sp_0.id]
  size                     = local.config_sp["vmSize"]
  admin_username           = "local-${var.admin_username}"
  admin_password           = local.admin_password
  license_type             = local.enable_hybrid_benefit_server_licenses
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.config_sp["vmName"]}-OS"
    storage_account_type = local.config_sp["storageAccountType"]
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = split(":", local.config_sp_image)[0]
    offer     = split(":", local.config_sp_image)[1]
    sku       = split(":", local.config_sp_image)[2]
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_sp_dsc" {
  # count                      = 0
  name                       = "VM-${local.config_sp["vmName"]}-DSC"
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
	    "url": "${var._artifactsLocation}${local.general_settings["dscScriptsFolder"]}/${local.config_sp_dsc["fileName"]}${var._artifactsLocationSasToken}",
	    "function": "${local.config_sp_dsc["function"]}",
	    "script": "${local.config_sp_dsc["script"]}"
    },
    "configurationArguments": {
      "DNSServer": "${local.network_settings["vmDCPrivateIPAddress"]}",
      "DomainFQDN": "${var.domain_fqdn}",
      "DCName": "${local.config_dc["vmName"]}",
      "SQLName": "${local.config_sql["vmName"]}",
      "SQLAlias": "${local.general_settings["sqlAlias"]}",
      "SharePointVersion": "${var.sharepoint_version}",
      "EnableAnalysis": false
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
        "UserName": "${local.general_settings["spSetupUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPFarmCreds": {
        "UserName": "${local.general_settings["spFarmUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPSvcCreds": {
        "UserName": "${local.general_settings["spSvcUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPAppPoolCreds": {
        "UserName": "${local.general_settings["spAppPoolUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPADDirSyncCreds": {
        "UserName": "${local.general_settings["spADDirSyncUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPPassphraseCreds": {
        "UserName": "Passphrase",
        "Password": "${local.service_accounts_password}"
      },
      "SPSuperUserCreds": {
        "UserName": "${local.general_settings["spSuperUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPSuperReaderCreds": {
        "UserName": "${local.general_settings["spSuperReaderName"]}",
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
  count               = var.add_public_ip_to_each_vm ? var.number_additional_frontend : 0
  name                = "PublicIP-${local.config_fe["vmName"]}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${lower(var.resource_group_name)}-${lower(local.config_fe["vmName"])}-${count.index}"
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
}

resource "azurerm_network_interface" "nic_fe_0" {
  count               = var.number_additional_frontend
  name                = "NIC-${local.config_fe["vmName"]}-${count.index}-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_sp.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.add_public_ip_to_each_vm ? element(azurerm_public_ip.pip_fe.*.id, count.index) : null
  }
}

resource "azurerm_windows_virtual_machine" "vm_fe" {
  count                    = var.number_additional_frontend
  name                     = "${local.config_fe["vmName"]}-${count.index}"
  computer_name            = "${local.config_fe["vmName"]}-${count.index}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  network_interface_ids    = [element(azurerm_network_interface.nic_fe_0.*.id, count.index)]
  size                     = local.config_sp["vmSize"]
  admin_username           = "local-${var.admin_username}"
  admin_password           = local.admin_password
  license_type             = local.enable_hybrid_benefit_server_licenses
  timezone                 = var.time_zone
  enable_automatic_updates = true
  provision_vm_agent       = true

  os_disk {
    name                 = "Disk-${local.config_fe["vmName"]}-${count.index}-OS"
    storage_account_type = local.config_sp["storageAccountType"]
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = split(":", local.config_sp_image)[0]
    offer     = split(":", local.config_sp_image)[1]
    sku       = split(":", local.config_sp_image)[2]
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_fe_dsc" {
  # count                      = 0
  count                      = var.number_additional_frontend
  name                       = "VM-${local.config_fe["vmName"]}-${count.index}-DSC"
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
	    "url": "${var._artifactsLocation}${local.general_settings["dscScriptsFolder"]}/${local.config_fe_dsc["fileName"]}${var._artifactsLocationSasToken}",
	    "function": "${local.config_fe_dsc["function"]}",
	    "script": "${local.config_fe_dsc["script"]}"
    },
    "configurationArguments": {
      "DNSServer": "${local.network_settings["vmDCPrivateIPAddress"]}",
      "DomainFQDN": "${var.domain_fqdn}",
      "DCName": "${local.config_dc["vmName"]}",
      "SQLName": "${local.config_sql["vmName"]}",
      "SQLAlias": "${local.general_settings["sqlAlias"]}",
      "SharePointVersion": "${var.sharepoint_version}",
      "EnableAnalysis": false
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
        "UserName": "${local.general_settings["spSetupUserName"]}",
        "Password": "${local.service_accounts_password}"
      },
      "SPFarmCreds": {
        "UserName": "${local.general_settings["spFarmUserName"]}",
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

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_inbound_internet" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "inbound-443-Internet"
  description                 = "Allow RDP"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 120
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_inbound_gatewaymanager" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "inbound-443-GatewayManager"
  description                 = "Allow RDP"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  access                      = "Allow"
  priority                    = 130
  direction                   = "Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_outbound_rdp" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "outbound-3389-RDP"
  description                 = "Allow RDP"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  priority                    = 120
  direction                   = "Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_outbound_ssh" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "outbound-22-SSH"
  description                 = "Allow SSH"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  access                      = "Allow"
  priority                    = 121
  direction                   = "Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_subnet_bastion[0].name
}

resource "azurerm_network_security_rule" "rdp_rule_subnet_bastion_outbound_azurecloud" {
  count                       = var.enable_azure_bastion ? 1 : 0
  name                        = "outbound-443-AzureCloud"
  description                 = "Allow AzureCloud"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  access                      = "Allow"
  priority                    = 130
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

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_bastion_association" {
  count                     = var.enable_azure_bastion ? 1 : 0
  subnet_id                 = azurerm_subnet.subnet_bastion[0].id
  network_security_group_id = azurerm_network_security_group.nsg_subnet_bastion[0].id
}

resource "azurerm_public_ip" "pip_bastion" {
  count               = var.enable_azure_bastion ? 1 : 0
  name                = "PublicIP-Bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = local.general_settings.bastion_publicip_name
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