########################################################################################################################
# Outputs
########################################################################################################################

output "brs_instance" {
  description = "Details of the BRS instance."
  value       = local.brs_instance
}
output "brs_instance_crn" {
  description = "CRN of the BRS instance."
  value       = local.brs_instance.crn
}
output "tenant_id" {
  description = "BRS tenant ID (with trailing slash)."
  value       = local.brs_instance.extensions["tenant-id"]
}

output "resource_group_id" {
  description = "ID of the resource group used."
  value       = module.resource_group.resource_group_id
}
