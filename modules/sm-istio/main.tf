locals {
  istio_release_name = "${var.namespace}-${var.name}"
  istio_chart_path   = "istio"

  istio_discovery_configuration = var.istio_discovery_configuration == null ? {} : {
    "istioconfiguration" : {
      "meshConfig" : {
        "discoverySelectors" : [var.istio_discovery_configuration.matchLabels != null ? { "matchLabels" : var.istio_discovery_configuration.matchLabels } : null, var.istio_discovery_configuration.matchExpressions != null ? { "matchExpressions" : var.istio_discovery_configuration.matchExpressions } : null]
      }
    }
  }

  istio_pilot_resources = var.pilot_resources == null ? {} : {
    "istioconfiguration" : {
      "pilot" : {
        "resources" : var.pilot_resources
      }
    }
  }

  istio_pilot_node_selector = var.pilot_node_selector == null ? {} : {
    "istioconfiguration" : {
      "pilot" : {
        "nodeselector" : var.pilot_node_selector
      }
    }
  }

  istio_pilot_affinity = var.pilot_affinity == null ? {} : {
    "istioconfiguration" : {
      "pilot" : {
        "affinity" : var.pilot_affinity
      }
    }
  }

  istio_pilot_tolerations = var.pilot_tolerations == null ? {} : {
    "istioconfiguration" : {
      "pilot" : {
        "tolerations" : var.pilot_tolerations
      }
    }
  }

  istio_mesh_config_keep_alive = var.mesh_config_tcp_keep_alive == null ? {} : {
    "istioconfiguration" : {
      "meshConfig" : {
        "tcpKeepalive" : var.mesh_config_tcp_keep_alive
      }
    }
  }

  istio_mesh_config_mesh_mtls = var.mesh_config_mesh_mtls == null ? {} : {
    "istioconfiguration" : {
      "meshConfig" : {
        "meshMTLS" : var.mesh_config_mesh_mtls
      }
    }
  }

  istio_mesh_config_mesh_tls_defaults = var.mesh_config_mesh_tls_defaults == null ? {} : {
    "istioconfiguration" : {
      "meshConfig" : {
        "tlsDefaults" : var.mesh_config_mesh_tls_defaults
      }
    }
  }
}

# installing helm chart for istio deployment
resource "helm_release" "istio" {

  name             = local.istio_release_name
  chart            = "${path.module}/../../chart/${local.istio_chart_path}"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  # timeout           = "60"
  dependency_update = true
  force_update      = var.force_controlplane_update
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set = concat([
    {
      name  = "istioconfiguration.pilot.enabled"
      type  = "string"
      value = var.pilot_enabled
      }, {
      name  = "istioconfiguration.pilot.replicacount"
      type  = "string"
      value = var.pilot_replicas
      }, {
      name  = "istioconfiguration.namespace"
      type  = "string"
      value = var.namespace
      }, {
      name  = "istioconfiguration.name"
      type  = "string"
      value = var.name
      }, {
      name  = "istioconfiguration.outboundtrafficpolicy"
      type  = "string"
      value = var.outboundtrafficpolicy
      }, {
      name  = "istioconfiguration.pilot.autoscale.enabled"
      type  = "string"
      value = var.pilot_autoscaling_enabled
      }, {
      name  = "istioconfiguration.pilot.autoscale.min"
      type  = "string"
      value = var.pilot_autoscaling_min_pods
      }, {
      name  = "istioconfiguration.pilot.autoscale.max"
      type  = "string"
      value = var.pilot_autoscaling_max_pods
      }, {
      name  = "istioconfiguration.pilot.autoscale.cpu.targetavgutil"
      type  = "string"
      value = var.pilot_autoscaling_target_cpu
      }, {
      name  = "istioconfiguration.pilot.autoscale.memory.targetavgutil"
      type  = "string"
      value = var.pilot_autoscaling_target_memory
      }, {
      name  = "istioconfiguration.meshConfig.enableAutoMTLS"
      type  = "string"
      value = var.mesh_config_enable_mtls
      }, {
      name  = "istioconfiguration.meshConfig.ingressSelector"
      type  = "string"
      value = var.mesh_config_ingress_selector != null ? var.mesh_config_ingress_selector : ""
      }, {
      name  = "istioconfiguration.meshConfig.ingressService"
      type  = "string"
      value = var.mesh_config_ingress_selector != null ? var.mesh_config_ingress_service : ""
      }, {
      name  = "istioconfiguration.meshConfig.ingressControllerMode"
      type  = "string"
      value = var.mesh_config_ingress_controller_mode != null ? var.mesh_config_ingress_controller_mode : ""
      }, {
      name  = "istioconfiguration.meshConfig.connectTimeout"
      type  = "string"
      value = var.mesh_config_ingress_controller_mode != null ? var.mesh_config_connect_timeout : ""
      }, {
      name  = "istioconfiguration.istioconfiguration.defaultpdb"
      type  = "string"
      value = var.istio_enable_default_pod_disruption_budget != null ? var.istio_enable_default_pod_disruption_budget : null
      }, {
      name  = "istioconfiguration.meshConfig.accessLogFile"
      type  = "string"
      value = var.mesh_config_access_log_file != null ? var.mesh_config_access_log_file : null
      }, {
      name  = "istioconfiguration.meshConfig.accessLogEncoding"
      type  = "string"
      value = var.mesh_config_access_log_encoding != null ? var.mesh_config_access_log_encoding : null
      }, {
      name  = "istioconfiguration.meshConfig.accessLogFormat"
      type  = "string"
      value = var.mesh_config_access_log_format != null && var.mesh_config_access_log_format != "" ? var.mesh_config_access_log_format : ""
    }
  ])

  values = [
    yamlencode(local.istio_discovery_configuration),
    yamlencode(local.istio_pilot_resources),
    yamlencode(local.istio_pilot_affinity),
    yamlencode(local.istio_pilot_tolerations),
    yamlencode(local.istio_mesh_config_keep_alive),
    yamlencode(local.istio_pilot_node_selector),
    yamlencode(local.istio_mesh_config_mesh_mtls),
    yamlencode(local.istio_mesh_config_mesh_tls_defaults),
  ]

}
