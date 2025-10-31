# main.tf
locals {
  subnet_zone_list = [
    for subnet in data.ibm_is_subnets.subnets.subnets : {
      cidr = subnet.ipv4_cidr_block
      crn  = subnet.crn
      id   = subnet.id
      name = subnet.name
      zone = subnet.zone
    }
  ]
  subnet_list = [for subnet in data.ibm_is_subnets.subnets.subnets : {
    cidr_block = subnet.ipv4_cidr_block
    id         = subnet.id
    zone       = subnet.zone
  }]
  vpc_subnets = {
    "default" = local.subnet_list
  }
  tenant_id = "${module.brs_instance.tenant_id}/"
}

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "v1.4.0"
  resource_group_name          = var.resource_group.create_new ? var.resource_group.name : null
  existing_resource_group_name = var.resource_group.create_new ? null : var.resource_group.name
}

module "network" {
  source                      = "terraform-ibm-modules/vpc/ibm"
  version                     = "v1.5.2"
  existing_vpc_name           = var.vpc.create_new ? null : var.vpc.name
  create_vpc                  = var.vpc.create_new
  vpc_name                    = var.vpc.name
  resource_group_id           = module.resource_group.resource_group_id
  locations                   = var.vpc.create_new ? ["${var.region}-1", "${var.region}-2", "${var.region}-3"] : []
  auto_assign_address_prefix  = var.vpc.auto_assign_address_prefix
  subnet_name_prefix          = "${var.vpc.prefix}-subnet"
  default_network_acl_name    = "${var.vpc.prefix}-nacl"
  default_routing_table_name  = "${var.vpc.prefix}-routing-table"
  default_security_group_name = "${var.vpc.prefix}-sg"
  create_gateway              = var.vpc.create_subnet_gateway
  public_gateway_name_prefix  = "${var.vpc.prefix}-pw"
  number_of_addresses         = 254
  depends_on                  = [module.resource_group]
}

data "ibm_is_vpc" "vpc" {
  name = var.vpc.name
}

data "ibm_is_subnets" "subnets" {
  vpc_name       = var.vpc.name
  resource_group = module.resource_group.resource_group_id
}

module "brs_instance" {
  source            = "./modules/brs_instance"
  instance_name     = var.brs_service.instance_name
  name              = var.brs_service.name
  provision_code    = var.brs_service.provision_code
  region            = var.brs_service.region
  resource_group_id = module.resource_group.resource_group_id
  depends_on        = [module.resource_group]
  create_new        = var.brs_service.create_new
}

module "vpeg" {
  source             = "./modules/vpeg"
  region             = var.region
  vpc_name           = var.vpc.name
  vpc_id             = module.network.vpc.vpc_id
  subnet_zone_list   = local.subnet_zone_list
  resource_group_id  = module.resource_group.resource_group_id
  security_group_ids = [module.network.vpc.vpc_default_security_group]
  cloud_service_crn  = module.brs_instance.instance.id
  service_endpoints  = var.brs_service.vpeg.service_endpoints
  create_new         = var.brs_service.vpeg.create_new
  name               = var.brs_service.vpeg.name
  depends_on         = [module.network, module.brs_instance]
}
