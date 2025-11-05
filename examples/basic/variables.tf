variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  sensitive   = true
}


variable "prefix" {
  type        = string
  description = "A unique prefix to name all resources created by this example. Must be lowercase, no spaces, and 3–12 characters."
  default     = "brs-basic"
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

variable "resource_group" {
  type        = string
  description = "Name of an existing resource group to use. If null, a new resource group will be created using the prefix."
  default = "Default"
}
