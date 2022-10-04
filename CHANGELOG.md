# Changelog for terraform-azurerm-sharepoint

## [2.0.0] -  Unreleased

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
