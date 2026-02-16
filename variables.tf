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
  description = "A list of access tags to apply to the Backup Recovery instance. [Learn more](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression `\"[\\w\\-_\\.]+:[\\w\\-_\\.]+\"`. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits)."
  }
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
