# Changelog for terraform-azurerm-sharepoint

> ~~This CHANGELOG covers only the changes related to this Terraform module.~~  
> As the changes in virtual machines configuration are significant each time, starting with `3.2.0` I decided to include all the changes in this CHANGELOG.  
The DSC files (virtual machines configuration) are copied from [this Azure template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/).

## [3.12.1] - Unreleased

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
- For variables `admin_password` and `service_accounts_password`, fixed the auto-generated password that may not be valid ([issue terraform-provider-random #337](https://github.com/hashicorp/terraform-provider-random/issues/337))

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
- Password variables `admin_password` and `service_accounts_password` can now be auto-generated, if they are left empty
- Added a condition in variable `admin_username` to prevent values 'admin' or 'administrator', which are not allowed by Azure
- Added a condition in variable `number_additional_frontend` as value can only be between 0 and 4 included
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
