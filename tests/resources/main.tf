##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.7"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}


module "backup_recovery_instance" {
  source                = "../.."
  region                = var.region
  resource_group_id     = module.resource_group.resource_group_id
  ibmcloud_api_key      = var.ibmcloud_api_key
  tags                  = var.resource_tags
  instance_name         = "${var.prefix}-brs-instance"
  connection_name       = "${var.prefix}-brs-connection"
  create_new_connection = false
}
