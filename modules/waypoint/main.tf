locals {
  waypoint_release_name = "${var.namespace}-${var.gateway_name}"
  waypoint_chart_path   = "waypoint"



  tolerations = length(var.tolerations) == 0 ? {} : {
    "configMap" : {
      "deployment" : {
        "tolerations" : var.tolerations
      }
    }
  }

  affinity = var.affinity == null ? {} : {
    "configMap" : {
      "deployment" : {
        "affinity" : var.affinity
      }
    }
  }

  resources_configuration = var.resources_configuration == null ? {} : {
    "configMap" : {
      "deployment" : {
        "resources" : var.resources_configuration
      }
    }
  }

  gateway_labels = length(var.gateway_labels) == 0 ? {} : {
    "gateway" : {
      "labels" : var.gateway_labels
    }
  }

  gateway_annotations = length(var.gateway_annotations) == 0 ? {} : {
    "gateway" : {
      "annotations" : var.gateway_annotations
    }
  }
}

# installing helm chart for waypoint deployment
resource "helm_release" "waypoint" {

  name              = local.waypoint_release_name
  chart             = "${path.module}/../../chart/${local.waypoint_chart_path}"
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
      name  = "namespace"
      type  = "string"
      value = var.namespace
    },
    {
      name  = "configMap.name"
      type  = "string"
      value = var.configmap_name
    },
    {
      name  = "gateway.name"
      type  = "string"
      value = var.gateway_name
    },
    {
      name  = "gateway.waypointFor"
      type  = "string"
      value = var.waypoint_for
    },
    {
      name  = "gateway.allowedRoutes"
      type  = "string"
      value = var.allowed_routes
    },
    {
      name  = "configMap.deployment.replicas"
      type  = "string"
      value = var.replicas
    },
  ]

  values = [
    yamlencode(local.tolerations),
    yamlencode(local.affinity),
    yamlencode(local.resources_configuration),
    yamlencode(local.gateway_labels),
    yamlencode(local.gateway_annotations),
  ]

}
