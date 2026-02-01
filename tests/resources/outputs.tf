########################################################################################################################
# Outputs
########################################################################################################################

output "brs_instance" {
  description = "Details of the BRS instance."
  value       = ibm_resource_instance.backup_recovery_instance
}
output "brs_instance_crn" {
  description = "CRN of the BRS instance."
  value       = ibm_resource_instance.backup_recovery_instance.crn
}
output "tenant_id" {
  description = "BRS tenant ID (with trailing slash)."
  value       = ibm_resource_instance.backup_recovery_instance.extensions["tenant-id"]
}
# Outputs below are no longer available as connection creation was removed from this minimal test resource
# output "brs_connection_name" {
#   description = "Name of the data source connection."
#   value       = module.brs.connection_name
#   sensitive   = true
# }
# output "brs_connection_id" {
#   description = "ID of the data source connection."
#   value       = module.brs.connection_id
#   sensitive   = true
# }
# output "registration_token" {
#   description = "Token to register backup agent. Use with caution — expires in 24h."
#   value       = module.brs.registration_token
#   sensitive   = true
# }

output "resource_group_id" {
  description = "ID of the resource group used."
  value       = module.resource_group.resource_group_id
}
