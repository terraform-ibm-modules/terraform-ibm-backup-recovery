# IKS Cluster Module
module "iks_cluster" {
  source            = "./modules/iks_cluster"
  create_new        = var.iks_cluster.create_new
  cluster_name      = var.iks_cluster.name
  vpc_id            = module.network.vpc.vpc_id
  subnet_ids        = [for subnet in local.subnet_list : subnet.id]
  resource_group_id = module.resource_group.resource_group_id
  flavor            = var.iks_cluster.machine_type
  worker_count      = var.iks_cluster.workers_per_zone
  kube_version      = var.iks_cluster.iks_version != null ? var.iks_cluster.iks_version : null
  zones             = [for subnet in local.subnet_list : subnet.zone]
  depends_on        = [module.network]
}
data "ibm_is_security_group" "iks" {
  name = "kube-${module.iks_cluster.cluster_id}"
}
module "cdsc_sg_rule_iks" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "v2.8.0"
  resource_group               = module.resource_group.resource_group_name
  existing_security_group_name = "kube-${module.iks_cluster.cluster_id}"
  use_existing_security_group  = true
  security_group_rules = [
    {
      name      = "allow-outbound-443-from-cdsc-to-brs-dataplane"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_max = 443
        port_min = 443
      }
    },
    {
      name      = "allow-outbound-29991-from-cdsc-to-brs-dataplane"
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
      remote    = data.ibm_is_security_group.iks.id
      tcp = {
        port_max = 3000
        port_min = 3000
      }
    }
  ]
}
module "connection_iks" {
  source          = "./modules/data_source_connection"
  tenant_id       = local.tenant_id
  connection_name = var.iks_cluster.connection.connection_name
  depends_on      = [module.brs_instance]
  create_new      = var.iks_cluster.connection.create_new
  endpoint_type   = var.iks_cluster.connection.endpoint_type
  instance_id     = module.brs_instance.instance.guid
  region          = var.brs_service.region
}
module "dsc_iks" {
  source = "./modules/data_source_connectors"
  providers = {
    helm = helm.iks
  }
  release_name       = var.iks_cluster.protection.connector.release_name
  chart_name         = var.iks_cluster.protection.connector.chart_name
  chart_repository   = var.iks_cluster.protection.connector.chart_repository
  namespace          = var.iks_cluster.protection.connector.namespace
  create_namespace   = var.iks_cluster.protection.connector.create_namespace
  chart_version      = var.iks_cluster.protection.connector.chart_version
  image              = var.iks_cluster.protection.connector.image
  registration_token = module.connection_iks.registration_token
  replica_count      = var.iks_cluster.protection.connector.replica_count
  timeout            = var.iks_cluster.protection.connector.timeout
  depends_on = [
    module.iks_cluster,
    module.cdsc_sg_rule_iks
  ]
}
# Protectcluster module for IKS cluster
module "protectcluster_iks" {
  source = "./modules/protectcluster"
  providers = {
    kubernetes = kubernetes.iks
    helm       = helm.iks
  }
  tenant_id     = local.tenant_id
  connection_id = module.connection_iks.connection_id
  registration = {
    name = var.iks_cluster.protection.source_name
    cluster = {
      id                = module.iks_cluster.cluster_id
      resource_group_id = module.resource_group.resource_group_id
      endpoint          = module.iks_cluster.private_service_endpoint_url
      distribution      = "kIKS"
      images            = var.iks_cluster.protection.images
    }
  }
  policy = {
    name = var.iks_cluster.protection.policy_name
  }
  depends_on = [
    module.brs_instance,
    module.connection_iks,
    module.iks_cluster,
    module.cdsc_sg_rule_iks,
    module.dsc_iks
  ]
}