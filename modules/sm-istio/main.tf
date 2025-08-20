locals {
  istio_release_name = "${var.namespace}-${var.name}"
  istio_chart_path   = "istio"

  # istio_discovery_configuration = {
  #   "istioconfiguration": {
  #     "meshConfig": {
  #       "discoverySelectors": [
  #         {"matchLabels": {"istio-discovery": "enabled", "app": "test"}},
  #         {"matchExpressions": [
  #           {key: "app", operator: "In", values: ["test1", "test2"]}
  #         ]}
  #       ]
  #     }
  #   }
  # }

  istio_discovery_configuration = var.istio_discovery_configuration == null ? {} : {
    "istioconfiguration" : {
      "meshConfig" : {
        "discoverySelectors" : [var.istio_discovery_configuration.matchLabels != null ? { "matchLabels" : var.istio_discovery_configuration.matchLabels } : null, var.istio_discovery_configuration.matchExpressions != null ? { "matchExpressions" : var.istio_discovery_configuration.matchExpressions } : null]
      }
    }
  }
  # istio_discovery_configuration = var.istio_discovery_configuration == null ? {} : {
  #   "istioconfiguration": {
  #     "meshConfig": {
  #       "discoverySelectors": var.istio_discovery_configuration
  #     }
  #   }
  # }
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
    name  = "istioconfiguration.outboundtrafficpolicy"
    type  = "string"
    value = var.outboundtrafficpolicy
  }

  set {
    name  = "istioconfiguration.enablemtls"
    type  = "string"
    value = var.enable_mtls ? "true" : "false"
  }

  values = [yamlencode(local.istio_discovery_configuration)]

}
