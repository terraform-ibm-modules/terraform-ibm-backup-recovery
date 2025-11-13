###############################
# Instance Configuration
###############################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  sensitive   = true
}

variable "create_new_instance" {
  type        = bool
  description = "Set to true to create a new BRS instance, false to use existing one."
  default     = true
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

variable "kms_key_crn" {
  type        = string
  description = "The CRN of the key management service key to encrypt the backup data."
  default     = null
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
  nullable    = false
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
