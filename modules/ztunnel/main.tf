locals {
  ztunnel_release_name = "${var.namespace}-default"
  ztunnel_chart_path   = "ztunnel"
}

# installing helm chart for ztunnel deployment
resource "helm_release" "ztunnel" {

  name              = local.ztunnel_release_name
  chart             = "${path.module}/../../chart/${local.ztunnel_chart_path}"
  namespace         = var.namespace
  create_namespace  = false
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  atomic            = var.rollback_on_failure
  wait              = true

  disable_openapi_validation = false

  set = [
    {
      name  = "ztunnel.namespace"
      type  = "string"
      value = var.namespace
    }
  ]

}
