
locals {
  backup_recovery_instance            = var.create_new_instance ? ibm_resource_instance.backup_recovery_instance[0] : data.ibm_resource_instance.backup_recovery_instance[0]
  tenant_id                           = "${local.backup_recovery_instance.extensions.tenant-id}/"
  backup_recovery_instance_public_url = local.backup_recovery_instance.extensions["endpoints.public"]
}

resource "ibm_resource_instance" "backup_recovery_instance" {
  count             = var.create_new_instance ? 1 : 0
  name              = var.instance_name
  service           = "backup-recovery"
  plan              = var.plan
  location          = var.region
  resource_group_id = var.resource_group_id
  tags              = var.tags
  # Support for KMS encryption has not yet been released.
  # parameters_json = var.kms_key_crn != null ? jsonencode({
  #   "kms-root-key-crn" = var.kms_key_crn
  # }) : null
}

# Script to remove all associated policies before deleting the instance.
resource "terraform_data" "delete_policies" {
  count = var.create_new_instance ? 1 : 0
  input = {
    url           = local.backup_recovery_instance_public_url
    tenant        = local.tenant_id
    endpoint_type = var.endpoint_type
  }
  # api key in triggers_replace to avoid it to be printed out in clear text in terraform_data output
  triggers_replace = {
    api_key = var.ibmcloud_api_key
  }
  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/scripts/delete_policies.sh ${self.input.url} ${self.input.tenant} ${self.input.endpoint_type}"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      API_KEY = self.triggers_replace.api_key
    }
  }
}

data "ibm_resource_instance" "backup_recovery_instance" {
  count             = var.create_new_instance ? 0 : 1
  name              = var.instance_name
  location          = var.region
  resource_group_id = var.resource_group_id
  service           = "backup-recovery"
}

# data_source_connection
data "ibm_backup_recovery_data_source_connections" "connections" {
  count            = var.create_new_connection ? 0 : 1
  x_ibm_tenant_id  = local.tenant_id
  connection_names = [var.connection_name]
  endpoint_type    = var.endpoint_type
  instance_id      = local.backup_recovery_instance.guid
  region           = var.region
}

resource "ibm_backup_recovery_data_source_connection" "connection" {
  count           = var.create_new_connection ? 1 : 0
  x_ibm_tenant_id = local.tenant_id
  connection_name = var.connection_name
  endpoint_type   = var.endpoint_type
  instance_id     = local.backup_recovery_instance.guid
  region          = var.region
}

# there is a bug in the ibm_backup_recovery_connection_registration_token so currently using ibm_backup_recovery_data_source_connection.connection[0].registration_token
# once this bug is resolved we can force create new ibm_backup_recovery_connection_registration_token as token expires every 24 hours.
# resource "ibm_backup_recovery_connection_registration_token" "registration_token" {
#   connection_id   = local.backup_recovery_connection.connection_id
#   x_ibm_tenant_id = local.tenant_id
#   endpoint_type   = var.endpoint_type
#   instance_id     = local.backup_recovery_instance.guid
#   region          = var.region
# }
