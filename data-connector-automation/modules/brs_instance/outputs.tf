output "tenant_id" {
  description = "The tenant ID associated with the Backup and Recovery Service resource instance, used to identify the tenancy context for the service."
  value       = var.create_new ? ibm_resource_instance.brs-instance[0].extensions.tenant-id : data.ibm_resource_instance.brs-instance[0].extensions.tenant-id
}
output "public_endpoint" {
  value = var.create_new ? ibm_resource_instance.brs-instance[0].extensions["endpoints.public"] : data.ibm_resource_instance.brs-instance[0].extensions["endpoints.public"]
}
output "private_endpoint" {
  value = var.create_new ? ibm_resource_instance.brs-instance[0].extensions["endpoints.private"] : data.ibm_resource_instance.brs-instance[0].extensions["endpoints.private"]
}
output "instance" {
  value = var.create_new ? ibm_resource_instance.brs-instance[0] : data.ibm_resource_instance.brs-instance[0]
}