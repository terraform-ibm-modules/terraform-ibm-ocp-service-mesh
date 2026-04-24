locals {
  istiocni_name         = "default" # istio-cni name cannot be different than
  istiocni_release_name = "${var.namespace}-${local.istiocni_name}"
  istiocni_chart_path   = "istiocni"
}

# installing helm chart for istio-cni deployment
resource "helm_release" "istiocni" {

  name             = local.istiocni_release_name
  chart            = "${path.module}/../../chart/${local.istiocni_chart_path}"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  # timeout           = "60"
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  atomic            = var.rollback_on_failure
  wait              = true

  disable_openapi_validation = false

  set = [
    {
      name  = "istiocniconfiguration.namespace"
      type  = "string"
      value = var.namespace
      }, {
      name  = "istiocniconfiguration.name"
      type  = "string"
      value = local.istiocni_name
    }
  ]

}
