# Data source to fetch an existing VPE gateway when create_new is false
data "ibm_is_virtual_endpoint_gateway" "vpeg" {
  count = var.create_new ? 0 : 1
  name  = var.name
}

# Module to create a new VPE gateway when create_new is true
module "vpeg" {
  count              = var.create_new ? 1 : 0
  source             = "terraform-ibm-modules/vpe-gateway/ibm"
  version            = "v4.8.1"
  region             = var.region
  prefix             = "vpe"
  vpc_name           = var.vpc_name
  vpc_id             = var.vpc_id
  subnet_zone_list   = var.subnet_zone_list
  resource_group_id  = var.resource_group_id
  security_group_ids = var.security_group_ids
  cloud_service_by_crn = [
    {
      crn = var.cloud_service_crn
    }
  ]
  service_endpoints = var.service_endpoints
}