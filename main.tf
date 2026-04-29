
locals {
  # Determine whether to create new resources or use existing ones
  create_new_instance                  = var.existing_brs_instance_crn == null || var.existing_brs_instance_crn == ""
  brs_instance_guid                    = local.create_new_instance ? null : module.crn_parser[0].service_instance
  brs_instance_region                  = local.create_new_instance ? var.region : module.crn_parser[0].region
  backup_recovery_instance             = local.create_new_instance ? ibm_resource_instance.backup_recovery_instance[0] : data.ibm_resource_instance.backup_recovery_instance[0]
  backup_recovery_connection           = var.connection_name == null ? null : (var.create_new_connection ? ibm_backup_recovery_data_source_connection.connection[0] : data.ibm_backup_recovery_data_source_connections.connections[0].connections[0])
  tenant_id                            = "${local.backup_recovery_instance.extensions.tenant-id}/"
  backup_recovery_instance_public_url  = local.backup_recovery_instance.extensions["endpoints.public"]
  backup_recovery_instance_private_url = local.backup_recovery_instance.extensions["endpoints.private"]
  binaries_path                        = "/tmp"
}

module "crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.5.0"
  count   = local.create_new_instance ? 0 : 1
  crn     = var.existing_brs_instance_crn
}

resource "terraform_data" "install_dependencies" {
  depends_on = [
    terraform_data.delete_policies
  ]
  count = (var.install_required_binaries && local.create_new_instance) ? 1 : 0
  input = {
    binaries_path = local.binaries_path
  }
  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/scripts/install-binaries.sh ${self.input.binaries_path}"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "ibm_resource_instance" "backup_recovery_instance" {
  count             = local.create_new_instance ? 1 : 0
  name              = var.instance_name
  service           = "backup-recovery"
  plan              = var.plan
  location          = local.brs_instance_region
  resource_group_id = var.resource_group_id
  tags              = var.resource_tags
  parameters_json   = var.parameters_json
  service_endpoints = var.service_endpoints
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

data "ibm_iam_access_tag" "access_tag" {
  for_each = local.create_new_instance && length(var.access_tags) != 0 ? toset(var.access_tags) : []
  name     = each.value
}

resource "ibm_resource_tag" "backup_recovery_access_tag" {
  depends_on  = [data.ibm_iam_access_tag.access_tag]
  count       = local.create_new_instance && length(var.access_tags) > 0 ? 1 : 0
  resource_id = ibm_resource_instance.backup_recovery_instance[0].crn
  tags        = var.access_tags
  tag_type    = "access"
}

# When an instance is created, it comes with a few default policies. If these policies are not deleted before
# attempting to delete the instance, the deletion will fail. This is the expected default behavior — even when
# an instance is created through the UI, it cannot be deleted until its associated policies are removed first.
resource "terraform_data" "delete_policies" {
  count = local.create_new_instance ? 1 : 0

  input = {
    url           = var.endpoint_type == "public" ? local.backup_recovery_instance_public_url : local.backup_recovery_instance_private_url
    tenant        = local.tenant_id
    endpoint_type = var.endpoint_type
    binaries_path = local.binaries_path
  }
  triggers_replace = {
    api_key = var.ibmcloud_api_key
  }
  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/scripts/delete_policies.sh ${self.input.url} ${self.input.tenant} ${self.input.endpoint_type} ${self.input.binaries_path}"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      API_KEY = self.triggers_replace.api_key
    }
  }
}

# Data source to retrieve the existing instance details if create_new_instance is false.
# This is used when a BRS instance CRN is provided.
data "ibm_resource_instance" "backup_recovery_instance" {
  count      = local.create_new_instance ? 0 : 1
  identifier = local.brs_instance_guid
}

# data_source_connection
data "ibm_backup_recovery_data_source_connections" "connections" {
  count            = var.connection_name != null && !var.create_new_connection ? 1 : 0
  x_ibm_tenant_id  = local.tenant_id
  connection_names = [var.connection_name]
  endpoint_type    = var.endpoint_type
  instance_id      = local.backup_recovery_instance.guid
  region           = local.brs_instance_region
}

