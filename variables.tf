###############################
# Instance Configuration
###############################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  sensitive   = true
  default     = null
}

variable "brs_instance_crn" {
  type        = string
  description = "The CRN of the existing Backup & Recovery Service instance. If not provided, a new instance will be created."
  default     = null

  validation {
    condition     = var.brs_instance_crn == null || can(regex("^crn:v1:bluemix:public:backup-recovery:.*:a/[a-f0-9]{32}:.*:instance:.*$", var.brs_instance_crn))
    error_message = "The brs_instance_crn must be a valid IBM Cloud CRN or null."
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

variable "tags" {
  type        = list(string)
  description = "Metadata labels describing this backup and recovery service instance, i.e. test"
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

variable "endpoint_type" {
  type        = string
  description = "The endpoint type to use when connecting to the Backup and Recovery service for creating a data source connection. Allowed values are 'public' or 'private'."
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.endpoint_type)
    error_message = "endpoint_type must be 'public' or 'private'."
  }
}
