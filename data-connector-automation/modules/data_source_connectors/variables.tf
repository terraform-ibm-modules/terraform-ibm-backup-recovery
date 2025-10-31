variable "release_name" {
  type        = string
  description = "The name of the Helm release for the Cohesity DSC chart."
  validation {
    condition     = var.release_name != ""
    error_message = "The release_name must not be empty."
  }
}

variable "chart_name" {
  type        = string
  description = "The name of the Helm chart to deploy (e.g., cohesity-dsc-chart)."
  validation {
    condition     = var.chart_name != ""
    error_message = "The chart_name must not be empty."
  }
}

variable "chart_repository" {
  type        = string
  description = "The repository URL where the Helm chart is hosted (e.g., OCI registry URL)."
  validation {
    condition     = can(regex("^oci://[a-zA-Z0-9.-]+/[a-zA-Z0-9.-]+(/[-a-zA-Z0-9._]+)?/?$", var.chart_repository))
    error_message = "The chart_repository must be a valid OCI URL starting with 'oci://' and followed by a valid repository path."
  }
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace where the Helm chart will be deployed."
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "The namespace must be a valid Kubernetes namespace name (lowercase alphanumeric, hyphens allowed, 1-63 characters)."
  }
}

variable "create_namespace" {
  type        = bool
  description = "Whether to create the Kubernetes namespace if it does not exist."
}

# variable "atomic" {
#   type        = bool
#   description = "Whether to enable atomic deployment for the Helm chart (rolls back on failure)."
# }

variable "chart_version" {
  type        = string
  description = "The version of the Helm chart to deploy."
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.-]+)?$", var.chart_version))
    error_message = "The chart_version must be a valid semantic version (e.g., 7.2.15 or 7.2.15-release-20250721-6aa24701)."
  }
}

variable "image" {
  type = object({
    namespace  = string
    repository = string
    tag        = string
    pullPolicy = string
  })
  description = "Configuration for the container image used in the Helm chart."
  validation {
    condition     = var.image.namespace != "" && var.image.repository != "" && var.image.tag != ""
    error_message = "The image namespace, repository, and tag must not be empty."
  }
  validation {
    condition     = contains(["Always", "IfNotPresent", "Never"], var.image.pullPolicy)
    error_message = "The image pullPolicy must be one of: Always, IfNotPresent, Never."
  }
}
variable "registration_token" {
  type        = string
  description = "connector registration token"
}
variable "replica_count" {
  type        = number
  description = "number of data source connectors."
  default     = 1
}
variable "timeout" {
  type        = number
  description = "Time in seconds to wait for deployment of release"
  default     = 1800
}