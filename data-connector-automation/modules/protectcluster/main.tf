

# Create a Kubernetes service account
resource "kubernetes_service_account" "brsagent" {
  metadata {
    name      = "brsagent"
    namespace = "default"
  }
}

# Create a cluster role binding for the service account
resource "kubernetes_cluster_role_binding" "brsagent_admin" {
  metadata {
    name = "brsagent-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.brsagent.metadata[0].name
    namespace = "default"
  }
}

# Create a secret to store the service account token
resource "kubernetes_secret" "brsagent_token" {
  metadata {
    name      = "brsagent-token"
    namespace = "default"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.brsagent.metadata[0].name
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

# Register the source with the extracted token
resource "ibm_backup_recovery_source_registration" "source_registration" {
  x_ibm_tenant_id = var.tenant_id
  environment     = "kKubernetes"
  connection_id   = var.connection_id
  name            = var.registration.name
  kubernetes_params {
    endpoint                               = var.registration.cluster.endpoint
    kubernetes_distribution                = var.registration.cluster.distribution
    data_mover_image_location              = var.registration.cluster.images.data_mover
    velero_image_location                  = var.registration.cluster.images.velero
    velero_aws_plugin_image_location       = var.registration.cluster.images.velero_aws_plugin
    velero_openshift_plugin_image_location = var.registration.cluster.images.velero_openshift_plugin
    init_container_image_location          = var.registration.cluster.images.init_container
    client_private_key                     = chomp(kubernetes_secret.brsagent_token.data["token"])
  }
  depends_on = [kubernetes_secret.brsagent_token]
}

# Define the backup policy
# Todo: need to generalise this mith hourly, daily, monthly, yearly schedule
resource "ibm_backup_recovery_protection_policy" "protection_policy" {
  x_ibm_tenant_id = var.tenant_id
  name            = var.policy.name
  backup_policy {
    regular {
      incremental {
        schedule {
          minute_schedule {
            frequency = 10
          }
          unit = "Minutes"
        }
      }
      retention {
        duration = 3
        unit     = "Weeks"
      }
      primary_backup_target {
        use_default_backup_target = true
      }
    }
  }
  retry_options {
    retries             = 1
    retry_interval_mins = 5
  }
}