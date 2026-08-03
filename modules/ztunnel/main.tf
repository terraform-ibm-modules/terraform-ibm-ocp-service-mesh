locals {
  ztunnel_release_name = "${var.namespace}-default"
  ztunnel_chart_path   = "ztunnel"

  ztunnel_resources_configuration = var.ztunnel_resources_configuration == null ? {} : {
    "ztunnel" : {
      "resources" : var.ztunnel_resources_configuration
    }
  }

  ztunnel_tolerations_configuration = length(var.tolerations) == 0 ? {} : {
    "ztunnel" : {
      "tolerations" : var.tolerations
    }
  }
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

  values = [
    yamlencode(local.ztunnel_resources_configuration),
    yamlencode(local.ztunnel_tolerations_configuration)
  ]

}
