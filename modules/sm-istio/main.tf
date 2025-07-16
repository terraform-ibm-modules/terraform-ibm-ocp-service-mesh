locals {
  istio_release_name = "${var.namespace}-${var.name}"
  istio_chart_path   = "istio"
}

# installing helm chart for istio deployment
resource "helm_release" "istio" {

  name             = local.istio_release_name
  chart            = "${path.module}/../../chart/${local.istio_chart_path}"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  # timeout           = "60"
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set {
    name  = "istioconfiguration.namespace"
    type  = "string"
    value = var.namespace
  }

  set {
    name  = "istioconfiguration.name"
    type  = "string"
    value = var.name
  }

  set {
    name  = "istioconfiguration.istiodiscovery"
    type  = "string"
    value = var.istiodiscovery
  }

  set {
    name  = "istioconfiguration.outboundtrafficpolicy"
    type  = "string"
    value = var.outboundtrafficpolicy
  }

  set {
    name  = "istioconfiguration.enablemtls"
    type  = "string"
    value = var.enable_mtls ? "true" : "false"
  }


}
