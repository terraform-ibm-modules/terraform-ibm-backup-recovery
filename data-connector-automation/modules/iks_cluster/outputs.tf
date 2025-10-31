# Output the cluster ID, name, and endpoint
output "cluster_id" {
  description = "ID of the created IKS cluster"
  value       = var.create_new ? ibm_container_vpc_cluster.iks_cluster[0].id : data.ibm_container_vpc_cluster.existing_cluster[0].id
}

output "cluster_name" {
  description = "Name of the created IKS cluster"
  value       = var.create_new ? ibm_container_vpc_cluster.iks_cluster[0].name : data.ibm_container_vpc_cluster.existing_cluster[0].name
}

output "kube_version" {
  description = "Kubernetes version used by the cluster"
  value       = local.selected_kube_version
}

output "public_service_endpoint_url" {
  description = "Public service endpoint URL of the cluster"
  value       = var.create_new ? ibm_container_vpc_cluster.iks_cluster[0].public_service_endpoint_url : data.ibm_container_vpc_cluster.existing_cluster[0].public_service_endpoint_url
}

output "private_service_endpoint_url" {
  description = "Public service endpoint URL of the cluster"
  value       = var.create_new ? ibm_container_vpc_cluster.iks_cluster[0].private_service_endpoint_url : data.ibm_container_vpc_cluster.existing_cluster[0].private_service_endpoint_url
}