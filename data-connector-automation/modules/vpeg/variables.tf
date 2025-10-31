# Manages an IBM Cloud Virtual Private Endpoint (VPE) Gateway.
# Creates a new VPE gateway if var.create_new is true, otherwise fetches an existing one by name.

variable "region" {
  type        = string
  description = "The IBM Cloud region where the VPE gateway will be deployed (e.g., us-south)."
  validation {
    condition     = contains(["us-south", "us-east", "eu-gb", "eu-de", "au-syd", "jp-tok"], var.region)
    error_message = "The region must be a valid IBM Cloud region, such as 'us-south', 'us-east', 'eu-gb', etc."
  }
}

variable "name" {
  type        = string
  description = "The name of the existing VPE gateway to fetch when create_new is false."
  default     = null
  validation {
    condition     = var.create_new ? true : length(var.name) > 0
    error_message = "The name must be provided when create_new is false."
  }
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC where the VPE gateway will be created."
  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "The vpc_name cannot be empty."
  }
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the VPE gateway will be created."
  validation {
    condition     = can(regex("^r[0-9]{3}-[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.vpc_id))
    error_message = "The vpc_id must be a valid IBM Cloud VPC ID."
  }
}

variable "subnet_zone_list" {
  type = list(object({
    cidr = string
    crn  = string
    id   = string
    name = string
    zone = string
  }))
  description = "A list of subnet objects, each containing CIDR, CRN, ID, name, and zone for the VPE gateway."
  validation {
    condition     = length(var.subnet_zone_list) > 0
    error_message = "At least one subnet must be provided in subnet_zone_list."
  }
}

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group for the VPE gateway."
  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.resource_group_id))
    error_message = "The resource_group_id must be a valid 32-character hexadecimal IBM Cloud resource group ID."
  }
}

variable "create_new" {
  type        = bool
  description = "Whether to create a new VPE gateway (true) or use an existing one (false)."
  default     = true
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to associate with the VPE gateway."
  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security group ID must be provided."
  }
}

variable "cloud_service_crn" {
  type        = string
  description = "The CRN of the cloud service to bind to the VPE gateway."
  validation {
    condition     = can(regex("^crn:v1:.*:.*:.*:.*:.*:.*:.*:.*$", var.cloud_service_crn))
    error_message = "The cloud_service_crn must be a valid IBM Cloud CRN."
  }
}

variable "service_endpoints" {
  type        = string
  description = "The type of service endpoints for the VPE gateway ('private' or 'public')."
  default     = "private"
  validation {
    condition     = contains(["private", "public"], var.service_endpoints)
    error_message = "The service_endpoints must be either 'private' or 'public'."
  }
}