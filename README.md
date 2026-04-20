# IBM Backup and Recovery Service (BRS) Module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-backup-recovery?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-backup-recovery/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-623CE4?logo=terraform)](https://registry.terraform.io/modules/terraform-ibm-modules/backup-recovery/ibm/latest)

This module provisions an **IBM Backup and Recovery Service (BRS)** instance, a **data source connection**, and generates a **registration token** for agent installation. It supports both creating new resources and referencing existing ones.

Use this module to automate BRS setup in IBM Cloud with Terraform.

<!-- BEGIN OVERVIEW HOOK -->
## Overview
<ul>
  <li><a href="#terraform-ibm-backup-recovery">terraform-ibm-backup-recovery</a></li>
  <li><a href="./examples">Examples</a>
    <ul>
      <li>
        <a href="./examples/basic">Basic example</a>
        <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=backup-recovery-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-backup-recovery/tree/main/examples/basic"><img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom; margin-left: 5px;"></a>
      </li>
      <li>
        <a href="./examples/existing-brs">existing-brs example</a>
        <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=backup-recovery-existing-brs-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-backup-recovery/tree/main/examples/existing-brs"><img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom; margin-left: 5px;"></a>
      </li>
    </ul>
    ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
  </li>
  <li><a href="#contributing">Contributing</a></li>
</ul>
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

locals {
    region = "us-south"
}

provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXX"  # replace with apikey value # pragma: allowlist secret
  region           = local.region
}

