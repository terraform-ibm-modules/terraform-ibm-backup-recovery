########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.8"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.4.2"
  count   = local.create_new_instance ? 0 : 1
  crn     = var.existing_brs_instance_crn
}

########################################################################################################################
# Backup & Recovery Service (BRS) Module
########################################################################################################################

locals {
  create_new_instance = var.existing_brs_instance_crn == null
  brs_instance        = local.create_new_instance ? ibm_resource_instance.backup_recovery_instance[0] : data.ibm_resource_instance.backup_recovery_instance[0]
}

resource "ibm_resource_instance" "backup_recovery_instance" {
  count             = local.create_new_instance ? 1 : 0
  name              = "${var.prefix}-instance"
  service           = "backup-recovery"
  plan              = "premium"
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags
}

data "ibm_resource_instance" "backup_recovery_instance" {
  count      = local.create_new_instance ? 0 : 1
  identifier = module.crn_parser[0].service_instance
}

resource "terraform_data" "policy_cleanup" {
  count = local.create_new_instance ? 1 : 0
  input = {
    url           = local.brs_instance.extensions["endpoints.public"]
    tenant        = "${local.brs_instance.extensions["tenant-id"]}/"
    endpoint_type = "public"
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
