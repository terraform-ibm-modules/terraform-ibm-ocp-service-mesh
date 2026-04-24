locals {
  prefix                     = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  istio_ingress_release_name = "${var.namespace}-${var.name}"
  istio_ingress_chart_path   = "istio-ingress"

  ingress_discovery_configuration = var.ingress_discovery_custom_configuration != null ? var.ingress_discovery_custom_configuration : (
    var.istio_mesh_enrollment == "default" ? {
      "istio-discovery" : "enabled",
      "istio-injection" : "enabled",
      } : {
      "istio-discovery" : var.istio_mesh_enrollment,
      "istio.io/rev" : var.istio_mesh_enrollment,
    }
  )

  ingress_selectors = {
    "ingress" : {
      "istioselectors" : var.ingress_selectors
    }
  }

  ingress_custom_annotations = {
    "ingress" : {
      "customAnnotations" : var.ingress_custom_annotations
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

##############################################################################
# Init cluster config
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

module "ingress_namespace" {
  count   = var.create_namespace ? 1 : 0
  source  = "terraform-ibm-modules/namespace/ibm"
  version = "v2.0.1"
  namespaces = [
    {
      name = var.namespace
      metadata = {
        labels      = local.ingress_discovery_configuration
        annotations = local.ingress_discovery_configuration
      }
    }
  ]
}

# installing helm chart for istio deployment
resource "helm_release" "istio_ingress" {
  depends_on        = [module.ingress_namespace[0]]
  name              = local.istio_ingress_release_name
  chart             = "${path.module}/../../chart/${local.istio_ingress_chart_path}"
  namespace         = var.namespace
  create_namespace  = false
  timeout           = var.istio_ingress_deployment_timeout
  dependency_update = true
  force_update      = var.force_dataplane_update
  cleanup_on_fail   = false
  atomic            = var.rollback_on_failure
  wait              = true

  disable_openapi_validation = false

  set = [
    {
      name  = "ingress.name"
      type  = "string"
      value = "${local.prefix}${var.name}"
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
      value = var.ingress_loadbalancer_type # alb nlb other
    },
    {
      name  = "ingress.lbiptype"
      type  = "string"
      value = var.ingress_ip_type
    },
    {
      name  = "ingress.externalTrafficPolicy"
      type  = "string"
      value = var.ingress_external_traffic_policy
    },
    {
      name  = "ingress.internalTrafficPolicy"
      type  = "string"
      value = var.ingress_internal_traffic_policy
    },
    {
      name  = "ingress.replicacount"
      type  = "string"
      value = var.ingress_replicas
    },
    {
      name  = "ingress.albtimeout"
      type  = "string"
      value = tostring(var.ingress_alb_idle_timeout)
    },
    {
      name  = "ingress.terminationGracePeriodSeconds"
      type  = "string"
      value = var.ingress_termination_grace_period
    },
    {
      name  = "ingress.proxyProtocol.enabled"
      value = var.ingress_enable_proxy_protocol
    },
    {
      name  = "ingress.proxyProtocol.allowWithoutProxyProtocol"
      value = var.ingress_proxy_protocol_allow_without
    }

  ]

  # yamlencode(local.ingress_namespace_enrollment_labels),
  values = [
    yamlencode(local.ingress_selectors),
    yamlencode(local.ingress_alb_subnets),
    yamlencode(local.ingress_custom_annotations),
    yamlencode(local.ingress_nlb_zones_subnets),
    yamlencode(local.ingress_ports),
    yamlencode(local.ingress_autoscale_configuration),
    yamlencode(local.ingress_pdb_configuration),
    yamlencode(local.ingress_resources_configuration),
    yamlencode(local.ingress_affinity),
    yamlencode(local.ingress_tolerations),
  ]

}


resource "null_resource" "confirm_ingress_operational_alb" {
  depends_on = [helm_release.istio_ingress]
  count      = var.ingress_loadbalancer_type == "alb" ? 1 : 0
  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-ingress-operational.sh \"${var.namespace}\" \"${local.prefix}${var.name}\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

# for nlb the ingress svc are created for each zone so there are a set of svc to check named "ingress-[svc name]-[zone]"
resource "null_resource" "confirm_ingress_operational_nlb" {
  depends_on = [helm_release.istio_ingress]
  for_each   = var.ingress_loadbalancer_type == "nlb" ? var.ingress_nlb_zones_subnets : {}
  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-ingress-operational.sh \"${var.namespace}\" \"${local.prefix}${var.name}-${each.value}\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
