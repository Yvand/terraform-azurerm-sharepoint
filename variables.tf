variable "location" {
  default     = "West Europe"
  description = "Location where resources will be provisioned"
}

variable "resource_group_name" {
  description = "Name of the ARM resource group to create"
}

variable "sharepoint_version" {
  default     = "SE"
  description = "Version of SharePoint farm to create."
}

variable "dns_label_prefix" {
  description = "[Prefix] of public DNS names of VMs, e.g. '[Prefix]-[VMName].[region].cloudapp.azure.com'"
}

variable "admin_username" {
  default     = "yvand"
  description = "Name of the AD and SharePoint administrator. 'administrator' is not allowed"
}

variable "admin_password" {
  description = "Input must meet password complexity requirements as documented for property 'admin_password' in https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/virtualmachines-create-or-update"
}

variable "service_accounts_password" {
  description = "Input must meet password complexity requirements as documented for property 'admin_password' in https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/virtualmachines-create-or-update"
}

variable "domain_fqdn" {
  default     = "contoso.local"
  description = "FQDN of the AD forest to create"
}

variable "time_zone" {
  default     = "Romance Standard Time"
  description = "Time zone of the virtual machines."
  validation {
    condition = contains([
      "Dateline Standard Time",
      "UTC-11",
      "Aleutian Standard Time",
      "Hawaiian Standard Time",
      "Marquesas Standard Time",
      "Alaskan Standard Time",
      "UTC-09",
      "Pacific Standard Time (Mexico)",
      "UTC-08",
      "Pacific Standard Time",
      "US Mountain Standard Time",
      "Mountain Standard Time (Mexico)",
      "Mountain Standard Time",
      "Central America Standard Time",
      "Central Standard Time",
      "Easter Island Standard Time",
      "Central Standard Time (Mexico)",
      "Canada Central Standard Time",
      "SA Pacific Standard Time",
      "Eastern Standard Time (Mexico)",
      "Eastern Standard Time",
      "Haiti Standard Time",
      "Cuba Standard Time",
      "US Eastern Standard Time",
      "Turks And Caicos Standard Time",
      "Paraguay Standard Time",
      "Atlantic Standard Time",
      "Venezuela Standard Time",
      "Central Brazilian Standard Time",
      "SA Western Standard Time",
      "Pacific SA Standard Time",
      "Newfoundland Standard Time",
      "Tocantins Standard Time",
      "E. South America Standard Time",
      "SA Eastern Standard Time",
      "Argentina Standard Time",
      "Greenland Standard Time",
      "Montevideo Standard Time",
      "Magallanes Standard Time",
      "Saint Pierre Standard Time",
      "Bahia Standard Time",
      "UTC-02",
      "Mid-Atlantic Standard Time",
      "Azores Standard Time",
      "Cape Verde Standard Time",
      "UTC",
      "GMT Standard Time",
      "Greenwich Standard Time",
      "Sao Tome Standard Time",
      "Morocco Standard Time",
      "W. Europe Standard Time",
      "Central Europe Standard Time",
      "Romance Standard Time",
      "Central European Standard Time",
      "W. Central Africa Standard Time",
      "Jordan Standard Time",
      "GTB Standard Time",
      "Middle East Standard Time",
      "Egypt Standard Time",
      "E. Europe Standard Time",
      "Syria Standard Time",
      "West Bank Standard Time",
      "South Africa Standard Time",
      "FLE Standard Time",
      "Israel Standard Time",
      "Kaliningrad Standard Time",
      "Sudan Standard Time",
      "Libya Standard Time",
      "Namibia Standard Time",
      "Arabic Standard Time",
      "Turkey Standard Time",
      "Arab Standard Time",
      "Belarus Standard Time",
      "Russian Standard Time",
      "E. Africa Standard Time",
      "Iran Standard Time",
      "Arabian Standard Time",
      "Astrakhan Standard Time",
      "Azerbaijan Standard Time",
      "Russia Time Zone 3",
      "Mauritius Standard Time",
      "Saratov Standard Time",
      "Georgian Standard Time",
      "Volgograd Standard Time",
      "Caucasus Standard Time",
      "Afghanistan Standard Time",
      "West Asia Standard Time",
      "Ekaterinburg Standard Time",
      "Pakistan Standard Time",
      "Qyzylorda Standard Time",
      "India Standard Time",
      "Sri Lanka Standard Time",
      "Nepal Standard Time",
      "Central Asia Standard Time",
      "Bangladesh Standard Time",
      "Omsk Standard Time",
      "Myanmar Standard Time",
      "SE Asia Standard Time",
      "Altai Standard Time",
      "W. Mongolia Standard Time",
      "North Asia Standard Time",
      "N. Central Asia Standard Time",
      "Tomsk Standard Time",
      "China Standard Time",
      "North Asia East Standard Time",
      "Singapore Standard Time",
      "W. Australia Standard Time",
      "Taipei Standard Time",
      "Ulaanbaatar Standard Time",
      "Aus Central W. Standard Time",
      "Transbaikal Standard Time",
      "Tokyo Standard Time",
      "North Korea Standard Time",
      "Korea Standard Time",
      "Yakutsk Standard Time",
      "Cen. Australia Standard Time",
      "AUS Central Standard Time",
      "E. Australia Standard Time",
      "AUS Eastern Standard Time",
      "West Pacific Standard Time",
      "Tasmania Standard Time",
      "Vladivostok Standard Time",
      "Lord Howe Standard Time",
      "Bougainville Standard Time",
      "Russia Time Zone 10",
      "Magadan Standard Time",
      "Norfolk Standard Time",
      "Sakhalin Standard Time",
      "Central Pacific Standard Time",
      "Russia Time Zone 11",
      "New Zealand Standard Time",
      "UTC+12",
      "Fiji Standard Time",
      "Kamchatka Standard Time",
      "Chatham Islands Standard Time",
      "UTC+13",
      "Tonga Standard Time",
      "Samoa Standard Time",
      "Line Islands Standard Time"
    ], var.time_zone)
    error_message = "Invalid time zone value."
  }
}

