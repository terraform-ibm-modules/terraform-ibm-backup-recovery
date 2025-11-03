########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source = "terraform-ibm-modules/resource-group/ibm"
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
  instance_name         = var.instance_name
  connection_name       = var.connection_name
  region                = var.region
  provision_code        = var.provision_code

  # === Optional Overrides (defaults from module) ===
  name                  = "backup-recovery"
  plan                  = "premium"
  endpoint_type         = "public"

  timeouts = {
    create = "90m"
    update = "30m"
    delete = "30m"
  }

  # Ensure resource group exists first
  depends_on = [module.resource_group]
}