module "module_template" {
  source            = "terraform-ibm-modules/backup-recovery/ibm"
  version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  region            = local.region
  resource_group_id = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX" # Replace with the actual ID of resource group to use
  ibmcloud_api_key  = "XXXXXXXXXX" # replace with apikey value # pragma: allowlist secret
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
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.88.3, < 3.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.13.1, < 1.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_crn_parser"></a> [crn\_parser](#module\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.5.0 |

### Resources

| Name | Type |
|------|------|
| [ibm_backup_recovery_connection_registration_token.registration_token](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/backup_recovery_connection_registration_token) | resource |
| [ibm_backup_recovery_data_source_connection.connection](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/backup_recovery_data_source_connection) | resource |
| [ibm_backup_recovery_protection_policy.protection_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/backup_recovery_protection_policy) | resource |
| [ibm_resource_instance.backup_recovery_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_instance) | resource |
| [ibm_resource_tag.backup_recovery_access_tag](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_tag) | resource |
| [terraform_data.delete_policies](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.install_dependencies](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.token_rotation_trigger](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_rotating.token_rotation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |
| [ibm_backup_recovery_data_source_connections.connections](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/backup_recovery_data_source_connections) | data source |
| [ibm_backup_recovery_protection_policies.existing_policies](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/backup_recovery_protection_policies) | data source |
| [ibm_iam_access_tag.access_tag](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/iam_access_tag) | data source |
| [ibm_resource_instance.backup_recovery_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/resource_instance) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | Add existing access management tags to the Backup Recovery instance to manage access. Before you can attach your access management tags, you must create them first. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#create-access-console). | `list(string)` | `[]` | no |
| <a name="input_connection_env_type"></a> [connection\_env\_type](#input\_connection\_env\_type) | Type of the data source connection. Set to `null` for VPC and VMware data source connections. Required for IKS/ROKS cluster connections — allowed values are: 'kIksVpc', 'kIksClassic', 'kRoksVpc', 'kRoksClassic'. | `string` | `null` | no |
| <a name="input_connection_name"></a> [connection\_name](#input\_connection\_name) | Name of the data source connection. If `create_new_connection` is `true` (default), a new connection with this name will be created. If `false`, an existing connection with this name must exist. | `string` | `"brs-connection"` | no |
| <a name="input_create_new_connection"></a> [create\_new\_connection](#input\_create\_new\_connection) | Whether to create a new data source connection. If set to true (default), a new connection is established using `connection_name`. If set to false, the system searches for and uses an existing connection that matches `connection_name`. | `bool` | `true` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | The endpoint type to use when connecting to the Backup and Recovery service for creating a data source connection. Allowed values are 'public' or 'private'. | `string` | `"public"` | no |
| <a name="input_existing_brs_instance_crn"></a> [existing\_brs\_instance\_crn](#input\_existing\_brs\_instance\_crn) | The CRN of the existing Backup & Recovery Service instance. If not provided, a new instance will be created. | `string` | `null` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud platform API key needed to deploy IAM enabled resources. | `string` | n/a | yes |
| <a name="input_install_required_binaries"></a> [install\_required\_binaries](#input\_install\_required\_binaries) | When enabled, a script will run during resource destroy to ensure `jq` is available and if not attempt to download it from the public internet and install it to /tmp. Set to false to skip this step. | `bool` | `true` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the Backup & Recovery Service instance. | `string` | `"brs-instance"` | no |
| <a name="input_parameters_json"></a> [parameters\_json](#input\_parameters\_json) | Arbitrary parameters as a JSON string to configure the Backup Recovery Service instance. Currently supported keys are `custom-prov-code` (for development purposes only) and `kms-root-key-crn` (to encrypt the BRS instance with a customer-managed encryption key). | `string` | `null` | no |
| <a name="input_plan"></a> [plan](#input\_plan) | The plan type for the Backup and Recovery service. Currently, only the premium plan is available. | `string` | `"premium"` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | A list of protection policies to create or look up. Set `create_new_policy` to `true` (default) to create a new policy with the specified `schedule` and `retention`. Set `create_new_policy` to `false` to reference an existing policy by `name`. | <pre>list(object({<br/>    name                      = string<br/>    create_new_policy         = optional(bool, true)<br/>    use_default_backup_target = optional(bool, true)<br/><br/>    # --- primary_backup_target advanced details ---<br/>    primary_backup_target_details = optional(object({<br/>      target_id = number<br/>      tier_settings = optional(list(object({<br/>        cloud_platform = string # AWS, Azure, Google, Oracle<br/>        aws_tiering = optional(object({<br/>          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))<br/>        }))<br/>        azure_tiering = optional(object({<br/>          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))<br/>        }))<br/>        google_tiering = optional(object({<br/>          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))<br/>        }))<br/>        oracle_tiering = optional(object({<br/>          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))<br/>        }))<br/>      })))<br/>    }))<br/><br/>    # --- Standard backup schedule and retention ---<br/>    schedule = optional(object({<br/>      unit            = string<br/>      minute_schedule = optional(object({ frequency = number }))<br/>      hour_schedule   = optional(object({ frequency = number }))<br/>      day_schedule    = optional(object({ frequency = number }))<br/>      week_schedule   = optional(object({ day_of_week = list(string) }))<br/>      month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))<br/>      year_schedule   = optional(object({ day_of_year = string }))<br/>    }))<br/>    retention = optional(object({<br/>      duration         = number<br/>      unit             = string<br/>      data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>    }))<br/><br/>    # --- Bare Metal Recovery (BMR) ---<br/>    bmr = optional(object({<br/>      schedule = optional(object({<br/>        unit            = string<br/>        minute_schedule = optional(object({ frequency = number }))<br/>        hour_schedule   = optional(object({ frequency = number }))<br/>        day_schedule    = optional(object({ frequency = number }))<br/>        week_schedule   = optional(object({ day_of_week = list(string) }))<br/>        month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))<br/>        year_schedule   = optional(object({ day_of_year = string }))<br/>      }))<br/>      retention = object({<br/>        duration         = number<br/>        unit             = string<br/>        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>      })<br/>    }))<br/><br/>    # --- Continuous Data Protection (CDP) ---<br/>    cdp = optional(object({<br/>      retention = object({<br/>        duration         = number<br/>        unit             = string<br/>        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>      })<br/>    }))<br/><br/>    # --- Database Log Backup ---<br/>    log = optional(object({<br/>      schedule = object({<br/>        unit            = string<br/>        minute_schedule = optional(object({ frequency = number }))<br/>        hour_schedule   = optional(object({ frequency = number }))<br/>        day_schedule    = optional(object({ frequency = number }))<br/>        week_schedule   = optional(object({ day_of_week = list(string) }))<br/>        month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))<br/>        year_schedule   = optional(object({ day_of_year = string }))<br/>      })<br/>      retention = object({<br/>        duration         = number<br/>        unit             = string<br/>        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>      })<br/>    }))<br/><br/>    # --- Storage Array Snapshot ---<br/>    storage_array_snapshot = optional(object({<br/>      schedule = object({<br/>        unit            = string<br/>        minute_schedule = optional(object({ frequency = number }))<br/>        hour_schedule   = optional(object({ frequency = number }))<br/>        day_schedule    = optional(object({ frequency = number }))<br/>        week_schedule   = optional(object({ day_of_week = list(string) }))<br/>        month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))<br/>        year_schedule   = optional(object({ day_of_year = string }))<br/>      })<br/>      retention = object({<br/>        duration         = number<br/>        unit             = string<br/>        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>      })<br/>    }))<br/><br/>    # --- Blackout windows ---<br/>    blackout_window = optional(list(object({<br/>      day = string<br/>      start_time = object({<br/>        hour      = number<br/>        minute    = number<br/>        time_zone = optional(string, "America/New_York")<br/>      })<br/>      end_time = object({<br/>        hour      = number<br/>        minute    = number<br/>        time_zone = optional(string, "America/New_York")<br/>      })<br/>    })))<br/><br/>    # --- Run timeouts (prevent hung backup jobs) ---<br/>    run_timeouts = optional(list(object({<br/>      timeout_mins = number<br/>      backup_type  = optional(string, "kRegular")<br/>    })))<br/><br/>    # --- Extended retention (keep certain snapshots longer) ---<br/>    extended_retention = optional(list(object({<br/>      schedule = object({<br/>        unit      = string<br/>        frequency = number<br/>      })<br/>      retention = object({<br/>        duration = number<br/>        unit     = string<br/>        data_lock_config = optional(object({<br/>          mode                           = string<br/>          unit                           = string<br/>          duration                       = number<br/>          enable_worm_on_external_target = optional(bool, false)<br/>        }))<br/>      })<br/>      run_type  = optional(string, "Regular")<br/>      config_id = optional(string)<br/>    })))<br/><br/>    # --- Cascaded Targets Config ---<br/>    cascaded_targets_config = optional(object({<br/>      source_cluster_id = number<br/>      remote_targets = list(object({<br/>        archival_targets = optional(list(object({<br/>          target_id           = number<br/>          backup_run_type     = optional(string)<br/>          config_id           = optional(string)<br/>          copy_on_run_success = optional(bool)<br/>          schedule = object({<br/>            unit      = string<br/>            frequency = optional(number)<br/>          })<br/>          retention = object({<br/>            duration         = number<br/>            unit             = string<br/>            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>          })<br/>          extended_retention = optional(list(object({<br/>            schedule = object({<br/>              unit      = string<br/>              frequency = number<br/>            })<br/>            retention = object({<br/>              duration         = number<br/>              unit             = string<br/>              data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>            })<br/>            run_type  = optional(string, "Regular")<br/>            config_id = optional(string)<br/>          })))<br/>        })))<br/>        cloud_spin_targets = optional(list(object({<br/>          target = object({<br/>            id = optional(number)<br/>          })<br/>          backup_run_type     = optional(string)<br/>          config_id           = optional(string)<br/>          copy_on_run_success = optional(bool)<br/>          schedule = object({<br/>            unit      = string<br/>            frequency = optional(number)<br/>          })<br/>          retention = object({<br/>            duration         = number<br/>            unit             = string<br/>            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>          })<br/>          log_retention = optional(object({<br/>            duration         = number<br/>            unit             = string<br/>            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>          }))<br/>          run_timeouts = optional(list(object({<br/>            timeout_mins = optional(number)<br/>            backup_type  = optional(string)<br/>          })))<br/>        })))<br/>        replication_targets = optional(list(object({<br/>          target_type         = string<br/>          backup_run_type     = optional(string)<br/>          config_id           = optional(string)<br/>          copy_on_run_success = optional(bool)<br/>          schedule = object({<br/>            unit      = string<br/>            frequency = optional(number)<br/>          })<br/>          retention = object({<br/>            duration         = number<br/>            unit             = string<br/>            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>          })<br/>          log_retention = optional(object({<br/>            duration         = number<br/>            unit             = string<br/>            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))<br/>          }))<br/>          run_timeouts = optional(list(object({<br/>            timeout_mins = optional(number)<br/>            backup_type  = optional(string)<br/>          })))<br/>          aws_target_config = optional(object({<br/>            region    = number<br/>            source_id = number<br/>          }))<br/>          azure_target_config = optional(object({<br/>            resource_group = optional(number)<br/>            source_id      = number<br/>          }))<br/>          remote_target_config = optional(object({<br/>            cluster_id = number<br/>          }))<br/>        })))<br/>      }))<br/>    }))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "basic-policy",<br/>    "retention": {<br/>      "duration": 2,<br/>      "unit": "Days"<br/>    },<br/>    "schedule": {<br/>      "day_schedule": {<br/>        "frequency": 1<br/>      },<br/>      "unit": "Days"<br/>    }<br/>  }<br/>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | IBM Cloud region where the instance is located or will be created. | `string` | `"us-east"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource group ID where the BRS instance exists or will be created. | `string` | n/a | yes |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | Add user resource tags to the Backup Recovery instance to organize, track, and manage costs. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#tag-types). | `list(string)` | `[]` | no |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | Types of service endpoints to enable for the Backup Recovery instance. Allowed values: 'public', 'private', 'public-and-private'. This controls which network endpoints are available for accessing the service. | `string` | `"public"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_brs_instance"></a> [brs\_instance](#output\_brs\_instance) | Details of the BRS instance. |
| <a name="output_brs_instance_crn"></a> [brs\_instance\_crn](#output\_brs\_instance\_crn) | CRN of the BRS instance. |
| <a name="output_brs_instance_dashboard_url"></a> [brs\_instance\_dashboard\_url](#output\_brs\_instance\_dashboard\_url) | Cluster endpoint URL for the BRS instance. Use this to access the service console. |
| <a name="output_brs_instance_guid"></a> [brs\_instance\_guid](#output\_brs\_instance\_guid) | GUID of the BRS instance. |
| <a name="output_brs_instance_state"></a> [brs\_instance\_state](#output\_brs\_instance\_state) | Current state of the BRS instance. For example, if the instance is deleted, it will return 'removed'. |
| <a name="output_brs_instance_status"></a> [brs\_instance\_status](#output\_brs\_instance\_status) | Current status of the BRS instance (e.g., active, provisioning, failed). |
| <a name="output_connection_id"></a> [connection\_id](#output\_connection\_id) | Unique ID of the data source connection. Used to identify the connection in BRS for agent registration and management. |
| <a name="output_connection_name"></a> [connection\_name](#output\_connection\_name) | Name of the data source connection. |
| <a name="output_protection_policy_ids"></a> [protection\_policy\_ids](#output\_protection\_policy\_ids) | Map of newly created protection policy names to their IDs (does not include pre-existing policies). |
| <a name="output_registration_token"></a> [registration\_token](#output\_registration\_token) | Registration token used to enroll data source connectors with the BRS connection. Expires in 24 hours. Must be kept secure. |
| <a name="output_resolved_policy_ids"></a> [resolved\_policy\_ids](#output\_resolved\_policy\_ids) | Map of all policy names (both created and looked up) to their IDs. |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | BRS tenant ID in the format `<tenant-guid>/`. Required for API calls and agent configuration. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

---

## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