variable "number_additional_frontend" {
  default     = 0
  description = "Number of MinRole Front-end to add to the farm. The MinRole type can be changed later as needed."
}

variable "rdp_traffic_allowed" {
  default     = "No"
  description = "Specify if RDP traffic is allowed to connect to the VMs:<br>- If 'No' (default): Firewall denies all incoming RDP traffic from Internet.<br>- If '*' or 'Internet': Firewall accepts all incoming RDP traffic from Internet.<br>- If 'ServiceTagName': Firewall accepts all incoming RDP traffic from the specified 'ServiceTagName'.<br>- If 'xx.xx.xx.xx': Firewall accepts incoming RDP traffic only from the IP 'xx.xx.xx.xx'."
}

variable "general_settings" {
  type = map(string)
  default = {
    dscScriptsFolder  = "dsc"
    adfsSvcUserName   = "adfssvc"
    sqlSvcUserName    = "sqlsvc"
    spSetupUserName   = "spsetup"
    spFarmUserName    = "spfarm"
    spSvcUserName     = "spsvc"
    spAppPoolUserName = "spapppool"
    spSuperUserName   = "spSuperUser"
    spSuperReaderName = "spSuperReader"
    sqlAlias          = "SQLAlias"
  }
}

variable "network_settings" {
  type = map(string)
  default = {
    vNetPrivatePrefix          = "10.1.0.0/16"
    vNetPrivateSubnetDCPrefix  = "10.1.1.0/24"
    vNetPrivateSubnetSQLPrefix = "10.1.2.0/24"
    vNetPrivateSubnetSPPrefix  = "10.1.3.0/24"
    vmDCPrivateIPAddress       = "10.1.1.4"
  }
}

variable "config_dc" {
  type = map(string)
  default = {
    vmName             = "DC"
    vmSize             = "Standard_B2s"
    vmImagePublisher   = "MicrosoftWindowsServer"
    vmImageOffer       = "WindowsServer"
    vmImageSKU         = "2022-datacenter-azure-edition-smalldisk"
    storageAccountType = "Standard_LRS"
  }
}

variable "config_sql" {
  type = map(string)
  default = {
    vmName             = "SQL"
    vmSize             = "Standard_B2ms"
    vmImagePublisher   = "MicrosoftSQLServer"
    vmImageOffer       = "sql2019-ws2022"
    vmImageSKU         = "sqldev-gen2"
    storageAccountType = "Standard_LRS"
  }
}

variable "config_sp" {
  type = map(string)
  default = {
    vmName = "SP"
    vmSize = "Standard_B4ms"
    # vmImagePublisher   = "MicrosoftWindowsServer"
    # vmImageOffer       = "WindowsServer"
    # vmImageSKU         = "2022-datacenter-azure-edition"
    storageAccountType = "Standard_LRS"
  }
}

variable "config_sp_image" {
  type = map(any)
  default = {
    "SE"   = "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest"
    "2019" = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2019:latest"
    "2016" = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2016:latest"
    "2013" = "MicrosoftSharePoint:MicrosoftSharePointServer:sp2013:latest"
  }
}

variable "config_fe" {
  type = map(string)
  default = {
    vmName = "FE"
    vmSize = "Standard_B4ms"
  }
}

variable "config_dc_dsc" {
  type = map(string)
  default = {
    fileName       = "ConfigureDCVM.zip"
    script         = "ConfigureDCVM.ps1"
    function       = "ConfigureDCVM"
    forceUpdateTag = "1.0"
  }
}

variable "config_sql_dsc" {
  type = map(string)
  default = {
    fileName       = "ConfigureSQLVM.zip"
    script         = "ConfigureSQLVM.ps1"
    function       = "ConfigureSQLVM"
    forceUpdateTag = "1.0"
  }
}

variable "config_sp_dsc" {
  type = map(string)
  default = {
    fileName       = "ConfigureSPVM.zip"
    script         = "ConfigureSPVM.ps1"
    function       = "ConfigureSPVM"
    forceUpdateTag = "1.0"
  }
}

variable "config_fe_dsc" {
  type = map(string)
  default = {
    fileName       = "ConfigureFEVM.zip"
    script         = "ConfigureFEVM.ps1"
    function       = "ConfigureFEVM"
    forceUpdateTag = "1.0"
  }
}

variable "_artifactsLocation" {
  default = "https://github.com/Azure/azure-quickstart-templates/raw/master/application-workloads/sharepoint/sharepoint-adfs/"
}

variable "_artifactsLocationSasToken" {
  default = ""
}
