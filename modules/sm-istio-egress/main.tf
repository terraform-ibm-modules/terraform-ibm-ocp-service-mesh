locals {

  prefix                    = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  istio_egress_release_name = "${var.namespace}-${var.name}"
  istio_egress_chart_path   = "istio-egress"

  service_name = try(trimspace(var.egress_service_name) != "" ? var.egress_service_name : "${local.prefix}${var.name}", "${local.prefix}${var.name}")

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

  egress_topology_spread_constraints = var.egress_topology_spread_constraints == null ? {} : {
    "egress" : {
      "topologySpreadConstraints" : var.egress_topology_spread_constraints
    }
  }

  egress_deployment_custom_labels = length(var.egress_deployment_custom_labels) == 0 ? {} : {
    "egress" = {
      "deploymentCustomLabels" = var.egress_deployment_custom_labels
    }
  }

  egress_deployment_custom_annotations = length(var.egress_deployment_custom_annotations) == 0 ? {} : {
    "egress" = {
      "deploymentCustomAnnotations" = var.egress_deployment_custom_annotations
    }
  }

  egress_resources_creation = {
    "egress" = {
      "createDeployment"     = var.egress_create_deployment
      "createService"        = var.egress_create_service
      "createServiceAccount" = var.egress_create_service_account
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

# labels to add to an existing namespace
resource "kubernetes_labels" "istio_namespace_labels" {
  count       = var.create_namespace == false && var.add_istio_labels_annotations_to_existing_namespace == true ? 1 : 0
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = var.namespace
  }
  labels = local.egress_discovery_configuration
}

# annotations to add to an existing namespace
resource "kubernetes_annotations" "istio_namespace_annotations" {
  count       = var.create_namespace == false && var.add_istio_labels_annotations_to_existing_namespace == true ? 1 : 0
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = var.namespace
  }
  annotations = local.egress_discovery_configuration
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
  atomic            = var.rollback_on_failure
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
      name  = "egress.istioMeshEnrollment"
      type  = "string"
      value = var.istio_mesh_enrollment
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
    },
    {
      name  = "egress.deploymentName"
      type  = "string"
      value = var.egress_deployment_name
    },
    {
      name  = "egress.extendSelector"
      value = var.extend_selectors
    },
    {
      name  = "egress.serviceName"
      type  = "string"
      value = var.egress_service_name
    },
    {
      name  = "egress.serviceAccountName"
      type  = "string"
      value = var.egress_service_account_name != null ? var.egress_service_account_name : "${var.name}-service-account"
    },
  ]

  values = [
    yamlencode(local.egress_selectors),
    yamlencode(local.egress_ports),
    yamlencode(local.egress_autoscale_configuration),
    yamlencode(local.egress_pdb_configuration),
    yamlencode(local.egress_resources_configuration),
    yamlencode(local.egress_affinity),
    yamlencode(local.egress_tolerations),
    yamlencode(local.egress_topology_spread_constraints),
    yamlencode(local.egress_deployment_custom_labels),
    yamlencode(local.egress_deployment_custom_annotations),
    yamlencode(local.egress_resources_creation)
  ]

}

resource "null_resource" "confirm_egress_operational" {

  count      = var.egress_create_service ? 1 : 0
  depends_on = [helm_release.istio_egress]
  triggers = {
    helm_revision = helm_release.istio_egress.metadata.revision
  }
  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-egress-operational.sh \"${var.namespace}\" \"${local.service_name}\""
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
