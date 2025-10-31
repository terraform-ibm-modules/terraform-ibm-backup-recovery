# provider.tf
terraform {
  required_version = ">= 1.12.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.85.0-beta0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.0"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}


# Data source for IKS cluster kubeconfig
data "ibm_container_cluster_config" "iks_cluster_config" {
  cluster_name_id = module.iks_cluster.cluster_id
  admin           = true
}

# Data source for ROKS cluster kubeconfig
data "ibm_container_cluster_config" "roks_cluster_config" {
  cluster_name_id = module.roks_cluster.cluster_id
  admin           = true
}

# Kubernetes provider for IKS cluster
provider "kubernetes" {
  alias                  = "iks"
  host                   = data.ibm_container_cluster_config.iks_cluster_config.host
  client_certificate     = data.ibm_container_cluster_config.iks_cluster_config.admin_certificate
  client_key             = data.ibm_container_cluster_config.iks_cluster_config.admin_key
  cluster_ca_certificate = data.ibm_container_cluster_config.iks_cluster_config.ca_certificate
}

# Helm provider for IKS cluster
provider "helm" {
  alias = "iks"
  kubernetes = {
    host                   = data.ibm_container_cluster_config.iks_cluster_config.host
    client_certificate     = data.ibm_container_cluster_config.iks_cluster_config.admin_certificate
    client_key             = data.ibm_container_cluster_config.iks_cluster_config.admin_key
    cluster_ca_certificate = data.ibm_container_cluster_config.iks_cluster_config.ca_certificate
  }
  registries = var.registry_creds
}

# Kubernetes provider for ROKS cluster
provider "kubernetes" {
  alias                  = "roks"
  host                   = data.ibm_container_cluster_config.roks_cluster_config.host
  client_certificate     = data.ibm_container_cluster_config.roks_cluster_config.admin_certificate
  client_key             = data.ibm_container_cluster_config.roks_cluster_config.admin_key
  cluster_ca_certificate = data.ibm_container_cluster_config.roks_cluster_config.ca_certificate
}

# Helm provider for ROKS cluster
provider "helm" {
  alias = "roks"
  kubernetes = {
    host                   = data.ibm_container_cluster_config.roks_cluster_config.host
    client_certificate     = data.ibm_container_cluster_config.roks_cluster_config.admin_certificate
    client_key             = data.ibm_container_cluster_config.roks_cluster_config.admin_key
    cluster_ca_certificate = data.ibm_container_cluster_config.roks_cluster_config.ca_certificate
  }
  # registries = var.registry_creds
}