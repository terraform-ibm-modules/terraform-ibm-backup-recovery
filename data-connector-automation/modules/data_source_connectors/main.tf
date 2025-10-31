resource "helm_release" "dsc-chart" {
  name             = var.release_name
  chart            = var.chart_name
  repository       = var.chart_repository
  namespace        = var.namespace
  create_namespace = var.create_namespace
  # atomic           = var.atomic
  version = var.chart_version
  values = [
    yamlencode({
      secrets = {
        registrationToken = var.registration_token
      }
      image = {
        namespace  = var.image.namespace
        repository = var.image.repository
        tag        = var.image.tag
        pullPolicy = var.image.pullPolicy
      }
      replicaCount     = var.replica_count
      fullnameOverride = var.release_name
    })
  ]
  timeout = var.timeout
}