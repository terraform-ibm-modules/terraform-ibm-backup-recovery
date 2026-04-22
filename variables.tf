###############################
# Instance Configuration
###############################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  sensitive   = true
}

variable "existing_brs_instance_crn" {
  type        = string
  description = "The CRN of the existing Backup & Recovery Service instance. If not provided, a new instance will be created."
  default     = null

  validation {
    condition     = var.existing_brs_instance_crn == null || var.region == element(split(":", var.existing_brs_instance_crn), 5)
    error_message = "The provided 'region' does not match the region derived from 'brs_instance_crn'. Please ensure they match."
  }
}

variable "instance_name" {
  type        = string
  description = "Name of the Backup & Recovery Service instance."
  default     = "brs-instance"
  nullable    = false
}

variable "plan" {
  type        = string
  description = "The plan type for the Backup and Recovery service. Currently, only the premium plan is available."
  default     = "premium"
  validation {
    condition     = contains(["premium"], var.plan)
    error_message = "Invalid plan type for the Backup and Recovery service."
  }
}

variable "resource_tags" {
  type        = list(string)
  description = "Add user resource tags to the Backup Recovery instance to organize, track, and manage costs. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#tag-types)."
  default     = []

  validation {
    condition     = alltrue([for tag in var.resource_tags : can(regex("^[A-Za-z0-9 _\\-.:]{1,128}$", tag))])
    error_message = "Each resource tag must be 128 characters or less and may contain only A-Z, a-z, 0-9, spaces, underscore (_), hyphen (-), period (.), and colon (:)."
  }
}

variable "access_tags" {
  type        = list(string)
  description = "Add existing access management tags to the Backup Recovery instance to manage access. Before you can attach your access management tags, you must create them first. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#create-access-console)."
  default     = []
}

variable "region" {
  type        = string
  description = "IBM Cloud region where the instance is located or will be created."
  default     = "us-east"
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID where the BRS instance exists or will be created."
}
variable "parameters_json" {
  type        = string
  description = "Arbitrary parameters as a JSON string to configure the Backup Recovery Service instance. Currently supported keys are `custom-prov-code` (for development purposes only) and `kms-root-key-crn` (to encrypt the BRS instance with a customer-managed encryption key)."
  default     = null

  validation {
    condition     = var.parameters_json == null || can(jsondecode(var.parameters_json))
    error_message = "parameters_json must be a valid JSON string."
  }
}

variable "service_endpoints" {
  type        = string
  description = "Types of service endpoints to enable for the Backup Recovery instance. Allowed values: 'public', 'private', 'public-and-private'. This controls which network endpoints are available for accessing the service."
  default     = "public"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.service_endpoints)
    error_message = "service_endpoints must be one of: 'public', 'private', 'public-and-private'."
  }
}

###############################
# Connection Configuration
###############################

variable "create_new_connection" {
  type        = bool
  description = "Whether to create a new data source connection. If set to true (default), a new connection is established using `connection_name`. If set to false, the system searches for and uses an existing connection that matches `connection_name`."
  default     = true
}

variable "connection_name" {
  type        = string
  description = "Name of the data source connection. If `create_new_connection` is `true` (default), a new connection with this name will be created. If `false`, an existing connection with this name must exist."
  default     = "brs-connection"
}

variable "connection_env_type" {
  type        = string
  default     = null
  description = "Type of the data source connection. Set to `null` for VPC and VMware data source connections. Required for IKS/ROKS cluster connections — allowed values are: 'kIksVpc', 'kIksClassic', 'kRoksVpc', 'kRoksClassic'."
  validation {
    condition     = var.connection_env_type == null || contains(["kIksVpc", "kIksClassic", "kRoksVpc", "kRoksClassic"], var.connection_env_type)
    error_message = "connection_env_type must be one of: 'kIksVpc', 'kIksClassic', 'kRoksVpc', 'kRoksClassic'."
  }
}

variable "endpoint_type" {
  type        = string
  description = "The endpoint type to use when connecting to the Backup and Recovery service for creating a data source connection. Allowed values are 'public' or 'private'."
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.endpoint_type)
    error_message = "endpoint_type must be 'public' or 'private'."
  }
}

variable "install_required_binaries" {
  type        = bool
  default     = true
  description = "When enabled, a script will run during resource destroy to ensure `jq` is available and if not attempt to download it from the public internet and install it to /tmp. Set to false to skip this step."
  nullable    = false
}

###############################
# Protection Policy
###############################

