# modules/data_source_connection/main.tf

data "ibm_backup_recovery_data_source_connections" "connections" {
  count            = var.create_new ? 0 : 1
  x_ibm_tenant_id  = var.tenant_id
  connection_names = [var.connection_name]
}

resource "ibm_backup_recovery_data_source_connection" "connection" {
  count           = var.create_new ? 1 : 0
  x_ibm_tenant_id = var.tenant_id
  connection_name = var.connection_name
  endpoint_type   = var.endpoint_type
  instance_id     = var.instance_id
  region          = var.region
}

resource "ibm_backup_recovery_connection_registration_token" "registration_token" {
  connection_id   = var.create_new ? ibm_backup_recovery_data_source_connection.connection[0].connection_id : data.ibm_backup_recovery_data_source_connections.connections[0].connections[0].connection_id
  x_ibm_tenant_id = var.tenant_id
}