
locals {
  # Determine whether to create new resources or use existing ones
  create_new_instance                  = var.brs_instance_crn == null || var.brs_instance_crn == ""
  brs_instance_guid                    = local.create_new_instance ? null : module.crn_parser[0].service_instance
  brs_instance_region                  = local.create_new_instance ? var.region : module.crn_parser[0].region
  backup_recovery_instance             = local.create_new_instance ? ibm_resource_instance.backup_recovery_instance[0] : data.ibm_resource_instance.backup_recovery_instance[0]
  backup_recovery_connection           = var.connection_name == null ? null : (var.create_new_connection ? ibm_backup_recovery_data_source_connection.connection[0] : data.ibm_backup_recovery_data_source_connections.connections[0].connections[0])
  tenant_id                            = "${local.backup_recovery_instance.extensions.tenant-id}/"
  backup_recovery_instance_public_url  = local.backup_recovery_instance.extensions["endpoints.public"]
  backup_recovery_instance_private_url = local.backup_recovery_instance.extensions["endpoints.private"]
}

module "crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.4.1"
  count   = local.create_new_instance ? 0 : 1
  crn     = var.brs_instance_crn
}

resource "ibm_resource_instance" "backup_recovery_instance" {
  count             = local.create_new_instance ? 1 : 0
  name              = var.instance_name
  service           = "backup-recovery"
  plan              = var.plan
  location          = local.brs_instance_region
  resource_group_id = var.resource_group_id
  tags              = var.tags
}

# When an instance is created, it comes with a few default policies. If these policies are not deleted before
# attempting to delete the instance, the deletion will fail. This is the expected default behavior — even when
# an instance is created through the UI, it cannot be deleted until its associated policies are removed first.
resource "terraform_data" "delete_policies" {
  count = local.create_new_instance ? 1 : 0

  input = {
    url           = var.endpoint_type == "public" ? local.backup_recovery_instance_public_url : local.backup_recovery_instance_private_url
    tenant        = local.tenant_id
    endpoint_type = var.endpoint_type
    api_key       = sensitive(var.ibmcloud_api_key)
  }

  lifecycle {
    replace_triggered_by = [
      ibm_resource_instance.backup_recovery_instance[0]
    ]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/scripts/delete_policies.sh ${self.input.url} ${self.input.tenant} ${self.input.endpoint_type}"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      API_KEY = self.input.api_key
    }
  }
}

# Data source to retrieve the existing instance details if create_new_instance is false.
# This is used when a BRS instance CRN is provided.
data "ibm_resource_instance" "backup_recovery_instance" {
  count      = local.create_new_instance ? 0 : 1
  identifier = local.brs_instance_guid
}

# data_source_connection
data "ibm_backup_recovery_data_source_connections" "connections" {
  count            = var.connection_name != null && !var.create_new_connection ? 1 : 0
  x_ibm_tenant_id  = local.tenant_id
  connection_names = [var.connection_name]
  endpoint_type    = var.endpoint_type
  instance_id      = local.backup_recovery_instance.guid
  region           = local.brs_instance_region
}

resource "ibm_backup_recovery_data_source_connection" "connection" {
  count           = var.connection_name != null && var.create_new_connection ? 1 : 0
  x_ibm_tenant_id = local.tenant_id
  connection_name = var.connection_name
  endpoint_type   = var.endpoint_type
  instance_id     = local.backup_recovery_instance.guid
  region          = local.brs_instance_region
}

resource "time_rotating" "token_rotation" {
  rotation_days = 1
}

moved {
  from = ibm_backup_recovery_connection_registration_token.registration_token
  to   = ibm_backup_recovery_connection_registration_token.registration_token[0]
}
resource "ibm_backup_recovery_connection_registration_token" "registration_token" {
  count           = var.connection_name != null ? 1 : 0
  connection_id   = local.backup_recovery_connection.connection_id
  x_ibm_tenant_id = local.tenant_id
  endpoint_type   = var.endpoint_type
  instance_id     = local.backup_recovery_instance.guid
  region          = local.brs_instance_region

  # This forces a replacement every time the time_rotating resource rotates
  lifecycle {
    replace_triggered_by = [
      time_rotating.token_rotation
    ]
  }
}
