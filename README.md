
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
  ibmcloud_api_key = "XXXXXXXXXXXXXX"  # replace with apikey value
  region           = var.region
}

module "brs" {
  source            = "terraform-ibm-modules/backup-recovery/ibm"
  version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX"
  region            = var.region
  ibmcloud_api_key  = "XXXXXXXXXXXXXX" # replace with apikey value
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

No modules.

### Resources

| Name | Type |
|------|------|
| [ibm_backup_recovery_data_source_connection.connection](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/backup_recovery_data_source_connection) | resource |
| [ibm_resource_instance.backup_recovery_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_instance) | resource |
| [terraform_data.delete_policies](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [ibm_backup_recovery_data_source_connections.connections](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/backup_recovery_data_source_connections) | data source |
| [ibm_resource_instance.backup_recovery_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/resource_instance) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connection_name"></a> [connection\_name](#input\_connection\_name) | Name of the data source connection. | `string` | `"brs-connection"` | no |
| <a name="input_create_new_connection"></a> [create\_new\_connection](#input\_create\_new\_connection) | Set to true to create a new data source connection, false to use existing. | `bool` | `true` | no |
| <a name="input_create_new_instance"></a> [create\_new\_instance](#input\_create\_new\_instance) | Set to true to create a new BRS instance, false to use existing one. | `bool` | `true` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | The endpoint type to use when connecting to the Backup and Recovery service for creating a data source connection | `string` | `"public"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud platform API key needed to deploy IAM enabled resources. | `string` | n/a | yes |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the Backup & Recovery Service instance. | `string` | `"brs-instance"` | no |
| <a name="input_kms_key_crn"></a> [kms\_key\_crn](#input\_kms\_key\_crn) | The CRN of the key management service key to encrypt the backup data. | `string` | `null` | no |
| <a name="input_plan"></a> [plan](#input\_plan) | The plan type for the Backup and Recovery service. Currently, only the premium plan is available. | `string` | `"premium"` | no |
| <a name="input_region"></a> [region](#input\_region) | IBM Cloud region where the instance is located or will be created. | `string` | `"us-east"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource group ID where the BRS instance exists or will be created. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Metadata labels describing this backup and recovery service instance, i.e. test | `list(string)` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_brs_instance_guid"></a> [brs\_instance\_guid](#output\_brs\_instance\_guid) | GUID of the BRS instance. |
| <a name="output_connection_id"></a> [connection\_id](#output\_connection\_id) | Unique ID of the data source connection. Used to identify the connection in BRS for agent registration and management. |
| <a name="output_registration_token"></a> [registration\_token](#output\_registration\_token) | Registration token used to enroll data source connectors with the BRS connection. Expires in 24 hours. Must be kept secure. |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | BRS tenant ID in the format `<tenant-guid>/`. Required for API calls and agent configuration. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

---

## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
