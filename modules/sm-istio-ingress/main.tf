locals {
  prefix                     = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  istio_ingress_release_name = "${var.namespace}-${var.name}"
  istio_ingress_chart_path   = "istio-ingress"

  ingress_deployment_name      = var.ingress_deployment_name != null && var.ingress_deployment_name != "" ? var.ingress_deployment_name : "${local.prefix}${var.name}"
  service_name                 = var.ingress_service_name != null && var.ingress_service_name != "" ? var.ingress_service_name : "${local.prefix}${var.name}"
  ingress_service_account_name = var.ingress_service_account_name != null && var.ingress_service_account_name != "" ? var.ingress_service_account_name : "${local.prefix}${var.name}-service-account"
  ingress_envoy_filter_name    = var.ingress_proxy_protocol_envoy_filter_name != null && var.ingress_proxy_protocol_envoy_filter_name != "" ? var.ingress_proxy_protocol_envoy_filter_name : "${local.prefix}${var.name}"

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

  ingress_hpa_name = var.ingress_autoscale_configuration.hpa_name != null && var.ingress_autoscale_configuration.hpa_name != "" ? var.ingress_autoscale_configuration.hpa_name : "${local.prefix}${var.name}"
  ingress_pdb_name = var.ingress_pdb_configuration != null && var.ingress_pdb_configuration.name != null && var.ingress_pdb_configuration.name != "" ? var.ingress_pdb_configuration.name : "${local.prefix}${var.name}"

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

  ingress_topology_spread_constraints = var.ingress_topology_spread_constraints == null ? {} : {
    "ingress" : {
      "topologySpreadConstraints" : var.ingress_topology_spread_constraints
    }
  }

  ingress_deployment_custom_labels = length(var.ingress_deployment_custom_labels) == 0 ? {} : {
    "ingress" = {
      "deploymentCustomLabels" = var.ingress_deployment_custom_labels
    }
  }

  ingress_deployment_custom_annotations = length(var.ingress_deployment_custom_annotations) == 0 ? {} : {
    "ingress" = {
      "deploymentCustomAnnotations" = var.ingress_deployment_custom_annotations
    }
  }

  ingress_resources_creation = {
    "ingress" = {
      "createDeployment"     = var.ingress_create_deployment
      "createService"        = var.ingress_create_service
      "createServiceAccount" = var.ingress_create_service_account
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

# labels to add to an existing namespace
resource "kubernetes_labels" "istio_namespace_labels" {
  count       = var.create_namespace == false && var.add_istio_labels_annotations_to_existing_namespace == true ? 1 : 0
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = var.namespace
  }
  labels = local.ingress_discovery_configuration
}

# annotations to add to an existing namespace
resource "kubernetes_annotations" "istio_namespace_annotations" {
  count       = var.create_namespace == false && var.add_istio_labels_annotations_to_existing_namespace == true ? 1 : 0
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = var.namespace
  }
  annotations = local.ingress_discovery_configuration
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
      name  = "ingress.istioMeshEnrollment"
      type  = "string"
      value = var.istio_mesh_enrollment
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
    },
    {
      name  = "ingress.autoscale.hpa_name"
      type  = "string"
      value = local.ingress_hpa_name
    },
    {
      name  = "ingress.pdb.name"
      type  = "string"
      value = local.ingress_pdb_name
    },
    {
      name  = "ingress.deploymentName"
      type  = "string"
      value = local.ingress_deployment_name
    },
    {
      name  = "ingress.extendSelector"
      value = var.extend_selectors
    },
    {
      name  = "ingress.serviceName"
      type  = "string"
      value = local.service_name
    },
    {
      name  = "ingress.serviceAccountName"
      type  = "string"
      value = local.ingress_service_account_name
    },
    {
      name  = "ingress.proxyProtocol.envoyFilterName"
      type  = "string"
      value = local.ingress_envoy_filter_name
    },
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
    yamlencode(local.ingress_topology_spread_constraints),
    yamlencode(local.ingress_deployment_custom_labels),
    yamlencode(local.ingress_deployment_custom_annotations),
    yamlencode(local.ingress_resources_creation)
  ]
}

resource "null_resource" "confirm_ingress_operational_alb" {
  depends_on = [helm_release.istio_ingress]
  triggers = {
    helm_revision = helm_release.istio_ingress.metadata.revision
  }
  count = var.ingress_loadbalancer_type == "alb" && var.ingress_create_service == true ? 1 : 0
  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-ingress-operational.sh \"${var.namespace}\" \"${local.service_name}\" \"alb\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

# for nlb the ingress svc are created for each zone so there are a set of svc to check named "ingress-[svc name]-[zone]"
resource "null_resource" "confirm_ingress_operational_nlb" {
  depends_on = [helm_release.istio_ingress]

  triggers = {
    helm_revision = helm_release.istio_ingress.metadata.revision
  }
  for_each = var.ingress_loadbalancer_type == "nlb" && var.ingress_create_service == true ? var.ingress_nlb_zones_subnets : {}
  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-ingress-operational.sh \"${var.namespace}\" \"${local.service_name}-${each.value}\" \"nlb\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

# for other types (internal use) - single service with potentially multiple IPs
resource "null_resource" "confirm_ingress_operational_other" {
  depends_on = [helm_release.istio_ingress]

  triggers = {
    helm_revision = helm_release.istio_ingress.metadata.revision
  }
  count = var.ingress_loadbalancer_type == "other" && var.ingress_create_service == true ? 1 : 0
  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-ingress-operational.sh \"${var.namespace}\" \"${local.service_name}\" \"other\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

##############################################################################
# Lookup ingress service details
##############################################################################

locals {
  # Build map of service names to query based on LB type
  # For NLB: multiple services (one per zone)
  # For ALB/other: single service

  ingress_services_map = var.ingress_create_service ? (
    var.ingress_loadbalancer_type == "nlb" ? {
      for subnet_id, zone in var.ingress_nlb_zones_subnets :
      "${local.service_name}-${zone}" => {
        namespace = var.namespace
        service   = "${local.service_name}-${zone}"
      }
      } : {
      (local.service_name) = {
        namespace = var.namespace
        service   = local.service_name
      }
    }
  ) : {}
}

# Query all ingress services (works for ALB, NLB, and other types)
data "kubernetes_service_v1" "ingress_services" {
  depends_on = [
    null_resource.confirm_ingress_operational_alb,
    null_resource.confirm_ingress_operational_nlb,
    null_resource.confirm_ingress_operational_other
  ]
  for_each = local.ingress_services_map

  metadata {
    name      = each.value.service
    namespace = each.value.namespace
  }
}
