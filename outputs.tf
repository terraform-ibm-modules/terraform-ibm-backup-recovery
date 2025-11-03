output "registration_token" {
  value     = ibm_backup_recovery_connection_registration_token.registration_token.token
  sensitive = true
}

output "tenant_id" {
  value = local.tenant_id
}

output "connection_id" {
  value = var.create_new_connection ? ibm_backup_recovery_data_source_connection.connection[0].connection_id : data.ibm_backup_recovery_data_source_connections.connections[0].connections[0].connection_id
}
