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
  default     = "brsinstance"

  validation {
    condition     = length(var.instance_name) > 0
    error_message = "instance_name must not be empty."
  }
}

variable "plan" {
  type        = string
  description = "The plan type for the Backup and Recovery Service. Currently, only the premium plan is available."
  default     = "premium"

  validation {
    condition     = var.plan == "premium"
    error_message = "The Backup and Recovery Service currently supports only the 'premium' plan. Use plan = \"premium\"."
  }
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
}

variable "kms_root_key_crn" {
  type        = string
  description = "CRN of the KMS root key"
  default     = ""
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
  description = "The endpoint type to use when connecting to the Backup and Recovery service for creating a data source connection"
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.endpoint_type)
    error_message = "endpoint_type must be 'public' or 'private'."
  }
}
variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  sensitive   = true
}