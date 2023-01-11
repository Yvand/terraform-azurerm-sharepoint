# Changelog for terraform-azurerm-sharepoint

> This CHANGELOG covers only the changes related to this Terraform module.  
The DSC files are copied from [this Azure template](https://azure.microsoft.com/en-us/resources/templates/sharepoint-adfs/) and you can consult it to see the changes specific to DSC.

## [3.1.0] - 23-01-11

* Use a small disk (32 GB) on SharePoint Subscription and SharePoint 2019 VMs.
* Updated SQL image to use SQL Server 2022 on Windows Server 2022.
* The resource group's name is used in the virtual network and the public IP resources, but now it is formatted to handle the restrictions on the characters allowed.
* Apply browser policies for Edge and Chrome to get rid of noisy wizards / homepages / new tab content.
* Reorganize the local variables in the module to be more consistent.

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
