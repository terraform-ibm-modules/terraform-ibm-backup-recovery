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

variable "access_tags" {
  type        = list(string)
  description = "Add existing access management tags to the Backup Recovery instance to manage access. Before you can attach your access management tags, you must create them first. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#create-access-console)."
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
}

variable "connection_env_type" {
  type        = string
  default     = null
  description = "Type of the data source connection. Set to `null` for VPC and VMware data source connections. Required for IKS/ROKS cluster connections — allowed values are: 'kIksVpc', 'kIksClassic', 'kRoksVpc', 'kRoksClassic'."
}

variable "service_endpoints" {
  type        = string
  description = "Types of service endpoints to enable for the Backup Recovery instance. Allowed values: 'public', 'private', 'public-and-private'."
  default     = "public"
}

variable "parameters_json" {
  type        = string
  description = "Optional JSON string to configure the Backup Recovery Service instance. Example: jsonencode({ key1 = \"value1\", nested = { enabled = true } })"
  default     = null
}
