########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.7"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# Backup & Recovery Service (BRS) Module
########################################################################################################################

resource "ibm_resource_instance" "backup_recovery_instance" {
  name              = "${var.prefix}-instance"
  service           = "backup-recovery"
  plan              = "premium"
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags
}

resource "terraform_data" "policy_cleanup" {
  count = 1

  input = {
    url           = ibm_resource_instance.backup_recovery_instance.extensions["endpoints.public"]
    tenant        = "${ibm_resource_instance.backup_recovery_instance.extensions["tenant-id"]}/"
    endpoint_type = "public"
    api_key       = sensitive(var.ibmcloud_api_key)
  }

  lifecycle {
    replace_triggered_by = [
      ibm_resource_instance.backup_recovery_instance
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
