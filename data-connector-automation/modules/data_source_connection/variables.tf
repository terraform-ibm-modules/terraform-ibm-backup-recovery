# modules/data_source_connection/variables.tf

variable "tenant_id" {
  description = "IBM Cloud tenant ID for the backup/recovery data source connection"
  type        = string
}

variable "connection_name" {
  description = "Name of the backup/recovery data source connection"
  type        = string
}
variable "create_new" {
  type    = bool
  default = true
}
variable "endpoint_type" {
  type        = string
  default     = "public"
  description = "Backup Recovery Endpoint type. By default set to public."
}
variable "instance_id" {
  type        = string
  description = "Backup Recovery instance ID. If provided here along with region, the provider constructs the endpoint URL"
}
variable "region" {
  type = string
}