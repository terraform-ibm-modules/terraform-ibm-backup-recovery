
# IBM Backup and Recovery Service (BRS) Module

[![Incubating (Not yet consumable)](https://img.shields.io/badge/status-Incubating%20(Not%20yet%20consumable)-red)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-backup-recovery?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-backup-recovery/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module provisions an **IBM Backup and Recovery Service (BRS)** instance, a **data source connection**, and generates a **registration token** for agent installation. It supports both creating new resources and referencing existing ones.

Use this module to automate BRS setup in IBM Cloud with Terraform.

<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-backup-recovery](#terraform-ibm-backup-recovery)
* [Examples](./examples)
    * [Basic example](./examples/basic)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-backup-recovery

### Usage

```hcl
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "X.Y.Z"  # Lock into a provider version that satisfies the module constraints
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXX"  # replace with apikey value
  region           = var.region
}

module "brs" {
  source = "terraform-ibm-modules/backup-recovery/ibm"
  version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release

  resource_group_id     = "r134-abc123def456..."
  create_new_instance   = true
  create_new_connection = true
  instance_name         = "my-brs-instance"
  connection_name       = "my-brs-connection"
  region                = "us-south"
  kms_root_key_crn      = "kms_root_key_crn"
}
```

### Required IAM Permissions

You need the following permissions to run this module:

- **Resource group**
  - `Viewer` access on the target resource group
- **Backup and Recovery Service**
  - `Editor` platform access
  - `Manager` service access

---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.85.0, < 2.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_resource_group"></a> [resource_group](#module\_resource_group) | terraform-ibm-modules/resource-group/ibm | 1.2.0 |

### Resources

| Name | Type |
|------|------|
| [ibm_resource_instance.backup_recovery_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_instance) | resource |
| [ibm_backup_recovery_data_source_connection.connection](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/backup_recovery_data_source_connection) | resource |
| [ibm_backup_recovery_connection_registration_token.registration_token](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/backup_recovery_connection_registration_token) | resource |
| [data.ibm_resource_instance.backup_recovery_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/resource_instance) | data source |
| [data.ibm_backup_recovery_data_source_connections.connections](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/backup_recovery_data_source_connections) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_new_instance"></a> [create_new_instance](#input\_create_new_instance) | Set to `true` to create a new BRS instance; `false` to use existing. | `bool` | `true` | no |
| <a name="input_create_new_connection"></a> [create_new_connection](#input\_create_new_connection) | Set to `true` to create a new connection; `false` to use existing. | `bool` | `true` | no |
| <a name="input_instance_name"></a> [instance_name](#input\_instance_name) | Name of the BRS instance. | `string` | n/a | yes |
| <a name="input_connection_name"></a> [connection_name](#input\_connection_name) | Name of the data source connection. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | IBM Cloud region for the BRS instance. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource_group_id](#input\_resource_group_id) | ID of the resource group. | `string` | n/a | yes |
| <a name="input_kms_root_key_crn"></a> [kms_root_key_crn](#input\_kms_root_key_crn) | CRN of the KMS root key. | `string` | n/a | no |
| <a name="input_plan"></a> [plan](#input\_plan) | BRS plan (e.g., `premium`). | `string` | `"premium"` | no |
| <a name="input_endpoint_type"></a> [endpoint_type](#input\_endpoint_type) | Backup and Recovery service endpoint type to use for creating a data source connection: `public` or `private`. | `string` | `"public"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_brs_instance_guid"></a> [brs_instance_guid](#output\_brs_instance_guid) | GUID of the BRS instance. |
| <a name="output_tenant_id"></a> [tenant_id](#output\_tenant_id) | Tenant ID with trailing slash (e.g., `abc123/`), used in API calls. |
| <a name="output_connection_id"></a> [connection_id](#output\_connection_id) | ID of the data source connection. |
| <a name="output_registration_token"></a> [registration_token](#output\_registration_token) | **Sensitive** token to register backup agent (expires in 24h). |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

---

## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
