
# brs_instance
locals {
  backup_recovery_instance     = var.create_new_instance ? ibm_resource_instance.backup_recovery_instance[0] : data.ibm_resource_instance.backup_recovery_instance[0]
  backup_recovery_connection   = var.create_new_connection ? ibm_backup_recovery_data_source_connection.connection[0] : data.ibm_backup_recovery_data_source_connections.connections[0].connections[0]
  tenant_id     = "${local.backup_recovery_instance.extensions.tenant-id}/"
  backup_recovery_instance_public_url = "${local.backup_recovery_instance.extensions["endpoints.public"]}"
}

resource "ibm_resource_instance" "backup_recovery_instance" {
  count             = var.create_new_instance ? 1 : 0
  name              = var.instance_name
  service           = "backup-recovery"
  plan              = var.plan
  location          = var.region
  resource_group_id = var.resource_group_id
  parameters_json = var.kms_root_key_crn != "" ? jsonencode({
    "kms-root-key-crn" = var.kms_root_key_crn
  }) : null

  timeouts {
    create = "60m"
    update = "30m"
    delete = "30m"
  }
}

resource "null_resource" "policy_cleanup_before_destroy" {
  count = var.create_new_instance ? 1 : 0

  triggers = {
    url     = local.backup_recovery_instance_public_url
    tenant  = local.tenant_id
    api_key = var.ibmcloud_api_key
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      #!/bin/bash
      set -euo pipefail

      URL="${self.triggers.url}"
      TENANT="${self.triggers.tenant}"
      API_KEY="${self.triggers.api_key}"

      # ---- Get IAM token -------------------------------------------------
      TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
        -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$API_KEY" \
        -H "Content-Type: application/x-www-form-urlencoded" | jq -r .access_token)

      # ---- List policies -------------------------------------------------
      curl -s \
        -H "Authorization: Bearer $TOKEN" \
        -H "X-IBM-Tenant-Id: $TENANT" \
        "https://$URL/v2/data-protect/policies" |
        jq -r '.policies[].id' |
        while read -r id; do
          echo "Deleting $id ..."
          curl -s -X DELETE -o /dev/null \
            -H "Authorization: Bearer $TOKEN" \
            -H "X-IBM-Tenant-Id: $TENANT" \
            "https://$URL/v2/data-protect/policies/$id" && echo "OK"
        done
    EOT

    interpreter = ["bash", "-c"]
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
  endpoint_type   = var.endpoint_type
  instance_id     = local.backup_recovery_instance.guid
  region          = var.region
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