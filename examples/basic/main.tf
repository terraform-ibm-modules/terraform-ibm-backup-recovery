########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.0"

  # If var.resource_group is null, create a new RG using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-rg" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# Backup & Recovery Service (BRS) Module
########################################################################################################################
#
# This calls your local BRS module (../..)
# To use from Terraform Registry, uncomment the source/version lines below
#
module "brs" {
  source = "../.."
  # source  = "terraform-ibm-modules/backup-recovery/ibm"
  # version = "1.0.0"  # Replace with actual release version

  # === Required Inputs ===
  resource_group_id     = module.resource_group.resource_group_id
  create_new_instance   = true
  create_new_connection = true
  instance_name         = "brs-instance-${var.region}"
  connection_name       = "brs-connection-${var.region}"
  region                = var.region
  ibmcloud_api_key      = var.ibmcloud_api_key
  # === Optional Overrides (defaults from module) ===
  plan          = "premium"
  endpoint_type = "public"
}