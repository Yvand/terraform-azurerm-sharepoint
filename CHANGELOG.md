# Changelog for terraform-azurerm-sharepoint


> This CHANGELOG covers only the changes related to this Terraform module.  
The DSC files are copied from [this Azure template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/) and you can consult its repo to see the changes related to DSC.

## Unreleased

### Changed

- Improved the logic that installs SharePoint updates when deploying SharePoint Subscription
- Renamed variable `add_public_ip_address` to `add_public_ip_address` and update its type and design to add more granularity. Now its default value is `SharePointVMsOnly`
- Changed SKU of Public IP address resources to use Basic instead of Standard (except for Bastion which requires Standard)
- Changed allocation method of Public IP address resources to use Dynamic instead of Static (except for Bastion which requires Static)

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
