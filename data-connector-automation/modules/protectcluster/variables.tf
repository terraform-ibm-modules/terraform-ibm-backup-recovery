variable "tenant_id" {
  type        = string
  description = "IBM Cloud tenant ID"
}

variable "connection_id" {
  type        = string
  description = "Connection ID for the backup service"
}

variable "registration" {
  type = object({
    name = string
    cluster = object({
      id                = string
      resource_group_id = string
      endpoint          = string
      distribution      = string
      images = object({
        data_mover              = string
        velero                  = string
        velero_aws_plugin       = string
        velero_openshift_plugin = string
        init_container          = string
      })
    })
  })
  description = "Kubernetes cluster registration details"
  sensitive   = true
}

variable "policy" {
  type = object({
    name = string
  })
  description = "Backup policy details"
}