variable "policies" {
  description = "A list of protection policies to create or look up. Set `create_new_policy` to `true` (default) to create a new policy with the specified `schedule` and `retention`. Set `create_new_policy` to `false` to reference an existing policy by `name`."
  type = list(object({
    name                      = string
    create_new_policy         = optional(bool, true)
    use_default_backup_target = optional(bool, true)

    # --- primary_backup_target advanced details ---
    primary_backup_target_details = optional(object({
      target_id = number
      tier_settings = optional(list(object({
        cloud_platform = string # AWS, Azure, Google, Oracle
        aws_tiering = optional(object({
          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))
        }))
        azure_tiering = optional(object({
          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))
        }))
        google_tiering = optional(object({
          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))
        }))
        oracle_tiering = optional(object({
          tiers = list(object({ tier_type = string, move_after = number, move_after_unit = string }))
        }))
      })))
    }))

    # --- Standard backup schedule and retention ---
    schedule = optional(object({
      unit            = string
      minute_schedule = optional(object({ frequency = number }))
      hour_schedule   = optional(object({ frequency = number }))
      day_schedule    = optional(object({ frequency = number }))
      week_schedule   = optional(object({ day_of_week = list(string) }))
      month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))
      year_schedule   = optional(object({ day_of_year = string }))
    }))
    retention = optional(object({
      duration         = number
      unit             = string
      data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
    }))

    # --- Bare Metal Recovery (BMR) ---
    bmr = optional(object({
      schedule = optional(object({
        unit            = string
        minute_schedule = optional(object({ frequency = number }))
        hour_schedule   = optional(object({ frequency = number }))
        day_schedule    = optional(object({ frequency = number }))
        week_schedule   = optional(object({ day_of_week = list(string) }))
        month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))
        year_schedule   = optional(object({ day_of_year = string }))
      }))
      retention = object({
        duration         = number
        unit             = string
        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
      })
    }))

    # --- Continuous Data Protection (CDP) ---
    cdp = optional(object({
      retention = object({
        duration         = number
        unit             = string
        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
      })
    }))

    # --- Database Log Backup ---
    log = optional(object({
      schedule = object({
        unit            = string
        minute_schedule = optional(object({ frequency = number }))
        hour_schedule   = optional(object({ frequency = number }))
        day_schedule    = optional(object({ frequency = number }))
        week_schedule   = optional(object({ day_of_week = list(string) }))
        month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))
        year_schedule   = optional(object({ day_of_year = string }))
      })
      retention = object({
        duration         = number
        unit             = string
        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
      })
    }))

    # --- Storage Array Snapshot ---
    storage_array_snapshot = optional(object({
      schedule = object({
        unit            = string
        minute_schedule = optional(object({ frequency = number }))
        hour_schedule   = optional(object({ frequency = number }))
        day_schedule    = optional(object({ frequency = number }))
        week_schedule   = optional(object({ day_of_week = list(string) }))
        month_schedule  = optional(object({ day_of_month = optional(number), day_of_week = optional(list(string)), week_of_month = optional(string) }))
        year_schedule   = optional(object({ day_of_year = string }))
      })
      retention = object({
        duration         = number
        unit             = string
        data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
      })
    }))

    # --- Blackout windows ---
    blackout_window = optional(list(object({
      day = string
      start_time = object({
        hour      = number
        minute    = number
        time_zone = optional(string, "America/New_York")
      })
      end_time = object({
        hour      = number
        minute    = number
        time_zone = optional(string, "America/New_York")
      })
    })))

    # --- Run timeouts (prevent hung backup jobs) ---
    run_timeouts = optional(list(object({
      timeout_mins = number
      backup_type  = optional(string, "kRegular")
    })))

    # --- Extended retention (keep certain snapshots longer) ---
    extended_retention = optional(list(object({
      schedule = object({
        unit      = string
        frequency = number
      })
      retention = object({
        duration = number
        unit     = string
        data_lock_config = optional(object({
          mode                           = string
          unit                           = string
          duration                       = number
          enable_worm_on_external_target = optional(bool, false)
        }))
      })
      run_type  = optional(string, "Regular")
      config_id = optional(string)
    })))

    # --- Cascaded Targets Config ---
    cascaded_targets_config = optional(object({
      source_cluster_id = number
      remote_targets = list(object({
        archival_targets = optional(list(object({
          target_id           = number
          backup_run_type     = optional(string)
          config_id           = optional(string)
          copy_on_run_success = optional(bool)
          schedule = object({
            unit      = string
            frequency = optional(number)
          })
          retention = object({
            duration         = number
            unit             = string
            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
          })
          extended_retention = optional(list(object({
            schedule = object({
              unit      = string
              frequency = number
            })
            retention = object({
              duration         = number
              unit             = string
              data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
            })
            run_type  = optional(string, "Regular")
            config_id = optional(string)
          })))
        })))
        cloud_spin_targets = optional(list(object({
          target = object({
            id = optional(number)
          })
          backup_run_type     = optional(string)
          config_id           = optional(string)
          copy_on_run_success = optional(bool)
          schedule = object({
            unit      = string
            frequency = optional(number)
          })
          retention = object({
            duration         = number
            unit             = string
            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
          })
          log_retention = optional(object({
            duration         = number
            unit             = string
            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
          }))
          run_timeouts = optional(list(object({
            timeout_mins = optional(number)
            backup_type  = optional(string)
          })))
        })))
        replication_targets = optional(list(object({
          target_type         = string
          backup_run_type     = optional(string)
          config_id           = optional(string)
          copy_on_run_success = optional(bool)
          schedule = object({
            unit      = string
            frequency = optional(number)
          })
          retention = object({
            duration         = number
            unit             = string
            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
          })
          log_retention = optional(object({
            duration         = number
            unit             = string
            data_lock_config = optional(object({ mode = string, unit = string, duration = number, enable_worm_on_external_target = optional(bool, false) }))
          }))
          run_timeouts = optional(list(object({
            timeout_mins = optional(number)
            backup_type  = optional(string)
          })))
          aws_target_config = optional(object({
            region    = number
            source_id = number
          }))
          azure_target_config = optional(object({
            resource_group = optional(number)
            source_id      = number
          }))
          remote_target_config = optional(object({
            cluster_id = number
          }))
        })))
      }))
    }))
  }))
  default = [{
    name = "basic-policy"
    schedule = {
      unit         = "Days"
      day_schedule = { frequency = 1 }
    }
    retention = {
      duration = 2
      unit     = "Days"
    }
  }]

  # 1. Structural Validation
  validation {
    condition = alltrue([
      for p in var.policies : (
        p.create_new_policy == false ||
        (p.schedule != null && p.retention != null)
      )
    ])
    error_message = "When create_new_policy is true, both schedule and retention are required."
  }

  # 2. Unit Enumerations (Registry Constraint: "Allowable values: Days, Weeks, Months, Years")
  validation {
    condition = alltrue([
      for p in var.policies : p.retention == null ? true :
      contains(["Days", "Weeks", "Months", "Years"], p.retention.unit)
    ])
    error_message = "Retention unit must be one of: Days, Weeks, Months, Years."
  }

  # 3. Frequency Minimums (Registry/Cohesity Constraint: Minutes >= 7, Others >= 1)
  validation {
    condition = alltrue([
      for p in var.policies : p.schedule == null ? true : (
        (p.schedule.minute_schedule == null ? true : p.schedule.minute_schedule.frequency >= 7) &&
        (p.schedule.hour_schedule == null ? true : p.schedule.hour_schedule.frequency >= 1) &&
        (p.schedule.day_schedule == null ? true : p.schedule.day_schedule.frequency >= 1)
      )
    ])
    error_message = "Invalid frequency: Minutes must be >= 7. Hours and Days must be >= 1."
  }

  # 4. Data Lock (WORM) Modes (Registry Constraint: "Compliance" or "Administrative")
  validation {
    condition = alltrue([
      for p in var.policies : (
        p.retention == null ? true : (
          p.retention.data_lock_config == null ? true :
          contains(["Compliance", "Administrative"], p.retention.data_lock_config.mode)
        )
      )
    ])
    error_message = "Data lock mode must be 'Compliance' or 'Administrative'."
  }

  # 5. Blackout Window Weekdays (Registry Constraint: Proper case day names)
  validation {
    condition = alltrue([
      for p in var.policies : p.blackout_window == null ? true : alltrue([
        for bw in p.blackout_window :
        contains(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], bw.day)
      ])
    ])
    error_message = "Blackout window 'day' must be the full weekday name (e.g., 'Monday')."
  }

  # 6. Run Timeouts Backup Types (Registry Constraint: kRegular, kFull, kLog, kSystem)
  validation {
    condition = alltrue([
      for p in var.policies : p.run_timeouts == null ? true : alltrue([
        for rt in p.run_timeouts :
        contains(["kRegular", "kFull", "kLog", "kSystem", "kHydrateCDP", "kStorageArraySnapshot"], rt.backup_type)
      ])
    ])
    error_message = "Invalid backup_type in run_timeouts. Allowed: kRegular, kFull, kLog, kSystem, kHydrateCDP, kStorageArraySnapshot."
  }

  # 7. Tiering Platform Cross-Check
  # Ensures user doesn't provide azure_tiering when cloud_platform is "AWS"
  validation {
    condition = alltrue([
      for p in var.policies : (
        p.primary_backup_target_details == null ? true : (
          p.primary_backup_target_details.tier_settings == null ? true : alltrue([
            for ts in p.primary_backup_target_details.tier_settings : (
              (ts.cloud_platform == "AWS" ? ts.aws_tiering != null : true) &&
              (ts.cloud_platform == "Azure" ? ts.azure_tiering != null : true) &&
              (ts.cloud_platform == "Oracle" ? ts.oracle_tiering != null : true) &&
              (ts.cloud_platform == "Google" ? ts.google_tiering != null : true)
            )
          ])
        )
      )
    ])
    error_message = "The tiering configuration block must match the selected cloud_platform (e.g., provide 'aws_tiering' for 'AWS')."
  }
}
