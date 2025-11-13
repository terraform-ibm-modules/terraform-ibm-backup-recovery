########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create Key Protect resources
##############################################################################

locals {
  key_ring_name = "brs-key-ring"
  key_name      = "brs-key"
}

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                   = "5.4.10"
  key_protect_instance_name = "${var.prefix}-kp"
  resource_group_id         = module.resource_group.resource_group_id
  enable_metrics            = false
  region                    = var.region
  keys = [
    {
      key_ring_name = (local.key_ring_name)
      keys = [
        {
          key_name = (local.key_name)
        }
      ]
    }
  ]
  resource_tags = var.resource_tags
}

########################################################################################################################
# Backup & Recovery Service (BRS) Module
########################################################################################################################

module "brs" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source            = "terraform-ibm-modules/backup-recovery/ibm"
  # version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  resource_group_id = module.resource_group.resource_group_id
  instance_name     = "${var.prefix}-instance"
  connection_name   = "${var.prefix}-instance"
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  tags              = var.resource_tags
  kms_key_crn       = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].crn
}
