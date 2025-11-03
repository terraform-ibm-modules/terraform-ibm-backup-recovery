variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  sensitive   = true
}

variable "region" {
  type        = string
  description = "IBM Cloud region where all resources will be provisioned."
  default     = "us-south"

  validation {
    condition     = contains(["us-south", "us-east", "eu-gb", "eu-de", "eu-fr2", "jp-tok", "au-syd", "ca-tor", "br-sao"], var.region)
    error_message = "The region must be a valid IBM Cloud region."
  }
}

variable "prefix" {
  type        = string
  description = "A unique prefix to name all resources created by this example. Must be lowercase, no spaces, and 3–12 characters."
  default     = "brs-basic"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,10}[a-z0-9]$", var.prefix))
    error_message = "Prefix must be 3–12 characters, lowercase, start/end with letter/number, and contain only letters, numbers, or hyphens."
  }
}

variable "resource_group" {
  type        = string
  description = "Name of an existing resource group to use. If null, a new resource group will be created using the prefix."
  default     = null
}

variable "instance_name" {
  type        = string
  description = "Name of the Backup & Recovery Service (BRS) instance to create or reference."
  default     = "brs-instance"

  validation {
    condition     = length(var.instance_name) >= 3 && length(var.instance_name) <= 63
    error_message = "instance_name must be between 3 and 63 characters."
  }
}

variable "connection_name" {
  type        = string
  description = "Name of the data source connection to create or reference."
  default     = "brs-connection"

  validation {
    condition     = length(var.connection_name) >= 3 && length(var.connection_name) <= 63
    error_message = "connection_name must be between 3 and 63 characters."
  }
}

variable "provision_code" {
  type        = string
  description = "Custom provision code required for BRS instance creation (provided by IBM)."

  validation {
    condition     = length(trimspace(var.provision_code)) > 0
    error_message = "provision_code cannot be empty or whitespace."
  }
}