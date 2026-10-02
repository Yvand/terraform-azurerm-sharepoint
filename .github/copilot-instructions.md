# Repository instructions

## Build, test, and validation

This repository is a Terraform module; it has no separate build or lint runner, and no `.tftest.hcl` test files are currently checked in.

- Format check: `terraform fmt -check -recursive`
- Initialize locally without configuring a backend: `terraform init -backend=false`
- Validate configuration after initialization: `terraform validate`
- Preview a deployment: `terraform plan -var-file=configuration.tfvars -var-file=<local-vars.tfvars>`; supply the required subscription, resource group, and credentials, and authenticate to Azure first.
- To run one Terraform test after adding one: `terraform test -filter=tests/unit/<test-name>.tftest.hcl`. Terraform tests can create real infrastructure, so use this only with tests designed for a safe test environment.

The README's deployment flow is `terraform init` followed by `terraform apply`. Applying creates Azure resources and can incur costs; do not apply unless explicitly requested.

## Architecture

The root module in `main.tf` composes the farm from Azure Verified Modules. It creates the resource group, virtual network/subnet and NSG, then deploys domain-controller, SQL, and SharePoint VMs; the front-end VM module is counted from `front_end_servers_count`. Key Vault is optional.

VM provisioning is performed by Azure VM DSC extensions in `main.tf`. The extensions download role-specific archives from the `_artifactsLocation` variable (published by SharePointInfraDsc), pass deployment settings and SharePoint package metadata to DSC, and send credentials in protected settings. The SharePoint version selects both a marketplace image and a package entry; configuration level/custom feature inputs are passed to DSC. Keep these Terraform-to-DSC arguments consistent with the external DSC configuration.

`outbound_access_method` selects public-IP egress or conditional Azure Firewall explicit-proxy resources. The network and VM modules share local settings, tags, and naming-module outputs; preserve those relationships when changing resource wiring.

## Repository conventions

- Input contracts and validations live in `variables.tf`; exported values live in `outputs.tf`; Terraform/provider requirements live in `versions.tf`; resource composition and locals are in `main.tf`.
- Azure resources are generally provisioned through Azure Verified Modules. Module `version` attributes in `main.tf` are exact pins; provider constraints in `versions.tf` use pessimistic constraints, and `.terraform.lock.hcl` records provider selections. Keep repeated references to a module source on the same version.
- `configuration.tfvars` is tracked deployment configuration, not a disposable local override. Preserve its intentional settings and comments. Keep private credentials and machine-specific values in a separate untracked tfvars file; Terraform state and outputs can contain sensitive deployment values.
- The two focused agents in `.github/agents/` own separate update paths: `sharepoint-update-syncer` updates only the `"SPLatest"` download URL in `main.tf`; `terraform-dependency-updater` updates module pins and provider constraints. Keep these changes separate and follow the relevant agent's validation instructions.
- The examples under `examples/` show consuming this module for public-IP and firewall-proxy egress; keep them aligned when changing those interfaces or defaults.
- For every non-trivial code, configuration, dependency, interface, or user-facing documentation change, add a concise entry under `## Unreleased` in `CHANGELOG.md` in the same change. Skip pure formatting and changelog-only edits; do not invent release versions or dates.