resource "ibm_backup_recovery_data_source_connection" "connection" {
  count               = var.connection_name != null && var.create_new_connection ? 1 : 0
  x_ibm_tenant_id     = local.tenant_id
  connection_name     = var.connection_name
  endpoint_type       = var.endpoint_type
  instance_id         = local.backup_recovery_instance.guid
  region              = local.brs_instance_region
  connection_env_type = var.connection_env_type
}

resource "time_rotating" "token_rotation" {
  count         = var.connection_name != null ? 1 : 0
  rotation_days = 1
}

# This terraform_data resource acts as a rotation trigger. When time_rotating
# rotates, this resource is replaced, which in turn forces the registration
# token to be recreated via replace_triggered_by. This two-stage approach
# avoids hitting the provider's CustomizeDiff that blocks updates on the
# ibm_backup_recovery_connection_registration_token resource.
resource "terraform_data" "token_rotation_trigger" {
  count = var.connection_name != null ? 1 : 0

  triggers_replace = {
    rotation = time_rotating.token_rotation[0].rotation_rfc3339
  }
}

resource "ibm_backup_recovery_connection_registration_token" "registration_token" {
  count           = var.connection_name != null ? 1 : 0
  connection_id   = local.backup_recovery_connection.connection_id
  x_ibm_tenant_id = local.tenant_id
  endpoint_type   = var.endpoint_type
  instance_id     = local.backup_recovery_instance.guid
  region          = local.brs_instance_region

  lifecycle {
    replace_triggered_by = [
      terraform_data.token_rotation_trigger[0]
    ]
  }
}

##############################################################################
# Protection Policy
##############################################################################

locals {
  # Explicitly filter based on the new boolean flag
  policies_to_create = { for p in var.policies : p.name => p if p.create_new_policy }
  policies_to_lookup = { for p in var.policies : p.name => p if !p.create_new_policy }

  resolved_policy_ids = merge(
    { for k, v in ibm_backup_recovery_protection_policy.protection_policy : k => replace(v.id, "${local.tenant_id}::", "") },
    { for k, v in data.ibm_backup_recovery_protection_policies.existing_policies : k => one(v.policies[*].id) if length(v.policies) > 0 }
  )
}

data "ibm_backup_recovery_protection_policies" "existing_policies" {
  for_each = local.policies_to_lookup

  x_ibm_tenant_id = local.tenant_id
  instance_id     = local.backup_recovery_instance.guid
  region          = local.brs_instance_region
  endpoint_type   = var.endpoint_type
  policy_names    = [each.key]
}

