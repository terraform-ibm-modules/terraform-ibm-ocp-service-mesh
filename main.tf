##############################################################################
# RedHat OpenShift Service Mesh 3
# Deploy the Service Mesh operator on an OCP cluster and sets up
# one or several service mesh control plane(s)
##############################################################################

##############################################################################
# Locals
##############################################################################

locals {
  operators_namespace      = "openshift-operators"
  sm_operator_release_name = "helm-release-smv3-subscription"
  sm_operator_chart_path   = "servicemeshoperator"
  # sm_operator_version              = "v3.0.3" # commented as not used in this moment
  sm_operator_name                 = "servicemeshoperator3"
  sm_operator_installplan_approval = "Manual"

  # timeout in seconds for operators helm releases to be ready
  operators_timeout = 600

  # timeout in seconds for the operators to be ready with their installPlan to approve
  operator_installplan_timeout = 1200

  # Wait periods are overally conservative on purpose to cover majority of case. Divide them by 10 during dev
  # calculating the wait period according to the amount of the operators addons to deploy (base is 60s for the service mesh operator only)
  sleep_create  = var.develop_mode ? 600 : 60
  sleep_destroy = var.develop_mode ? 360 : 36
}

##############################################################################
# Retrieve information about all the Cluster configuration files and
# certificates to access the cluster through the kubernetes provider
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

##############################################################################
# RedHat Service Mesh Operator, and its dependencies
##############################################################################

locals {
  service_mesh_operator_set_list = [
    {
      name  = "operator.namespace"
      type  = "string"
      value = local.operators_namespace
      }, {
      # name  = "operator.version"
      # type  = "string"
      # value = local.sm_operator_version
      # }, {
      name  = "operator.name"
      type  = "string"
      value = local.sm_operator_name
      }, {
      name  = "operator.installplanapproval"
      type  = "string"
      value = local.sm_operator_installplan_approval
    }
  ]

  sm_operator_custom_catalog_registry_pullsecret_value = var.sm_operator_custom_catalog_registry_pullsecret_value == null || var.sm_operator_custom_catalog_registry_pullsecret_value == "" ? null : {
    auths = {
      # tflint-ignore: terraform_deprecated_interpolation
      "${var.sm_operator_custom_catalog_registry_url}" = {
        "auth" = base64encode(var.sm_operator_custom_catalog_registry_pullsecret_value)
      }
    }
  }

  service_mesh_operator_set_list_extended = concat(
    local.service_mesh_operator_set_list,
    var.sm_operator_custom_catalog_name != null ? [
      {
        name  = "operator.source"
        type  = "string"
        value = var.sm_operator_custom_catalog_name
        }, {
        name  = "operator.sourcenamespace"
        type  = "string"
        value = var.sm_operator_custom_catalog_namespace
        }, {
        name  = "catalog.name"
        type  = "string"
        value = var.sm_operator_custom_catalog_name
        }, {
        name  = "catalog.namespace"
        type  = "string"
        value = var.sm_operator_custom_catalog_namespace
        }, {
        name  = "catalog.description"
        type  = "string"
        value = var.sm_operator_custom_catalog_description
        }, {
        name  = "catalog.publisher"
        type  = "string"
        value = var.sm_operator_custom_catalog_publisher
        }, {
        name  = "catalog.registryUrl"
        type  = "string"
        value = var.sm_operator_custom_catalog_registry_url
        }, {
        name  = "catalog.registryPullSecretName"
        type  = "string"
        value = var.sm_operator_custom_catalog_registry_pullsecret_name
        }, {
        name  = "catalog.catagalogIndexName"
        type  = "string"
        value = var.sm_operator_custom_catalog_index_name
        }, {
        name  = "catalog.catalogIndexDigest"
        type  = "string"
        value = var.sm_operator_custom_catalog_image_digest
      }
    ] : []
  )
}

# installing helm chart to enable subscriptions for openshift servicemesh v3 operator
resource "helm_release" "service_mesh_operator" {
  depends_on = [data.ibm_container_cluster_config.cluster_config]

  name              = local.sm_operator_release_name
  chart             = "${path.module}/chart/${local.sm_operator_chart_path}"
  namespace         = local.operators_namespace
  create_namespace  = false
  timeout           = local.operators_timeout
  dependency_update = true
  force_update      = false
  cleanup_on_fail   = false
  wait              = true

  disable_openapi_validation = false

  set = local.service_mesh_operator_set_list_extended

  values = [
    yamlencode({
      "catalog" = {
        "registryPullSecretValue" = local.sm_operator_custom_catalog_registry_pullsecret_value
      }
    })
  ]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/approve-install-plan.sh \"${local.operators_namespace}\" ${local.operator_installplan_timeout}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

# # trigger on destroy the removal of operator custom resources
# resource "null_resource" "undeploy_servicemesh" {
#   depends_on = [helm_release.service_mesh_operator]
#   triggers = {
#     kubeconfig   = data.ibm_container_cluster_config.cluster_config.config_file_path
#     namespace    = local.operators_namespace
#     operatorname = local.sm_operator_name
#   }

#   provisioner "local-exec" {
#     when       = destroy
#     command    = "${path.module}/scripts/deprovision-sm-operator.sh \"${self.triggers.kubeconfig}\" \"${self.triggers.namespace}\" ${self.triggers.operatorname}"
#     on_failure = continue
#   }
# }

# trigger on destroy the removal of operator custom resources
# resource "null_resource" "undeploy_servicemesh" {
#   triggers = {
#     kubeconfig   = data.ibm_container_cluster_config.cluster_config.config_file_path
#     namespace    = local.operators_namespace
#     operatorname = local.sm_operator_name
#   }

#   provisioner "local-exec" {
#     when       = destroy
#     command    = "${path.module}/scripts/deprovision-sm-operator.sh \"${self.triggers.kubeconfig}\" \"${self.triggers.namespace}\" ${self.triggers.operatorname}"
#     on_failure = continue
#   }
# }

locals {
  scripts_location = "${path.module}/scripts/"
  kubeconfig_path  = data.ibm_container_cluster_config.cluster_config.config_file_path
}

resource "terraform_data" "undeploy_servicemesh" {
  depends_on = [helm_release.service_mesh_operator]
  triggers_replace = {
    scripts_location = local.scripts_location
    namespace        = local.operators_namespace
    operatorname     = local.sm_operator_name
    kubeconfig_path  = local.kubeconfig_path
  }

  # Removes patch from Console Operator in openshift-console-operator
  provisioner "local-exec" {
    command     = "${self.triggers_replace.scripts_location}/deprovision-sm-operator.sh \"${self.triggers_replace.namespace}\" \"${self.triggers_replace.operatorname}\""
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
    environment = {
      KUBECONFIG = self.triggers_replace.kubeconfig_path
    }
  }
}

# On create: give time for the istio pod operator to warm-up up
# On delete: give time for the crd sm instance to be removed (which depends on running finalizer)
# Cheap for now - replace with polling of specific resources
resource "time_sleep" "wait_operators" {
  depends_on = [helm_release.service_mesh_operator]

  create_duration  = "${local.sleep_create}s"
  destroy_duration = "${local.sleep_destroy}s"
}
