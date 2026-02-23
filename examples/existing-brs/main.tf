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

########################################################################################################################
# Backup & Recovery Service (BRS) Module
########################################################################################################################

module "brs" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/backup-recovery/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id         = module.resource_group.resource_group_id
  existing_brs_instance_crn = var.existing_brs_instance_crn
  connection_name           = "${var.prefix}-connection"
  instance_name             = "${var.prefix}-instance"
  region                    = var.region
  ibmcloud_api_key          = var.ibmcloud_api_key
  resource_tags             = var.resource_tags
  connection_env_type       = "kIksVpc"
}
