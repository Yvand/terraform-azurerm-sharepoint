variable "subscription_id" {
  type        = string
  description = "The ID of the Azure subscription where the resources will be deployed."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "The resource group name of the resource group where the resources will be deployed."
  nullable    = false
}

variable "location" {
  type        = string
  default     = "francecentral"
  description = "The Azure region where this and supporting resources should be deployed."
  nullable    = false
}

variable "sharepoint_version" {
  type        = string
  default     = "Subscription-Latest"
  description = "Version of SharePoint farm to create."
  validation {
    condition = contains([
      "Subscription-Latest",
      "Subscription-25H2",
      "Subscription-25H1",
      "Subscription-24H2",
      "Subscription-24H1",
      "Subscription-23H2",
      "Subscription-23H1",
      "Subscription-22H2",
      "Subscription-RTM",
      "2019",
      "2016"
    ], var.sharepoint_version)
    error_message = "Invalid SharePoint farm version."
  }
}

variable "domain_fqdn" {
  type        = string
  default     = "contoso.local"
  description = "FQDN of the Active Directory forest."
}

variable "front_end_servers_count" {
  type        = number
  default     = 0
  description = "Number of servers with MinRole Front-end to add to the farm."
  validation {
    condition     = var.front_end_servers_count >= 0 && var.front_end_servers_count <= 4
    error_message = "The front_end_servers_count value must be between 0 and 4 included."
  }
}

variable "admin_username" {
  type        = string
  default     = "yvand"
  description = "Name of the Active Directory and SharePoint administrator. 'admin' and 'administrator' are not allowed."
  validation {
    condition = !contains([
      "admin",
      "administrator"
    ], var.admin_username)
    error_message = "'admin' and 'administrator' are not allowed as value of admin_username."
  }
}

variable "admin_password" {
  type        = string
  default     = ""
  description = "Password for the admin account. Leave empty to auto-generate a password that will be recorded in the state file. If set, the input must meet password complexity requirements as documented in https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-"
  nullable    = true
}

variable "other_accounts_password" {
  type        = string
  default     = ""
  description = "Password for all the other accounts and the SharePoint passphrase. Leave empty to auto-generate a password that will be recorded in the state file. If set, the input must meet password complexity requirements as documented in https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-"
  nullable    = true
}

variable "rdp_traffic_rule" {
  type        = string
  default     = "No"
  description = <<EOF
    Specify if a rule in the network security groups should allow the inbound RDP traffic:
    - "No" (default): No rule is created, RDP traffic is blocked.
    - "*" or "Internet": RDP traffic is allowed from everywhere.
    - CIDR notation (e.g. 192.168.99.0/24 or 2001:1234::/64) or an IP address (e.g. 192.168.99.0 or 2001:1234::): RDP traffic is allowed from the IP address / pattern specified.
  EOF
}

variable "outbound_access_method" {
  type        = string
  default     = "PublicIPAddress"
  description = <<EOF
    Select how the virtual machines connect to internet.
    IMPORTANT: With AzureFirewallProxy, you need to either enable Azure Bastion, or manually add a public IP address to a virtual machine, to be able to connect to it.
  EOF
  validation {
    condition = contains([
      "PublicIPAddress",
      "AzureFirewallProxy"
    ], var.outbound_access_method)
    error_message = "Invalid value for outbound_access_method."
  }
}

variable "add_name_to_public_ip_addresses" {
  type        = string
  default     = "SharePointVMsOnly"
  description = "Set if the Public IP addresses of virtual machines should have a name label."
  validation {
    condition = contains([
      "No",
      "SharePointVMsOnly",
      "Yes"
    ], var.add_name_to_public_ip_addresses)
    error_message = "Invalid value selected."
  }
}

variable "enable_azure_bastion" {
  type        = bool
  default     = false
  description = "Specify if Azure Bastion Developer should be provisioned. See https://azure.microsoft.com/en-us/services/azure-bastion for more information."
}

