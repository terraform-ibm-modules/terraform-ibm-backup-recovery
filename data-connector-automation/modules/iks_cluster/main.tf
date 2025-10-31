# Fetch valid Kubernetes versions for the resource group (only when creating a new cluster)
data "ibm_container_cluster_versions" "cluster_versions" {
  count             = var.create_new ? 1 : 0
  resource_group_id = var.resource_group_id
}

# Fetch existing cluster details if specified
data "ibm_container_vpc_cluster" "existing_cluster" {
  count             = var.create_new ? 0 : 1
  name              = var.cluster_name
  resource_group_id = var.resource_group_id
}

# Local variable to determine the Kubernetes version to use
locals {
  selected_kube_version = var.create_new ? (
    var.kube_version != null ? var.kube_version : data.ibm_container_cluster_versions.cluster_versions[0].default_kube_version
  ) : data.ibm_container_vpc_cluster.existing_cluster[0].kube_version
}

# Validate the provided kube_version against valid versions (only when creating a new cluster)
resource "null_resource" "kube_version_validation" {
  count = var.create_new ? (var.kube_version != null ? 1 : 0) : 0
  triggers = {
    kube_version = var.kube_version
  }
  lifecycle {
    precondition {
      condition     = contains(data.ibm_container_cluster_versions.cluster_versions[0].valid_kube_versions, var.kube_version)
      error_message = "The specified kube_version '${var.kube_version}' is not valid. Valid versions are: ${join(", ", data.ibm_container_cluster_versions.cluster_versions[0].valid_kube_versions)}"
    }
  }
}

# Creating the IKS cluster on IBM Cloud VPC
resource "ibm_container_vpc_cluster" "iks_cluster" {
  count             = var.create_new ? 1 : 0
  name              = var.cluster_name
  vpc_id            = var.vpc_id
  flavor            = var.flavor
  worker_count      = var.worker_count
  resource_group_id = var.resource_group_id
  kube_version      = local.selected_kube_version
  tags              = var.tags

  dynamic "zones" {
    for_each = var.zones
    content {
      name      = zones.value
      subnet_id = var.subnet_ids[index(var.zones, zones.value)]
    }
  }

  # Enable public service endpoint to align with backup integration
  disable_public_service_endpoint = false

  # Configure default worker pool labels
  worker_labels = {
    "environment" = "test"
  }

  # Wait for the cluster to be ready
  wait_for_worker_update = true

  # Ensure kube_version validation runs before cluster creation
  depends_on = [null_resource.kube_version_validation]
}