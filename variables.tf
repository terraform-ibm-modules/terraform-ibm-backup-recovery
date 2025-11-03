###############################
# Instance Configuration
###############################

variable "create_new_instance" {
  type        = bool
  description = "Set to true to create a new BRS instance, false to use existing one."
  default     = true
}

variable "instance_name" {
  type        = string
  description = "Name of the Backup & Recovery Service instance."
  default     = "brs-test-instance"

  validation {
    condition     = length(var.instance_name) > 0
    error_message = "instance_name must not be empty."
  }
}

variable "name" {
  type        = string
  description = "Service name for BRS (should be 'backup-recovery')"
  default     = "backup-recovery"
}

variable "plan" {
  type        = string
  description = "The plan type for the Backup and Recovery Service. Currently, only the premium plan is available."
  default     = "premium"
}

variable "region" {
  type        = string
  description = "IBM Cloud region where the instance is located or will be created."
  default     = "us-east"

  validation {
    condition     = contains(["us-south", "us-east", "eu-gb", "eu-de", "eu-fr2", "jp-tok", "au-syd", "ca-tor", "br-sao"], var.region)
    error_message = "region must be a valid IBM Cloud region."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID where the BRS instance exists or will be created."
  default     = null # Must be provided or set via env

  validation {
    condition     = var.resource_group_id != null && length(var.resource_group_id) > 0
    error_message = "resource_group_id is required and must not be empty."
  }
}

variable "provision_code" {
  type        = string
  description = "Custom provision code for BRS instance."
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
  default     = "test-connection"

  validation {
    condition     = length(var.connection_name) > 0
    error_message = "connection_name must not be empty."
  }
}

variable "endpoint_type" {
  type        = string
  description = "Endpoint type: 'public' or 'private'."
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.endpoint_type)
    error_message = "endpoint_type must be 'public' or 'private'."
  }
}

###############################
# Timeouts
###############################

variable "timeouts" {
  type = object({
    create = string
    update = string
    delete = string
  })
  description = "Timeouts for create, update, and delete operations."
  default = {
    create = "60m"
    update = "30m"
    delete = "30m"
  }
}