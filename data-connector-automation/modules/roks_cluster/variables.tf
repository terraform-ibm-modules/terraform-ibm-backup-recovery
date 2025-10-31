variable "create_new" {
  type        = bool
  description = "Whether to create a new cluster (true) or use an existing cluster (false)."
  default     = true
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster to be created."
}

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group where the cluster will be deployed."
}

variable "region" {
  type        = string
  description = "The region where the cluster and associated resources will be created."
}

variable "force_delete_storage" {
  type        = bool
  description = "Whether to force deletion of storage resources associated with the cluster during cleanup."
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the cluster will be deployed."
}

variable "vpc_subnets" {
  type = map(list(object({
    id         = string
    zone       = string
    cidr_block = string
  })))
  description = "Metadata describing the VPC's subnets, including their IDs, availability zones, and CIDR blocks."
}

variable "ocp_version" {
  type        = string
  description = "The version of OpenShift Container Platform (OCP) to deploy."
}

variable "disable_outbound_traffic_protection" {
  type        = bool
  description = "Whether to disable outbound traffic protection for the cluster."
  default     = false
}

variable "subnet_prefix" {
  type        = string
  description = "The prefix used to identify subnets for the cluster."
}

variable "pool_name" {
  type        = string
  description = "The name of the worker pool for the cluster."
}

variable "machine_type" {
  type        = string
  description = "The machine type to use for the cluster's worker nodes."
}

variable "workers_per_zone" {
  type        = number
  description = "The number of worker nodes per availability zone."
}

variable "operating_system" {
  type        = string
  description = "The operating system to use for the cluster's worker nodes."
}