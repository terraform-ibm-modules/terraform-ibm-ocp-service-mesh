locals {

  prefix                    = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  istio_egress_release_name = "${var.namespace}-${var.name}"
  istio_egress_chart_path   = "istio-egress"

  egress_discovery_configuration = var.egress_discovery_custom_configuration != null ? var.egress_discovery_custom_configuration : (
    var.istio_mesh_enrollment == "default" ? {
      "istio-discovery" : "enabled",
      "istio-injection" : "enabled",
      } : {
      "istio-discovery" : var.istio_mesh_enrollment,
      "istio.io/rev" : var.istio_mesh_enrollment,
    }
  )

  egress_selectors = {
    "egress" : {
      "istioselectors" : var.egress_selectors
    }
  }

  egress_ports = {
    "egress" : {
      "ports" : var.egress_ports
    }
  }

  egress_autoscale_configuration = {
    "egress" : {
      "autoscale" : var.egress_autoscale_configuration
    }
  }

  egress_pdb_configuration = var.egress_pdb_configuration == null ? {} : {
    "egress" : {
      "pdb" : var.egress_pdb_configuration
    }
  }

  egress_resources_configuration = var.egress_resources_configuration == null ? {} : {
    "egress" : {
      "resources" : var.egress_resources_configuration
    }
  }

  egress_affinity = var.egress_affinity == null ? {} : {
    "egress" : {
      "affinity" : var.egress_affinity
    }
  }

  egress_tolerations = var.egress_tolerations == null ? {} : {
    "egress" : {
      "tolerations" : var.egress_tolerations
    }
  }

}

##############################################################################
# Init cluster config
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

module "egress_namespace" {
  count   = var.create_namespace ? 1 : 0
  source  = "terraform-ibm-modules/namespace/ibm"
  version = "v2.0.1"
  namespaces = [
    {
      name = var.namespace
      metadata = {
        labels      = local.egress_discovery_configuration
        annotations = local.egress_discovery_configuration
      }
    }
  ]
}

# installing helm chart for istio deployment
resource "helm_release" "istio_egress" {
  depends_on        = [module.egress_namespace[0]]
  name              = local.istio_egress_release_name
  chart             = "${path.module}/../../chart/${local.istio_egress_chart_path}"
  namespace         = var.namespace
  create_namespace  = false
  timeout           = var.istio_egress_deployment_timeout
  dependency_update = true
  force_update      = var.force_dataplane_update
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set = [
    {
      name  = "egress.name"
      type  = "string"
      value = "${local.prefix}${var.name}"
    },
    {
      name  = "egress.namespace"
      type  = "string"
      value = var.namespace
    },
    {
      name  = "egress.internalTrafficPolicy"
      type  = "string"
      value = var.egress_internal_traffic_policy
    },
    {
      name  = "egress.replicacount"
      type  = "string"
      value = var.egress_replicas
    },
    {
      name  = "egress.terminationGracePeriodSeconds"
      type  = "string"
      value = var.egress_termination_grace_period
    }
  ]

  values = [
    yamlencode(local.egress_selectors),
    yamlencode(local.egress_ports),
    yamlencode(local.egress_autoscale_configuration),
    yamlencode(local.egress_pdb_configuration),
    yamlencode(local.egress_resources_configuration),
    yamlencode(local.egress_affinity),
    yamlencode(local.egress_tolerations),
  ]

}

resource "null_resource" "confirm_egress_operational" {
  depends_on = [helm_release.istio_egress]
  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-egress-operational.sh \"${var.namespace}\" \"${local.prefix}${var.name}\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
