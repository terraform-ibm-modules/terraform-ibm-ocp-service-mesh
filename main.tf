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
  sm_operator_version      = "v3.0.3"
  sm_operator_name         = "servicemeshoperator3"

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

# installing helm chart to enable subscriptions for openshift servicemesh v3 operator
resource "helm_release" "service_mesh_operator" {
  depends_on = [data.ibm_container_cluster_config.cluster_config, null_resource.undeploy_servicemesh]

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

  set = [
    {
      name  = "smoperator.namespace"
      type  = "string"
      value = local.operators_namespace
      }, {
      name  = "smoperator.version"
      type  = "string"
      value = local.sm_operator_version
      }, {
      name  = "smoperator.name"
      type  = "string"
      value = local.sm_operator_name
    }
  ]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/approve-install-plan.sh \"${local.operators_namespace}\" ${local.operator_installplan_timeout}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }

}

# trigger on destroy the removal of operator custom resources
resource "null_resource" "undeploy_servicemesh" {
  triggers = {
    kubeconfig   = data.ibm_container_cluster_config.cluster_config.config_file_path
    namespace    = local.operators_namespace
    operatorname = local.sm_operator_name
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "${path.module}/scripts/deprovision-sm-operator.sh \"${self.triggers.kubeconfig}\" \"${self.triggers.namespace}\" ${self.triggers.operatorname}"
    on_failure = continue
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
