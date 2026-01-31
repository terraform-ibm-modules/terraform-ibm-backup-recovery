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

module "brs" {
  source            = "terraform-ibm-modules/backup-recovery/ibm"
  version           = "v1.3.0"
  resource_group_id = module.resource_group.resource_group_id
  instance_name     = "${var.prefix}-instance"
  connection_name   = "${var.prefix}-instance"
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  tags              = var.resource_tags
}
