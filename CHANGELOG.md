# Changelog for terraform-azurerm-sharepoint

## [6.1.0] - Unreleased

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the February 2025 CU for SharePoint Subscription

### Fixed

- DSC Configuration for DC
  - Removed NetConnectionProfile (to set the network interface as private) as it randomly causes errors


## [6.0.0] - 25-01-17

### Changed

- Template
  - Enabled [Trusted launch](https://learn.microsoft.com/azure/virtual-machines/trusted-launch-existing-vm), with secure boot and Virtual Trusted Platform Module, on all virtual machines except SharePoint 2016
  - Added variable `add_name_to_public_ip_addresses`, to set which virtual machines have a public name associated to their public IP address.
  - [BREAKING CHANGE] With the default value of new variable `add_name_to_public_ip_addresses` set to `SharePointVMsOnly`, now, only SharePoint VMs have a public name by default. Other VMs only have a public IP.
  - Upgraded the virtual machines DC and SharePoint Subscription to Windows Server 2025.
  - Changed the network configuration to use a single subnet for all the virtual machines. This avoids potential network issues due to Defender network access policies, which may block some traffic between subnets due to a JIT access configuration.
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the January 2025 CU for SharePoint Subscription

- All DSC configurations
  - Bumped DSC modules

- DSC Configuration for SPSE
  - Renamed the root site to "root site"

- DSC Configuration for DC
  - Set the network interface as a private connection

## [5.3.0] - 24-12-11

### Changed

- Template
  - Update the default size of the virtual machines to use the [Basv2 series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/general-purpose/basv2-series?tabs=sizebasic). It is newer, cheaper and more performant than the [Bv1 series](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/general-purpose/bv1-series?tabs=sizebasic) used until now.
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the December 2024 CU for SharePoint Subscription

## [5.2.0] - 24-11-18

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the November 2024 CU for SharePoint Subscription

### Fixed

- Template
  - Stopped using the Windows Server's [small disk](https://azure.microsoft.com/en-us/blog/new-smaller-windows-server-iaas-image/) image for SharePoint Subscription VMs, as SharePoint updates no longer have enough free disk space to be installed.

## [5.1.0] - 24-10-23

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the October 2024 CU for SharePoint Subscription

## [5.0.0] - 24-09-11

### Added

- Template
  - [BREAKING CHANGE] Add variable `subscription_id`, required after upgrading provider `azurerm` to version 4.1
  - [BREAKING CHANGE] Add variable `outbound_access_method`, to choose how the virtual machines connect to internet. Now, they can connect through either a public IP, or using Azure Firewall as an HTTP proxy
  - Add value `Subscription-24H2` to parameter `sharepoint_version`, to install SharePoint Subscription with 24H2 update

### Changed

- Template
  - [BREAKING CHANGE] Upgrade provider `azurerm` to version 4.1
  - [BREAKING CHANGE] Minimim version required for terraform core is now 1.9.5
  - [BREAKING CHANGE] Rename most of the variables
  - Change the SKU of the public IP resources from Basic to Standard, due to Basic SKU being deprecated - https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-basic-upgrade-guidance
  - Update the display name of most of the resources to be more consistent and reflect their relationship with each other
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the September 2024 CU for SharePoint Subscription
- All DSC configurations
  - Add a firewall rule to all virtual machines to allow remote event viewer connections

## [4.6.0] - 24-08-20

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the August 2024 CU for SharePoint Subscription

## [4.5.0] - 24-07-11

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the July 2024 CU for SharePoint Subscription

## [4.4.0] - 24-06-18

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the June 2024 CU for SharePoint Subscription

## [4.3.0] - 24-06-04

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the May 2024 CU for SharePoint Subscription
- DSC configurations
  - Updated DSC module `ActiveDirectoryDsc` to 6.4.0
  - Updated DSC module `ComputerManagementDsc` to 9.1.0
  - Updated DSC module `SharePointDSC` to 5.5.0

## [4.2.0] - 24-04-10

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the April 2024 CU for SharePoint Subscription

## [4.1.0] - 24-03-15

- Template
  - Added value `Subscription-24H1` to parameter `sharePointVersion`, which installs the March 2024 CU (24H1) for SharePoint Subscription

## [4.0.1] - 24-02-26

- Template
  - Set the minimum version required for provider `azurerm` to 3.88, which is the one that introduced resource `azurerm_virtual_machine_run_command`

## [4.0.0] - 24-02-26

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the February 2024 CU for SharePoint Subscription
  - Remove provider `azure/azapi`, and use new `resource azurerm_virtual_machine_run_command` added recently to provider `azurerm`
  - Remove SharePoint 2013
- All SharePoint configurations
  - Add network share `SPLOGS` on folder `C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\LOGS`
- Configuration for SPSE
  - Update the registry keys required to allow OneDrive on OIDC authentication
  - Update claims provider to LDAPCPSE
  - It is no longer needed to restart the VM to be able to create the SPTrustedIdentityTokenIssuer, which saves a few minutes
- Configuration for SPLE
  - Update claims provider to LDAPCPSE
  - It is no longer needed to restart the VM to be able to create the SPTrustedIdentityTokenIssuer, which saves a few minutes

## [3.14.0] - 24-01-11

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the January 2024 CU for SharePoint Subscription

## [3.13.0] - 23-12-18

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the December 2023 CU for SharePoint Subscription
  - Add a resource `azapi_resource` from provider `azapi` to run a script that increases MaxEnvelopeSizeKb on SPSE, so that service WS-Management in SPSE can process the bigger DSC script
- Configuration for SPSE
  - Add claim type groupsid to make the switch to SPTrustedBackedByUPAClaimProvider easier. There are remaining steps needed to finalize its configuration
  - Set registry keys to configure OneDrive NGSC for OIDC authentication
- Configuration for DC
  - Bump DSC module AdfsDsc

## [3.12.1] - 23-11-21

### Changed

- Module
  - Upgrade provider azurerm to fix ExpiredAuthenticationToken - https://github.com/hashicorp/terraform-provider-azurerm/issues/20867

## [3.12.0] - 23-11-15

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the November 2023 CU for SharePoint Subscription
- Configuration for SPSE
  - Configure the SPTrustedBackedByUPAClaimProvider (as much as possible). There are remaining steps needed to finalize its configuration
  - Update creation of user profiles to set their PreferredName
  - Format the document
- Configuration for most VMs
  - Bump DSC modules ActiveDirectoryDsc and SqlServerDsc

## [3.11.0] - 23-10-12

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the October 2023 CU for SharePoint Subscription

### Fixed
- All SharePoint configurations
  - Fixed regression with installation of Chocolatey

## [3.10.0] - 23-09-13

### Changed

- Template
  - Added value `Subscription-23H2` to parameter `sharepoint_version`, to install SharePoint Subscription with 23H2 update
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the September 2023 CU for SharePoint Subscription (23H2 update)

## [3.9.0] - 23-08-17

### Fixed

- Configuration for SPSE
  - When doing a slipstream install of SharePoint using 2022-10 CU or newer: Fixed the SharePoint configuration wizard hanging at 10% of step 10/10, when executed after installing a CU

### Changed

- Template
  - Changed the prefix of the built-in administrator from `local-` to `l-` so it does not exceed 15 characters, because the reset password feature in Azure requires that it has 15 characters maximum.
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the August 2023 CU for SharePoint Subscription

## [3.8.0] - 23-07-12

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the July 2023 CU for SharePoint Subscription

## [3.7.1] - 23-06-30

### Fixed

- Configuration for SP Legacy and FE Legacy (SharePoint 2019 / 2016 / 2013 VMs)
  - Fixed the deployment error caused by DSC resource cChocoInstaller

## [3.7.0] - 23-06-19

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the June 2023 CU for SharePoint Subscription
  - Updated SQL image to use SQL Server 2022 on Windows Server 2022.
- Configuration for all virtual machines
  - Update DSC module `ComputerManagementDsc`
- Configuration for all VMs except DC
  - Update DSC module `SqlServerDsc`
- Configuration for SPSE and FESE
  - Update DSC module `StorageDsc`
- Configuration for DC
  - Update DSC module `AdfsDsc`

## [3.6.0] - 23-06-01

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the May 2023 CU for SharePoint Subscription

## [3.5.0] - 23-04-12

### Changed

- Template
  - Value `Subscription-Latest` for parameter `sharePointVersion` now installs the April 2023 CU for SharePoint Subscription

## [3.4.0] - 23-04-06

### Added

- Template
  - Added value `Subscription-23H1` to parameter `sharepoint_version`, to install SharePoint Subscription with 23H1 update

### Changed

- Configuration for SQL
  - Update SQL module `SqlServer` and DSC module `SqlServerDsc`
- Configuration for DC
  - Update DSC module `AdfsDsc`
- Configuration for all SharePoint versions
  - Update DSC module `SharePointDsc`
- Configuration for SharePoint Subscription
  - Add domain administrator as a SharePoint shell admin (done by cmdlet `Add-SPShellAdmin`)
  - For OIDC: Change the nonce secret key to a more unique value and rename the certificate used to sign the nonce

## [3.3.0] - 23-03-10

### Changed

- Module
  - Removed the no-longer necessary dependency on provider `null`
  - Updated value `Subscription-latest` of variable `sharepoint_version`, to install the February 2023 CU on SharePoint Subscription

## [3.2.0] - 23-02-06

### Added

- Template
  - Added value `Subscription-latest` to variable `sharepoint_version`, to install the January 2023 CU on SharePoint Subscription
- Configuration for DC
  - Create additional users in AD, in a dedicated OU `AdditionalUsers`
- Configuration for SQL
  - Install SQL module `SqlServer` (version 21.1.18256) as it is the preferred option of `SqlServerDsc`
- Configuration for all SharePoint versions
  - Create various desktop shortcuts
  - Configure Windows explorer to always show file extensions and expand the ribbon
  - Enqueue the creation of the personal sites of the admin and all users in OU `AdditionalUsers`, for both Windows and trusted authentication modes
  - Add the OU `AdditionalUsers` to the User Profile synchronization connection
  - Grant the domain administrator `Full Control` to the User Profile service application
- Configuration for SharePoint Subscription and 2019
  - Set OneDrive NGSC registry keys to be able to sync sites located under MySites path

### Changed

- Template
  - Revert SQL image to SQL Server 2019, due to reliability issues with SQL Server 2022 (SQL PowerShell modules not ready yet)
  - If user chooses SharePoint 2013, template deploys SQL Server 2014 SP3 (latest version it supports)
- Configuration for DC
  - Review the logic to allow the VM to restart after the AD FS farm was configured (as required), and before the other VMs attempt to join the domain
- Configuration for all VMs except DC
  - Review the logic to join the AD domain only after it is guaranteed that the DC is ready. This fixes the most common cause of random deployment errors

## [3.1.0] - 23-01-11

- Use a small disk (32 GB) on SharePoint Subscription and SharePoint 2019 VMs.
- Updated SQL image to use SQL Server 2022 on Windows Server 2022.
- The resource group's name is used in the virtual network and the public IP resources, but now it is formatted to handle the restrictions on the characters allowed.
- Apply browser policies for Edge and Chrome to get rid of noisy wizards / homepages / new tab content.
- Reorganize the local variables in the module to be more consistent.

## [3.0.0] - 22-11-29

### Changed

- BREAKING CHANGE: Renamed variable `add_public_ip_to_each_vm` to `add_public_ip_address` and changed its type to `string` to provide more granularity. Its default value is now `"SharePointVMsOnly"`, to assign a public IP address only to SharePoint VMs
- Moved the definition of SharePoint Subscription packages list from DSC to the module itself
- Changed SKU of Public IP address resources to use Basic instead of Standard (except for Bastion which requires Standard)
- Changed allocation method of Public IP address resources to use Dynamic instead of Static (except for Bastion which requires Static)
- Updated the test for the value of variable `auto_shutdown_time`
- Moved variable `_artifactsLocationSasToken` to locals

### Fixed

- Fixed the random error `NetworkSecurityGroupNotCompliantForAzureBastionSubnet` when deploying Azure Bastion by updating the rules in the network security group attached to Bastion's subnet
- For variables `admin_password` and `other_accounts_password`, fixed the auto-generated password that may not be valid ([issue terraform-provider-random #337](https://github.com/hashicorp/terraform-provider-random/issues/337))

## [2.1.0] - 22-10-18

### Added

- Added variable `add_public_ip_address`
- Added examples

## [2.0.0] - 22-10-04

### Fixed

- Link to DSC extension of FE VM was not correct

### Added

- Added 6 variables to allow custom values on the size and storage account type of the virtual machines
- Added variable `enable_hybrid_benefit_server_licenses`

### Changed

- Now, only variable `resource_group_name` requires to be explicitly set
- Password variables `admin_password` and `other_accounts_password` can now be auto-generated, if they are left empty
- Added a condition in variable `admin_username` to prevent values 'admin' or 'administrator', which are not allowed by Azure
- Added a condition in variable `front_end_servers_count` as value can only be between 0 and 4 included
- Default storage account type of all virtual machines is now standard SSD disks instead of standard HDD (deployment time goes down from 1h30 to 1h)
- Increase timeout of resource azurerm_virtual_machine_extension for SharePoint VM to 120 minutes (necessary when using HDD disks instead of SSD)

## [1.3.0] -  2022-09-30

### Added

- Added variable auto_shutdown_time to configure the auto shutdown of virtual machines

### Fixed

- Make changes to work with the new version of the ARM template / DSC extensions used as reference

### Changed

- Updated variable sharepoint_version to include "Subscription-22H2" and "Subscription-RTM"
- Changed SKU of Public IP addresses to Standard, since Basic SKU will be retired
- Updated internal logic the to accomodate the changes made to the DSC extensions of the ARM template

## [1.2.1] - 2022-08-29

### Fixed

- Added rules that were missing on the network security group for Bastion
- Fixed a typo in the name of Bastion's subnet

## [1.2.0] - 2022-08-26

### Added

- Added possibility to configure Azure Bastion

### Changed

- Moved variables that were used to store configuration to locals
- Increased timeout for DSC extensions of DC and SQL to 45 minutes

## [1.1.0] - 2022-08-25

### Changed

- Added validation on variable sharepoint_version
- Removed variable dns_label_prefix and replaced it variable resource_group_name

## [1.0.0] - 2022-08-25

Initial release