variable "enable_hybrid_benefit_server_licenses" {
  type        = bool
  default     = false
  description = "Enable the Azure Hybrid Benefit on virtual machines, to use your on-premises Windows Server licenses and reduce cost. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/hybrid-use-benefit-licensing for more information.'"
}

variable "time_zone" {
  type        = string
  default     = "Romance Standard Time"
  description = "Time zone of the virtual machines. Type '[TimeZoneInfo]::GetSystemTimeZones().Id' in PowerShell to get the list."
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

variable "auto_shutdown_time" {
  type        = string
  default     = "1900"
  description = "The time (24h HHmm format) at which the virtual machines will automatically be shutdown and deallocated. Set value to '9999' to NOT configure the auto shutdown."
  validation {
    condition     = can(regex("^\\d{4}$", var.auto_shutdown_time))
    error_message = "The auto_shutdown_time value must contain 4 digits."
  }
}

variable "vm_dc_size" {
  type        = string
  default     = "Standard_B2als_v2"
  description = "Size of the DC virtual machine."
}

variable "vm_dc_storage" {
  type        = string
  default     = "StandardSSD_LRS"
  description = "Type of storage for the managed disk. Visit https://docs.microsoft.com/en-us/rest/api/compute/disks/list#diskstorageaccounttypes for more information."
  validation {
    condition = contains([
      "Standard_LRS",
      "StandardSSD_LRS",
      "StandardSSD_ZRS",
      "Premium_LRS",
      "PremiumV2_LRS",
      "Premium_ZRS",
      "UltraSSD_LRS"
    ], var.vm_dc_storage)
    error_message = "Invalid storage type."
  }
}

variable "vm_sql_size" {
  type        = string
  default     = "Standard_B2as_v2"
  description = "Size of the SQL virtual machine."
}

variable "vm_sql_storage" {
  type        = string
  default     = "StandardSSD_LRS"
  description = "Type of storage for the managed disk. Visit https://docs.microsoft.com/en-us/rest/api/compute/disks/list#diskstorageaccounttypes for more information."
  validation {
    condition = contains([
      "Standard_LRS",
      "StandardSSD_LRS",
      "StandardSSD_ZRS",
      "Premium_LRS",
      "PremiumV2_LRS",
      "Premium_ZRS",
      "UltraSSD_LRS"
    ], var.vm_sql_storage)
    error_message = "Invalid storage type."
  }
}

variable "vm_sp_size" {
  type        = string
  default     = "Standard_B4as_v2"
  description = "Size of the SharePoint virtual machine(s)."
}

variable "vm_sp_storage" {
  type        = string
  default     = "StandardSSD_LRS"
  description = "Type of storage for the managed disk. Visit https://docs.microsoft.com/en-us/rest/api/compute/disks/list#diskstorageaccounttypes for more information."
  validation {
    condition = contains([
      "Standard_LRS",
      "StandardSSD_LRS",
      "StandardSSD_ZRS",
      "Premium_LRS",
      "PremiumV2_LRS",
      "Premium_ZRS",
      "UltraSSD_LRS"
    ], var.vm_sp_storage)
    error_message = "Invalid storage type."
  }
}

variable "_artifactsLocation" {
  type        = string
  description = "The base URI where artifacts required by this template are located including a trailing '/'"
  default     = "https://raw.githubusercontent.com/Yvand/terraform-azurerm-sharepoint/7.6.0/dsc/"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply on the resources."
  nullable    = true
}

variable "add_default_tags" {
  type        = bool
  default     = false
  description = "If true, the default tags will be added to the resources. Default tags are: 'source', 'createdOn', and 'sharePointVersion'."
}

variable "vm_availability_zone" {
  type        = number
  default     = null
  description = "The Availability Zone which the Virtual Machines should be allocated in. If deploying to a region without zones, set this value to null. If the zone should be assigned randomly, set this value to 0."
  nullable    = true
}