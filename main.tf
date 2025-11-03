
# brs_instance
locals {
  tenant_id_raw = var.create_new_instance ? ibm_resource_instance.brs-instance[0].extensions.tenant-id : data.ibm_resource_instance.brs-instance[0].extensions.tenant-id
  tenant_id = "${local.tenant_id_raw}/"
}

resource "ibm_resource_instance" "brs-instance" {
  count             = var.create_new_instance ? 1 : 0
  name              = var.instance_name
  service           = var.name
  plan              = var.plan
  location          = var.region
  resource_group_id = var.resource_group_id
  parameters_json   = <<EOF
{
  "custom-prov-code": "${var.provision_code}"
}
EOF

  //User can increase timeouts
  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
data "ibm_resource_instance" "brs-instance" {
  count             = var.create_new_instance ? 0 : 1
  name              = var.instance_name
  location          = var.region
  resource_group_id = var.resource_group_id
  service           = var.name
}

# data_source_connection
data "ibm_backup_recovery_data_source_connections" "connections" {
  count            = var.create_new_connection ? 0 : 1
  x_ibm_tenant_id  = local.tenant_id
  connection_names = [var.connection_name]
}

resource "ibm_backup_recovery_data_source_connection" "connection" {
  count           = var.create_new_connection ? 1 : 0
  x_ibm_tenant_id = local.tenant_id
  connection_name = var.connection_name
  endpoint_type   = var.endpoint_type # default public
  instance_id     = var.create_new_instance ? ibm_resource_instance.brs-instance[0].guid : data.ibm_resource_instance.brs-instance[0].guid
  region          = var.region
}

resource "ibm_backup_recovery_connection_registration_token" "registration_token" {
  connection_id   = var.create_new_connection ? ibm_backup_recovery_data_source_connection.connection[0].connection_id : data.ibm_backup_recovery_data_source_connections.connections[0].connections[0].connection_id
  x_ibm_tenant_id = local.tenant_id
}