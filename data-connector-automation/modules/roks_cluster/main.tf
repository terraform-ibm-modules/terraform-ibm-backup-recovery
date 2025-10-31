module "ocp_base" {
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "v3.67.5"
  count                               = var.create_new ? 1 : 0
  cluster_name                        = var.cluster_name
  resource_group_id                   = var.resource_group_id
  region                              = var.region
  force_delete_storage                = var.force_delete_storage
  vpc_id                              = var.vpc_id
  vpc_subnets                         = var.vpc_subnets
  ocp_version                         = var.ocp_version
  disable_outbound_traffic_protection = var.disable_outbound_traffic_protection
  worker_pools = [
    {
      subnet_prefix    = var.subnet_prefix
      pool_name        = var.pool_name
      machine_type     = var.machine_type
      workers_per_zone = var.workers_per_zone
      operating_system = var.operating_system
    }
  ]
}
data "ibm_container_vpc_cluster" "existing_cluster" {
  count             = var.create_new ? 0 : 1
  name              = var.cluster_name
  resource_group_id = var.resource_group_id
}
