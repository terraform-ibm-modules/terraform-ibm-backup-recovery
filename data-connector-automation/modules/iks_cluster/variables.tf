# Defining variables for the IKS cluster module
variable "cluster_name" {
  description = "Name of the IKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster, must match the order of zones"
  type        = list(string)
  validation {
    condition     = var.create_new ? length(var.subnet_ids) > 0 : true
    error_message = "At least one subnet ID must be provided."
  }
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "flavor" {
  description = "Machine type for worker nodes (e.g., bx2.4x16)"
  type        = string
  default     = "bx2.4x16"
}

variable "worker_count" {
  description = "Number of worker nodes per zone"
  type        = number
  default     = 1
  validation {
    condition     = var.create_new ? var.worker_count >= 1 : true
    error_message = "Worker count must be at least 1 per zone."
  }
}

variable "kube_version" {
  description = "Kubernetes version for the cluster (e.g., 1.28). If not specified, uses the default version."
  type        = string
  default     = null
}

variable "zones" {
  description = "List of availability zones for the cluster"
  type        = list(string)
  validation {
    condition     = var.create_new ? length(var.zones) > 0 : true
    error_message = "At least one zone must be provided."
  }
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = list(string)
  default     = []
}

variable "create_new" {
  type        = bool
  default     = true
  description = "If true, create a new cluster; if false, use an existing one."
}