resource "ibm_backup_recovery_protection_policy" "protection_policy" {
  for_each = local.policies_to_create

  x_ibm_tenant_id = local.tenant_id
  name            = each.key
  endpoint_type   = var.endpoint_type
  instance_id     = local.backup_recovery_instance.guid
  region          = local.brs_instance_region

  backup_policy {
    dynamic "bmr" {
      for_each = each.value.bmr != null ? [each.value.bmr] : []
      content {
        schedule {
          unit = bmr.value.schedule.unit
          dynamic "day_schedule" {
            for_each = bmr.value.schedule.day_schedule != null ? [bmr.value.schedule.day_schedule] : []
            content { frequency = day_schedule.value.frequency }
          }
          dynamic "week_schedule" {
            for_each = bmr.value.schedule.week_schedule != null ? [bmr.value.schedule.week_schedule] : []
            content { day_of_week = week_schedule.value.day_of_week }
          }
          dynamic "month_schedule" {
            for_each = bmr.value.schedule.month_schedule != null ? [bmr.value.schedule.month_schedule] : []
            content {
              day_of_month  = try(month_schedule.value.day_of_month, null)
              day_of_week   = try(month_schedule.value.day_of_week, null)
              week_of_month = try(month_schedule.value.week_of_month, null)
            }
          }
          dynamic "year_schedule" {
            for_each = bmr.value.schedule.year_schedule != null ? [bmr.value.schedule.year_schedule] : []
            content { day_of_year = year_schedule.value.day_of_year }
          }
        }
        retention {
          duration = bmr.value.retention.duration
          unit     = bmr.value.retention.unit
          dynamic "data_lock_config" {
            for_each = bmr.value.retention.data_lock_config != null ? [bmr.value.retention.data_lock_config] : []
            content {
              mode                           = data_lock_config.value.mode
              unit                           = data_lock_config.value.unit
              duration                       = data_lock_config.value.duration
              enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
            }
          }
        }
      }
    }

    dynamic "cdp" {
      for_each = each.value.cdp != null ? [each.value.cdp] : []
      content {
        retention {
          duration = cdp.value.retention.duration
          unit     = cdp.value.retention.unit
          dynamic "data_lock_config" {
            for_each = cdp.value.retention.data_lock_config != null ? [cdp.value.retention.data_lock_config] : []
            content {
              mode                           = data_lock_config.value.mode
              unit                           = data_lock_config.value.unit
              duration                       = data_lock_config.value.duration
              enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
            }
          }
        }
      }
    }

    dynamic "log" {
      for_each = each.value.log != null ? [each.value.log] : []
      content {
        schedule {
          unit = log.value.schedule.unit
          dynamic "hour_schedule" {
            for_each = log.value.schedule.hour_schedule != null ? [log.value.schedule.hour_schedule] : []
            content { frequency = hour_schedule.value.frequency }
          }
          dynamic "minute_schedule" {
            for_each = log.value.schedule.minute_schedule != null ? [log.value.schedule.minute_schedule] : []
            content { frequency = minute_schedule.value.frequency }
          }
        }
        retention {
          duration = log.value.retention.duration
          unit     = log.value.retention.unit
          dynamic "data_lock_config" {
            for_each = log.value.retention.data_lock_config != null ? [log.value.retention.data_lock_config] : []
            content {
              mode                           = data_lock_config.value.mode
              unit                           = data_lock_config.value.unit
              duration                       = data_lock_config.value.duration
              enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
            }
          }
        }
      }
    }

    dynamic "storage_array_snapshot" {
      for_each = each.value.storage_array_snapshot != null ? [each.value.storage_array_snapshot] : []
      content {
        schedule {
          unit = storage_array_snapshot.value.schedule.unit
          dynamic "minute_schedule" {
            for_each = storage_array_snapshot.value.schedule.minute_schedule != null ? [storage_array_snapshot.value.schedule.minute_schedule] : []
            content { frequency = minute_schedule.value.frequency }
          }
          dynamic "hour_schedule" {
            for_each = storage_array_snapshot.value.schedule.hour_schedule != null ? [storage_array_snapshot.value.schedule.hour_schedule] : []
            content { frequency = hour_schedule.value.frequency }
          }
          dynamic "day_schedule" {
            for_each = storage_array_snapshot.value.schedule.day_schedule != null ? [storage_array_snapshot.value.schedule.day_schedule] : []
            content { frequency = day_schedule.value.frequency }
          }
          dynamic "week_schedule" {
            for_each = storage_array_snapshot.value.schedule.week_schedule != null ? [storage_array_snapshot.value.schedule.week_schedule] : []
            content { day_of_week = week_schedule.value.day_of_week }
          }
          dynamic "month_schedule" {
            for_each = storage_array_snapshot.value.schedule.month_schedule != null ? [storage_array_snapshot.value.schedule.month_schedule] : []
            content {
              day_of_month  = try(month_schedule.value.day_of_month, null)
              day_of_week   = try(month_schedule.value.day_of_week, null)
              week_of_month = try(month_schedule.value.week_of_month, null)
            }
          }
          dynamic "year_schedule" {
            for_each = storage_array_snapshot.value.schedule.year_schedule != null ? [storage_array_snapshot.value.schedule.year_schedule] : []
            content { day_of_year = year_schedule.value.day_of_year }
          }
        }
        retention {
          duration = storage_array_snapshot.value.retention.duration
          unit     = storage_array_snapshot.value.retention.unit
          dynamic "data_lock_config" {
            for_each = storage_array_snapshot.value.retention.data_lock_config != null ? [storage_array_snapshot.value.retention.data_lock_config] : []
            content {
              mode                           = data_lock_config.value.mode
              unit                           = data_lock_config.value.unit
              duration                       = data_lock_config.value.duration
              enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
            }
          }
        }
      }
    }

    regular {
      incremental {
        schedule {
          unit = each.value.schedule.unit

          dynamic "minute_schedule" {
            for_each = each.value.schedule.minute_schedule != null ? [each.value.schedule.minute_schedule] : []
            content {
              frequency = minute_schedule.value.frequency
            }
          }
          dynamic "hour_schedule" {
            for_each = each.value.schedule.hour_schedule != null ? [each.value.schedule.hour_schedule] : []
            content {
              frequency = hour_schedule.value.frequency
            }
          }
          dynamic "day_schedule" {
            for_each = each.value.schedule.day_schedule != null ? [each.value.schedule.day_schedule] : []
            content {
              frequency = day_schedule.value.frequency
            }
          }
          dynamic "week_schedule" {
            for_each = each.value.schedule.week_schedule != null ? [each.value.schedule.week_schedule] : []
            content {
              day_of_week = week_schedule.value.day_of_week
            }
          }
          dynamic "month_schedule" {
            for_each = each.value.schedule.month_schedule != null ? [each.value.schedule.month_schedule] : []
            content {
              day_of_week   = try(month_schedule.value.day_of_week, null)
              week_of_month = try(month_schedule.value.week_of_month, null)
              day_of_month  = try(month_schedule.value.day_of_month, null)
            }
          }
          dynamic "year_schedule" {
            for_each = each.value.schedule.year_schedule != null ? [each.value.schedule.year_schedule] : []
            content {
              day_of_year = year_schedule.value.day_of_year
            }
          }
        }
      }

      retention {
        duration = each.value.retention.duration
        unit     = each.value.retention.unit

        dynamic "data_lock_config" {
          for_each = each.value.retention.data_lock_config != null ? [each.value.retention.data_lock_config] : []
          content {
            mode                           = data_lock_config.value.mode
            unit                           = data_lock_config.value.unit
            duration                       = data_lock_config.value.duration
            enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
          }
        }
      }

      primary_backup_target {
        use_default_backup_target = each.value.use_default_backup_target

        dynamic "archival_target_settings" {
          for_each = each.value.primary_backup_target_details != null ? [each.value.primary_backup_target_details] : []
          content {
            target_id = archival_target_settings.value.target_id

            dynamic "tier_settings" {
              for_each = archival_target_settings.value.tier_settings != null ? archival_target_settings.value.tier_settings : []
              content {
                cloud_platform = tier_settings.value.cloud_platform

                dynamic "aws_tiering" {
                  for_each = tier_settings.value.aws_tiering != null ? [tier_settings.value.aws_tiering] : []
                  content {
                    dynamic "tiers" {
                      for_each = aws_tiering.value.tiers
                      content {
                        tier_type       = tiers.value.tier_type
                        move_after      = tiers.value.move_after
                        move_after_unit = tiers.value.move_after_unit
                      }
                    }
                  }
                }
                dynamic "azure_tiering" {
                  for_each = tier_settings.value.azure_tiering != null ? [tier_settings.value.azure_tiering] : []
                  content {
                    dynamic "tiers" {
                      for_each = azure_tiering.value.tiers
                      content {
                        tier_type       = tiers.value.tier_type
                        move_after      = tiers.value.move_after
                        move_after_unit = tiers.value.move_after_unit
                      }
                    }
                  }
                }
                dynamic "google_tiering" {
                  for_each = tier_settings.value.google_tiering != null ? [tier_settings.value.google_tiering] : []
                  content {
                    dynamic "tiers" {
                      for_each = google_tiering.value.tiers
                      content {
                        tier_type       = tiers.value.tier_type
                        move_after      = tiers.value.move_after
                        move_after_unit = tiers.value.move_after_unit
                      }
                    }
                  }
                }
                dynamic "oracle_tiering" {
                  for_each = tier_settings.value.oracle_tiering != null ? [tier_settings.value.oracle_tiering] : []
                  content {
                    dynamic "tiers" {
                      for_each = oracle_tiering.value.tiers
                      content {
                        tier_type       = tiers.value.tier_type
                        move_after      = tiers.value.move_after
                        move_after_unit = tiers.value.move_after_unit
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    dynamic "run_timeouts" {
      for_each = each.value.run_timeouts != null ? each.value.run_timeouts : []
      content {
        timeout_mins = run_timeouts.value.timeout_mins
        backup_type  = run_timeouts.value.backup_type
      }
    }
  }

  dynamic "blackout_window" {
    for_each = each.value.blackout_window != null ? each.value.blackout_window : []
    content {
      day = blackout_window.value.day
      start_time {
        hour      = blackout_window.value.start_time.hour
        minute    = blackout_window.value.start_time.minute
        time_zone = blackout_window.value.start_time.time_zone
      }
      end_time {
        hour      = blackout_window.value.end_time.hour
        minute    = blackout_window.value.end_time.minute
        time_zone = blackout_window.value.end_time.time_zone
      }
    }
  }

  dynamic "extended_retention" {
    for_each = each.value.extended_retention != null ? each.value.extended_retention : []
    content {
      schedule {
        unit      = extended_retention.value.schedule.unit
        frequency = extended_retention.value.schedule.frequency
      }
      retention {
        duration = extended_retention.value.retention.duration
        unit     = extended_retention.value.retention.unit

        dynamic "data_lock_config" {
          for_each = extended_retention.value.retention.data_lock_config != null ? [extended_retention.value.retention.data_lock_config] : []
          content {
            mode                           = data_lock_config.value.mode
            unit                           = data_lock_config.value.unit
            duration                       = data_lock_config.value.duration
            enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
          }
        }
      }
      run_type  = extended_retention.value.run_type
      config_id = extended_retention.value.config_id
    }
  }

  dynamic "cascaded_targets_config" {
    for_each = each.value.cascaded_targets_config != null ? [each.value.cascaded_targets_config] : []
    content {
      source_cluster_id = cascaded_targets_config.value.source_cluster_id
      dynamic "remote_targets" {
        for_each = cascaded_targets_config.value.remote_targets
        content {
          dynamic "archival_targets" {
            for_each = remote_targets.value.archival_targets != null ? remote_targets.value.archival_targets : []
            content {
              target_id           = archival_targets.value.target_id
              backup_run_type     = archival_targets.value.backup_run_type
              config_id           = archival_targets.value.config_id
              copy_on_run_success = archival_targets.value.copy_on_run_success
              schedule {
                unit      = archival_targets.value.schedule.unit
                frequency = archival_targets.value.schedule.frequency
              }
              retention {
                duration = archival_targets.value.retention.duration
                unit     = archival_targets.value.retention.unit
                dynamic "data_lock_config" {
                  for_each = archival_targets.value.retention.data_lock_config != null ? [archival_targets.value.retention.data_lock_config] : []
                  content {
                    mode                           = data_lock_config.value.mode
                    unit                           = data_lock_config.value.unit
                    duration                       = data_lock_config.value.duration
                    enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
                  }
                }
              }
              dynamic "extended_retention" {
                for_each = archival_targets.value.extended_retention != null ? archival_targets.value.extended_retention : []
                content {
                  schedule {
                    unit      = extended_retention.value.schedule.unit
                    frequency = extended_retention.value.schedule.frequency
                  }
                  retention {
                    duration = extended_retention.value.retention.duration
                    unit     = extended_retention.value.retention.unit
                    dynamic "data_lock_config" {
                      for_each = extended_retention.value.retention.data_lock_config != null ? [extended_retention.value.retention.data_lock_config] : []
                      content {
                        mode                           = data_lock_config.value.mode
                        unit                           = data_lock_config.value.unit
                        duration                       = data_lock_config.value.duration
                        enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
                      }
                    }
                  }
                  run_type  = extended_retention.value.run_type
                  config_id = extended_retention.value.config_id
                }
              }
            }
          }

          dynamic "cloud_spin_targets" {
            for_each = remote_targets.value.cloud_spin_targets != null ? remote_targets.value.cloud_spin_targets : []
            content {
              dynamic "target" {
                for_each = cloud_spin_targets.value.target != null ? [cloud_spin_targets.value.target] : []
                content {
                  id = target.value.id
                }
              }
              backup_run_type     = cloud_spin_targets.value.backup_run_type
              config_id           = cloud_spin_targets.value.config_id
              copy_on_run_success = cloud_spin_targets.value.copy_on_run_success
              schedule {
                unit      = cloud_spin_targets.value.schedule.unit
                frequency = cloud_spin_targets.value.schedule.frequency
              }
              retention {
                duration = cloud_spin_targets.value.retention.duration
                unit     = cloud_spin_targets.value.retention.unit
                dynamic "data_lock_config" {
                  for_each = cloud_spin_targets.value.retention.data_lock_config != null ? [cloud_spin_targets.value.retention.data_lock_config] : []
                  content {
                    mode                           = data_lock_config.value.mode
                    unit                           = data_lock_config.value.unit
                    duration                       = data_lock_config.value.duration
                    enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
                  }
                }
              }
              dynamic "log_retention" {
                for_each = cloud_spin_targets.value.log_retention != null ? [cloud_spin_targets.value.log_retention] : []
                content {
                  duration = log_retention.value.duration
                  unit     = log_retention.value.unit
                  dynamic "data_lock_config" {
                    for_each = log_retention.value.data_lock_config != null ? [log_retention.value.data_lock_config] : []
                    content {
                      mode                           = data_lock_config.value.mode
                      unit                           = data_lock_config.value.unit
                      duration                       = data_lock_config.value.duration
                      enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
                    }
                  }
                }
              }
              dynamic "run_timeouts" {
                for_each = cloud_spin_targets.value.run_timeouts != null ? cloud_spin_targets.value.run_timeouts : []
                content {
                  timeout_mins = run_timeouts.value.timeout_mins
                  backup_type  = run_timeouts.value.backup_type
                }
              }
            }
          }

          dynamic "replication_targets" {
            for_each = remote_targets.value.replication_targets != null ? remote_targets.value.replication_targets : []
            content {
              target_type         = replication_targets.value.target_type
              backup_run_type     = replication_targets.value.backup_run_type
              config_id           = replication_targets.value.config_id
              copy_on_run_success = replication_targets.value.copy_on_run_success
              schedule {
                unit      = replication_targets.value.schedule.unit
                frequency = replication_targets.value.schedule.frequency
              }
              retention {
                duration = replication_targets.value.retention.duration
                unit     = replication_targets.value.retention.unit
                dynamic "data_lock_config" {
                  for_each = replication_targets.value.retention.data_lock_config != null ? [replication_targets.value.retention.data_lock_config] : []
                  content {
                    mode                           = data_lock_config.value.mode
                    unit                           = data_lock_config.value.unit
                    duration                       = data_lock_config.value.duration
                    enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
                  }
                }
              }
              dynamic "log_retention" {
                for_each = replication_targets.value.log_retention != null ? [replication_targets.value.log_retention] : []
                content {
                  duration = log_retention.value.duration
                  unit     = log_retention.value.unit
                  dynamic "data_lock_config" {
                    for_each = log_retention.value.data_lock_config != null ? [log_retention.value.data_lock_config] : []
                    content {
                      mode                           = data_lock_config.value.mode
                      unit                           = data_lock_config.value.unit
                      duration                       = data_lock_config.value.duration
                      enable_worm_on_external_target = data_lock_config.value.enable_worm_on_external_target
                    }
                  }
                }
              }
              dynamic "run_timeouts" {
                for_each = replication_targets.value.run_timeouts != null ? replication_targets.value.run_timeouts : []
                content {
                  timeout_mins = run_timeouts.value.timeout_mins
                  backup_type  = run_timeouts.value.backup_type
                }
              }
              dynamic "aws_target_config" {
                for_each = replication_targets.value.aws_target_config != null ? [replication_targets.value.aws_target_config] : []
                content {
                  region    = aws_target_config.value.region
                  source_id = aws_target_config.value.source_id
                }
              }
              dynamic "azure_target_config" {
                for_each = replication_targets.value.azure_target_config != null ? [replication_targets.value.azure_target_config] : []
                content {
                  resource_group = azure_target_config.value.resource_group
                  source_id      = azure_target_config.value.source_id
                }
              }
              dynamic "remote_target_config" {
                for_each = replication_targets.value.remote_target_config != null ? [replication_targets.value.remote_target_config] : []
                content {
                  cluster_id = remote_target_config.value.cluster_id
                }
              }
            }
          }
        }
      }
    }
  }

  retry_options {
    retries             = 3
    retry_interval_mins = 5
  }
}
