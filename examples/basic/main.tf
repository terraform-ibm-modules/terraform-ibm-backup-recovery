########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.0"
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
  instance_name             = "${var.prefix}-instance"
  connection_name           = "${var.prefix}-instance"
  region                    = var.existing_brs_instance_crn == null ? var.region : element(split(":", var.existing_brs_instance_crn), 5)
  ibmcloud_api_key          = var.ibmcloud_api_key
  resource_tags             = var.resource_tags
  access_tags               = var.access_tags
  existing_brs_instance_crn = var.existing_brs_instance_crn
  connection_env_type       = var.connection_env_type
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
    # See, https://github.com/IBM-Cloud/terraform-provider-ibm/issues/6738
    # blackout_window = [{
    #   day = "Sunday"
    #   start_time = {
    #     hour      = 2
    #     minute    = 0
    #   }
    #   end_time = {
    #     hour      = 6
    #     minute    = 0
    #   }
    # }]
  }]
}
