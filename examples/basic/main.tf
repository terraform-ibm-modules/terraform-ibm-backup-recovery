########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# Backup & Recovery Service (BRS) Module
########################################################################################################################

module "brs" {
  source                    = "../.."
  resource_group_id         = module.resource_group.resource_group_id
  instance_name             = "${var.prefix}-instance"
  connection_name           = "${var.prefix}-instance"
  region                    = var.existing_brs_instance_crn == null ? var.region : element(split(":", var.existing_brs_instance_crn), 5)
  ibmcloud_api_key          = var.ibmcloud_api_key
  resource_tags             = var.resource_tags
  access_tags               = var.access_tags
  existing_brs_instance_crn = var.existing_brs_instance_crn
  connection_env_type       = var.connection_env_type
  service_endpoints         = var.service_endpoints
  service_type              = var.service_type
  parameters_json           = var.parameters_json
  policies = [{
    name                      = "${var.prefix}-policy"
    create_new_policy         = true
    use_default_backup_target = true
    schedule = {
      unit = "Hours"
      hour_schedule = {
        frequency = 6
      }
    }
    retention = {
      duration = 4
      unit     = "Weeks"
    }
  }]
}
