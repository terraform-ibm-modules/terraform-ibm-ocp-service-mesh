locals {
  istio_ingress_release_name = "${var.namespace}-${var.name}-ingress"
  istio_ingress_chart_path   = "istio-ingress"

  ingress_namespace_enrollment_labels = var.ingress_namespace_enrollment_labels
  # {
  # "ingress": {
  # "istioNamespaceEnrollmentLabels": var.ingress_namespace_enrollment_labels
  # }
  # }

  ingress_selectors = {
    "ingress" : {
      "istioSelectors" : var.ingress_selectors
    }
  }

  ingress_alb_subnets = {
    "ingress" : {
      "albsubnets" : var.ingress_alb_subnets
    }
  }

  ingress_nlb_zones_subnets = {
    "ingress" : {
      "nlbzonessubnets" : var.ingress_nlb_zones_subnets
    }
  }

  ingress_ports = {
    "ingress" : {
      "ports" : var.ingress_ports
    }
  }

  ingress_autoscale_configuration = {
    "ingress" : {
      "autoscale" : var.ingress_autoscale_configuration
    }
  }

  ingress_pdb_configuration = var.ingress_pdb_configuration == null ? {} : {
    "ingress" : {
      "pdb" : var.ingress_pdb_configuration
    }
  }

  ingress_resources_configuration = var.ingress_resources_configuration == null ? {} : {
    "ingress" : {
      "resources" : var.ingress_resources_configuration
    }
  }

  ingress_affinity = var.ingress_affinity == null ? {} : {
    "ingress" : {
      "affinity" : var.ingress_affinity
    }
  }

  ingress_tolerations = var.ingress_tolerations == null ? {} : {
    "ingress" : {
      "tolerations" : var.ingress_tolerations
    }
  }

}

module "ingress_namespace" {
  count   = var.create_namespace ? 1 : 0
  source  = "terraform-ibm-modules/namespace/ibm"
  version = "v1.0.3"
  namespaces = [
    {
      name = var.namespace
      metadata = {
        labels      = local.ingress_namespace_enrollment_labels
        annotations = local.ingress_namespace_enrollment_labels
      }
    }
  ]
}

# installing helm chart for istio deployment
resource "helm_release" "istio_ingress" {
  depends_on       = [module.ingress_namespace[0]]
  name             = local.istio_ingress_release_name
  chart            = "${path.module}/../../chart/${local.istio_ingress_chart_path}"
  namespace        = var.namespace
  create_namespace = false
  # timeout           = "60"
  dependency_update = true
  force_update      = var.force_controlplane_update
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set = [
    {
      name  = "ingress.name"
      type  = "string"
      value = var.name
    },
    {
      name  = "ingress.namespace"
      type  = "string"
      value = var.namespace
    },
    {
      name  = "ingress.svctype"
      type  = "string"
      value = var.ingress_service_type # LoadBalancer
    },
    {
      name  = "ingress.lbtype"
      type  = "string"
      value = var.ingress_loadbalancer_type # alb nlb sdnlb
    },
    {
      name  = "ingress.lbiptype"
      type  = "string"
      value = var.ingress_ip_type
    },
    {
      name  = "ingress.externalTrafficPolicy"
      type  = "string"
      value = var.ingress_external_traffic_policy # Local Cluster
    },
    {
      name  = "ingress.internalTrafficPolicy"
      type  = "string"
      value = var.ingress_internal_traffic_policy # Cluster Local
    },
    {
      name  = "ingress.replicacount"
      type  = "string"
      value = var.ingress_replicas #
    },
    {
      name  = "ingress.terminationGracePeriodSeconds"
      type  = "string"
      value = var.ingress_termination_grace_period
    }
  ]

  values = [
    yamlencode(local.ingress_namespace_enrollment_labels),
    yamlencode(local.ingress_selectors),
    yamlencode(local.ingress_alb_subnets),
    yamlencode(local.ingress_nlb_zones_subnets),
    yamlencode(local.ingress_ports),
    yamlencode(local.ingress_autoscale_configuration),
    yamlencode(local.ingress_pdb_configuration),
    yamlencode(local.ingress_resources_configuration),
    yamlencode(local.ingress_affinity),
    yamlencode(local.ingress_tolerations),
  ]

}


# resource "null_resource" "confirm_istio_operational" {
#   depends_on = [helm_release.istio_ingress]
#   provisioner "local-exec" {
#     command     = "${path.module}/scripts/confirm-istio-operational.sh \"${var.namespace}\" \"${var.name}\""
#     interpreter = ["/bin/bash", "-c"]
#     environment = {
#       KUBECONFIG = var.cluster_config_file_path
#     }
#   }
# }
