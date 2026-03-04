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

###############################
# Connection Configuration
###############################

variable "create_new_connection" {
  type        = bool
  description = "Set to true to create a new data source connection, false to use existing."
  default     = true
}

variable "connection_name" {
  type        = string
  description = "Name of the data source connection."
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
  description = "A list of protection policies to create or look up. For new policies, provide `schedule` and `retention`. To reference existing policies by name, omit `schedule` and `retention`."
  type = list(object({
    name = string

    use_default_backup_target = optional(bool)

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
        })))
      }))
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for p in var.policies : (
        (p.schedule == null && p.retention == null) ||
        (p.schedule != null && p.retention != null)
      )
    ])
    error_message = "For existing policies, do not provide schedule or retention (both must be null). For custom policies, both schedule and retention are required."
  }
}
