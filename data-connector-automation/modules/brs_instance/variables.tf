variable "instance_name" {
  type        = string
  description = "The unique name for the Backup and Recovery Service resource instance that will be created."
}

variable "name" {
  type        = string
  description = "The identifier used to search for the Backup and Recovery Service in the IBM Cloud service catalog."
}

variable "plan" {
  type        = string
  description = "The plan type for the Backup and Recovery Service. Currently, only the premium plan is available."
  default     = "premium"
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the resource instance will be deployed (e.g., us-south, eu-de)."
}

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group where the resource instance will be created."
}

variable "provision_code" {
  type        = string
  description = "The provisioning code or service ID for the Backup and Recovery Service."
}

variable "timeouts" {
  type = object({
    create = string
    update = string
    delete = string
  })
  description = "Timeout configurations for create, update, and delete operations on the resource instance."
  default = {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}
variable "create_new" {
  type    = bool
  default = true
}