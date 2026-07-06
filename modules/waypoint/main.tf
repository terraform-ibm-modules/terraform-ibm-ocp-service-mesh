locals {
  waypoint_release_name = "${var.namespace}-${var.gateway_name}"
  waypoint_chart_path   = "waypoint"

  deployment_name = var.deployment_name != null && var.deployment_name != "" ? var.deployment_name : var.gateway_name
  service_name    = var.service_name != null && var.service_name != "" ? var.service_name : var.gateway_name

  deployment_labels = length(var.deployment_labels) == 0 ? {} : {
    "configMap" : {
      "deployment" : {
        "labels" : var.deployment_labels
      }
    }
  }

  deployment_annotations = length(var.deployment_annotations) == 0 ? {} : {
    "configMap" : {
      "deployment" : {
        "annotations" : var.deployment_annotations
      }
    }
  }

  waypoint_pod_labels = length(var.waypoint_pod_labels) == 0 ? {} : {
    "configMap" : {
      "deployment" : {
        "podLabels" : var.waypoint_pod_labels
      }
    }
  }

  waypoint_pod_annotations = length(var.waypoint_pod_annotations) == 0 ? {} : {
    "configMap" : {
      "deployment" : {
        "podAnnotations" : var.waypoint_pod_annotations
      }
    }
  }

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

  service_labels = length(var.service_labels) == 0 ? {} : {
    "configMap" : {
      "service" : {
        "labels" : var.service_labels
      }
    }
  }

  service_annotations = length(var.service_annotations) == 0 ? {} : {
    "configMap" : {
      "service" : {
        "annotations" : var.service_annotations
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
    {
      name  = "configMap.deployment.name"
      type  = "string"
      value = local.deployment_name
    },
    {
      name  = "configMap.service.name"
      type  = "string"
      value = local.service_name
    },
  ]

  values = [
    yamlencode(local.deployment_labels),
    yamlencode(local.deployment_annotations),
    yamlencode(local.waypoint_pod_labels),
    yamlencode(local.waypoint_pod_annotations),
    yamlencode(local.tolerations),
    yamlencode(local.affinity),
    yamlencode(local.resources_configuration),
    yamlencode(local.service_labels),
    yamlencode(local.service_annotations),
    yamlencode(local.gateway_labels),
    yamlencode(local.gateway_annotations),
  ]

}
