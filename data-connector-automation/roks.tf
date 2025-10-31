# OpenShift (ROKS) Cluster Module
module "roks_cluster" {
  source                              = "./modules/roks_cluster"
  create_new                          = var.roks_cluster.create_new
  cluster_name                        = var.roks_cluster.name
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  force_delete_storage                = true
  vpc_id                              = module.network.vpc.vpc_id
  vpc_subnets                         = local.vpc_subnets
  ocp_version                         = var.roks_cluster.ocp_version
  disable_outbound_traffic_protection = false
  subnet_prefix                       = "default"
  pool_name                           = var.roks_cluster.pool_name
  machine_type                        = var.roks_cluster.machine_type
  workers_per_zone                    = var.roks_cluster.workers_per_zone
  operating_system                    = var.roks_cluster.operating_system
  depends_on                          = [module.network]
}

# Data source for the ROKS cluster's default security group
data "ibm_is_security_group" "roks" {
  name       = "kube-${module.roks_cluster.cluster_id}"
  depends_on = [module.roks_cluster]
}
module "cdsc_sg_rule_roks" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "v2.8.0"
  resource_group               = module.resource_group.resource_group_name
  existing_security_group_name = "kube-${module.roks_cluster.cluster_id}"
  use_existing_security_group  = true
  security_group_rules = [
    {
      name      = "allow-outbound-443-from-cdsc-to-brs-dataplace"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_max = 443
        port_min = 443
      }
    },
    {
      name      = "allow-outbound-29991-from-cdsc-to-brs-dataplace"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_max = 29991
        port_min = 29991
      }
    },
    {
      name      = "allow-outbound-50001-from-cdsc-to-brs-dataplane"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_max = 50001
        port_min = 50001
      }
    },
    {
      name      = "allow-inbound-3000-from-kube-cluster"
      direction = "inbound"
      remote    = data.ibm_is_security_group.roks.id
      tcp = {
        port_max = 3000
        port_min = 3000
      }
    }
  ]
}
module "connection_roks" {
  source          = "./modules/data_source_connection"
  tenant_id       = local.tenant_id
  connection_name = var.roks_cluster.connection.connection_name
  depends_on      = [module.brs_instance]
  create_new      = var.roks_cluster.connection.create_new
  endpoint_type   = var.roks_cluster.connection.endpoint_type
  instance_id     = module.brs_instance.instance.guid
  region          = var.brs_service.region
}
module "dsc_roks" {
  source = "./modules/data_source_connectors"
  providers = {
    helm = helm.roks
  }
  release_name       = var.roks_cluster.protection.connector.release_name
  chart_name         = var.roks_cluster.protection.connector.chart_name
  chart_repository   = var.roks_cluster.protection.connector.chart_repository
  namespace          = var.roks_cluster.protection.connector.namespace
  create_namespace   = var.roks_cluster.protection.connector.create_namespace
  chart_version      = var.roks_cluster.protection.connector.chart_version
  image              = var.roks_cluster.protection.connector.image
  registration_token = module.connection_roks.registration_token
  replica_count      = var.roks_cluster.protection.connector.replica_count
  timeout            = var.roks_cluster.protection.connector.timeout
  depends_on = [
    module.roks_cluster,
    module.cdsc_sg_rule_roks
  ]
}
# Protectcluster module for ROKS cluster
module "protectcluster_roks" {
  source = "./modules/protectcluster"
  providers = {
    kubernetes = kubernetes.roks
    helm       = helm.roks
  }
  tenant_id     = local.tenant_id
  connection_id = module.connection_roks.connection_id
  registration = {
    name = var.roks_cluster.protection.source_name
    cluster = {
      id                = module.roks_cluster.cluster_id
      resource_group_id = module.resource_group.resource_group_id
      endpoint          = module.roks_cluster.private_service_endpoint_url
      distribution      = "kROKS"
      images            = var.roks_cluster.protection.images
    }
  }
  policy = {
    name = var.roks_cluster.protection.policy_name
  }
  depends_on = [
    module.brs_instance,
    module.connection_roks,
    module.roks_cluster,
    module.dsc_roks
  ]
}