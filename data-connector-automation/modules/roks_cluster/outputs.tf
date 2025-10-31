output "cluster_id" {
  description = "The ID of the OpenShift cluster, either created or retrieved from an existing cluster."
  value       = var.create_new ? try(module.ocp_base[0].cluster_id, null) : try(data.ibm_container_vpc_cluster.existing_cluster[0].id, null)
}

output "public_service_endpoint_url" {
  description = "The public service endpoint URL of the OpenShift cluster."
  value       = var.create_new ? try(module.ocp_base[0].public_service_endpoint_url, null) : try(data.ibm_container_vpc_cluster.existing_cluster[0].public_service_endpoint_url, null)
}

output "private_service_endpoint_url" {
  description = "The private service endpoint URL of the OpenShift cluster."
  value       = var.create_new ? try(module.ocp_base[0].private_service_endpoint_url, null) : try(data.ibm_container_vpc_cluster.existing_cluster[0].private_service_endpoint_url, null)
}