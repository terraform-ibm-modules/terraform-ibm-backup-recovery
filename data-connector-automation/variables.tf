variable "ibmcloud_api_key" {
  type        = string
  sensitive   = true
  description = "The IBM Cloud API key for authentication."
  validation {
    condition     = var.ibmcloud_api_key != ""
    error_message = "The ibmcloud_api_key must not be empty."
  }
}

variable "resource_group" {
  type = object({
    name       = string
    create_new = bool
  })
  description = "The name of the existing resource group where resources will be deployed."
  validation {
    condition     = var.resource_group.name != ""
    error_message = "The resource_group.name must not be empty."
  }
}

variable "vpc" {
  type = object({
    name                       = string
    create_new                 = bool
    create_subnet_gateway      = bool
    auto_assign_address_prefix = bool
    prefix                     = string
  })
  description = "The name of the existing VPC where resources will be deployed."
  validation {
    condition     = var.vpc.name != ""
    error_message = "The vpc.name must not be empty."
  }
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where resources will be deployed (e.g., us-east)."
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+$", var.region))
    error_message = "The region must be a valid IBM Cloud region (e.g., us-east)."
  }
}

variable "brs_service" {
  type = object({
    name           = string
    provision_code = string
    instance_name  = string
    create_new     = bool
    region         = string
    vpeg = object({
      service_endpoints = string
      create_new        = bool
      name              = string
    })
  })
  description = "Configuration for the Backup and Recovery Service (BRS) instance."
  validation {
    condition     = alltrue([var.brs_service.name != "", var.brs_service.provision_code != "", var.brs_service.instance_name != ""])
    error_message = "All fields in brs_service (name, provision_code, instance_name) must be non-empty."
  }
}

variable "iks_cluster" {
  type = object({
    name             = string
    iks_version      = string
    workers_per_zone = number
    machine_type     = string
    operating_system = string
    pool_name        = string
    create_new       = bool
    connection = object({
      create_new      = bool
      endpoint_type   = string
      connection_name = string
    })
    protection = object({
      source_name = string
      policy_name = string
      images = object({
        data_mover              = string
        velero                  = string
        velero_aws_plugin       = string
        velero_openshift_plugin = string
        init_container          = string
      })
      connector = object({
        release_name     = string
        chart_name       = string
        chart_repository = string
        namespace        = string
        chart_version    = string
        image = object({
          namespace  = string
          repository = string
          tag        = string
          pullPolicy = string
        })
        replica_count    = number
        timeout          = number
        create_namespace = bool
      })
    })

  })
  description = "Configuration for the IKS cluster on IBM Cloud."
}

variable "roks_cluster" {
  type = object({
    name             = string
    ocp_version      = string
    workers_per_zone = number
    machine_type     = string
    operating_system = string
    pool_name        = string
    create_new       = bool
    connection = object({
      create_new      = bool
      endpoint_type   = string
      connection_name = string
    })
    protection = object({
      source_name = string
      policy_name = string
      images = object({
        data_mover              = string
        velero                  = string
        velero_aws_plugin       = string
        velero_openshift_plugin = string
        init_container          = string
      })
      connector = object({
        release_name     = string
        chart_name       = string
        chart_repository = string
        namespace        = string
        chart_version    = string
        image = object({
          namespace  = string
          repository = string
          tag        = string
          pullPolicy = string
        })
        replica_count    = number
        timeout          = number
        create_namespace = bool
      })
    })

  })
  description = "Configuration for the Red Hat OpenShift on IBM Cloud (ROKS) cluster."
  validation {
    condition     = var.roks_cluster.name != ""
    error_message = "The roks_cluster.name must not be empty."
  }
  validation {
    condition     = contains(["4.14", "4.15", "4.16", "4.17", "4.18", "default"], var.roks_cluster.ocp_version)
    error_message = "The roks_cluster.ocp_version must be one of: 4.14, 4.15, 4.16, 4.17, 4.18, or default."
  }
  validation {
    condition     = var.roks_cluster.pool_name != ""
    error_message = "The roks_cluster.pool_name must not be empty."
  }
  validation {
    condition     = var.roks_cluster.workers_per_zone >= 1
    error_message = "The roks_cluster.workers_per_zone must be at least 1."
  }
  validation {
    condition     = contains(["REDHAT_8_64", "RHEL_9_64", "RHCOS"], var.roks_cluster.operating_system)
    error_message = "The roks_cluster.operating_system must be one of: REDHAT_8_64, RHEL_9_64, RHCOS."
  }
  validation {
    condition     = var.roks_cluster.operating_system != "RHCOS" || contains(["4.15", "4.16", "4.17", "4.18"], var.roks_cluster.ocp_version)
    error_message = "RHCOS is only supported for OpenShift versions 4.15 and later."
  }
}

variable "registry_creds" {
  type = list(object({
    url      = string
    username = string
    password = string
  }))
}