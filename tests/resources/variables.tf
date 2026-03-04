variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  sensitive   = true
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "prefix" {
  type        = string
  description = "A unique prefix to name all resources created by this example. Must be lowercase, no spaces, and 3–12 characters."
  default     = "brs-basic"
}

variable "resource_tags" {
  type        = list(string)
  description = "Add user resource tags to the Backup Recovery instance to organize, track, and manage costs. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#tag-types)."
  default     = []
}

variable "region" {
  type        = string
  description = "IBM Cloud region where the instance is located or will be created."
  default     = "us-east"
}

variable "existing_brs_instance_crn" {
  description = "CRN of the Backup & Recovery Service instance."
  type        = string
  default     = null

  validation {
    condition     = var.existing_brs_instance_crn == null || can(regex("^crn:v1:[a-z0-9-]+:[a-z0-9-]*:[a-z0-9-]+:[a-z0-9-]*:a/[a-f0-9]+:[a-f0-9-]+::$", var.existing_brs_instance_crn))
    error_message = "'existing_brs_instance_crn' must be a valid CRN. Example: crn:v1:bluemix:public:backup-recovery:<region>:a/<account-id>:<instance-guid>::"
  }
}
