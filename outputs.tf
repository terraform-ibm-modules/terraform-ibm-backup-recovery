output "registration_token" {
  description = "Registration token used to enroll data source connectors with the BRS connection. Expires in 24 hours. Must be kept secure."
  value       = ibm_backup_recovery_connection_registration_token.registration_token.registration_token
  sensitive   = true
}

output "tenant_id" {
  description = "BRS tenant ID in the format `<tenant-guid>/`. Required for API calls and agent configuration."
  value       = local.tenant_id
}

output "connection_id" {
  description = "Unique ID of the data source connection. Used to identify the connection in BRS for agent registration and management."
  value       = local.backup_recovery_connection_id
}

output "brs_instance_guid" {
  description = "GUID of the BRS instance."
  value       = local.backup_recovery_instance.guid
}

output "brs_instance_crn" {
  description = "CRN of the BRS instance."
  value       = local.backup_recovery_instance.crn
}

output "brs_instance" {
  description = "Details of the BRS instance."
  value       = local.backup_recovery_instance
}

output "brs_instance_crn" {
  description = "CRN of the BRS instance."
  value       = local.backup_recovery_instance.crn
}

output "brs_instance" {
  description = "Details of the BRS instance."
  value       = local.backup_recovery_instance
}
