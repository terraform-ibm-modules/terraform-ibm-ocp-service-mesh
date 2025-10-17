##############################################################################
# Locals
##############################################################################

locals {
  # sample_app_namespace = "bookinfo"
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.3.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

############################################################################
# CLUSTER PROXY
############################################################################

module "cluster_proxy" {
  source     = "git::https://github.ibm.com/GoldenEye/cluster-proxy-module.git?ref=4.1.1"
  cluster_id = var.existing_cluster_id
}

##############################################################################
# Init cluster config for helm and kubernetes providers for existing cluster
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.existing_cluster_id
  resource_group_id = module.resource_group.resource_group_id
}

module "service_mesh" {
  source     = "../.."
  cluster_id = var.existing_cluster_id
  # ibmcloud_api_key             = var.ibmcloud_api_key
  deploy_operator              = var.deploy_operator
  develop_mode                 = var.develop_mode
  cluster_config_endpoint_type = var.cluster_config_endpoint_type
}

module "deploy_istio_cni" {
  depends_on       = [module.service_mesh]
  source           = "../../modules/sm-istio-cni"
  namespace        = "istio-system-cni"
  create_namespace = true
}



# module "istio" {
#   depends_on       = [module.service_mesh]
#   source           = "../../modules/sm-istio"
#   name             = "mesh-1"
#   namespace        = "istio-system-1"
#   istio_namespace_discovery_custom_labels = var.istio_namespace_discovery_selector_labels
#   force_controlplane_update = false
#   mesh_config_enable_mtls      = true
#   istio_discovery_custom_configuration = var.istio_discovery_configuration
#   pilot_autoscaling_enabled = true
#   pilot_autoscaling_max_pods = 10
#   pilot_autoscaling_min_pods = 3
#   pilot_replicas = 3
#   istio_enable_default_pod_disruption_budget = false
#   pilot_autoscaling_target_memory = 75
#   pilot_autoscaling_target_cpu = 70
#   pilot_node_selector = { "ibm-cloud.kubernetes.io/worker-pool-name": "default" }
#   pilot_tolerations = [
#     {
#       key : "dedicated"
#       value : "transit"
#       effect : "NoExecute"
#     }
#   ]
#   pilot_resources = {
#     "requests": {
#       "cpu": "200m"
#       "memory": "128Mi"
#     }
#     "limits": {
#       "cpu": "500m"
#       "memory": "256Mi"
#     }
#   }
#   mesh_config_tcp_keep_alive = {
#     probes = 10
#   }
#   cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
# }

# module "workload_ingress" {
#   # depends_on = [ module.istio, module.deploy_istio_cni ]
#   source = "../../modules/sm-istio-ingress"
#   name = "workload-ingress"
#   namespace = "workload-1"
#   create_namespace = true
#   force_controlplane_update = false
#   ingress_loadbalancer_type = "alb"
#   ingress_service_type = "LoadBalancer"
#   ingress_ip_type = "public"
#   ingress_namespace_enrollment_labels = {
#     # "istio-injection": "enabled",
#     "istio-discovery": "mesh-1",
#     # "istio-discovery": "istio-hc-1",
#     "istio.io/rev": "mesh-1",
#     # "istio.io/rev": "istio-hc-1"
#   }
#   # ingress_selectors = {
#   #   "app": "istio-ingress",
#   #   "istio": "worload-1-ingress",
#   #   "gateway-instance": "istio-ingressgateway"
#   # }
#   ingress_selectors = {
#     "istio": "workload-1-ingress",
#   }
#   ingress_alb_subnets = [for subnet in module.vpc.subnets["edge"] : subnet["id"]]
#   # ingress_nlb_zones_subnets = { for subnet in module.vpc.subnets["edge"] :
#   #   subnet["id"] => subnet["zone"]
#   # }
#   ingress_ports = [
#     {
#       "name": "http2"
#       "port": "80"
#       "targetPort": "8000"
#       "proto": "TCP"
#     },
#     {
#       "name": "istio-health"
#       "port": "15021"
#       "targetPort": "15021"
#       "proto": "TCP"
#     }
#   ]
#   ingress_autoscale_configuration = {
#     "enabled": false
#   }
#   # ingress_pdb_configuration = null
#   # ingress_pdb_configuration = {
#   #   "minAvailable" = "1"
#   # }

#   ingress_replicas = 3
#   # ingress_resources_configuration = null
#   # ingress_resources_configuration = {
#   #   "limits": {
#   #     "cpu": "200m"
#   #     "memory": "1024Mi"
#   #   },
#   #   "requests": {
#   #     "cpu": "100m"
#   #     "memory": "128Mi"
#   #   }
#   # }
#   # ingress_termination_grace_period = null
#   # ingress_termination_grace_period = 30
#   # ingress_affinity = null
#   # ingress_tolerations = null
#   # cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
# }


# # TO DO TEST TO REMOVE

# module "istio_cp2" {
#   depends_on       = [module.service_mesh]
#   source           = "../../modules/sm-istio"
#   # name             = "istio-cp2"
#   name             = "mesh-2"
#   namespace        = "istio-system-2"
#   istio_namespace_discovery_selector_labels = {
#     "istio-discovery" = "mesh-2"
#     # "app" = "app-2"
#   }
#   create_namespace = true
#   force_controlplane_update = false
#   mesh_config_enable_mtls      = true
#   istio_discovery_configuration = {
#     matchLabels = {
#       # istio-discovery = "istio-cp2"
#       istio-discovery = "mesh-2"
#   }
#   }
#   pilot_autoscaling_enabled = false
#   pilot_replicas = 3
#   istio_enable_default_pod_disruption_budget = false
#   pilot_node_selector = { "ibm-cloud.kubernetes.io/worker-pool-name": "default" }
#   cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
# }

# module "default_istio" {
#   depends_on       = [module.service_mesh]
#   source           = "../../modules/sm-istio"
#   name             = "default"
#   namespace        = "istio-system"
#   # istio_namespace_discovery_selector_labels = {
#   #    "istio-discovery" = "default"
#   # }
#   force_controlplane_update = false
#   mesh_config_enable_mtls      = true
#   # istio_discovery_configuration = var.istio_discovery_configuration
#   # pilot_autoscaling_enabled = true
#   # pilot_autoscaling_max_pods = 10
#   # pilot_autoscaling_min_pods = 3
#   # pilot_replicas = 3
#   # istio_enable_default_pod_disruption_budget = false
#   # pilot_autoscaling_target_memory = 75
#   # pilot_autoscaling_target_cpu = 70
#   pilot_node_selector = { "ibm-cloud.kubernetes.io/worker-pool-name": "default" }
#   pilot_tolerations = [
#     {
#       key : "dedicated"
#       value : "transit"
#       effect : "NoExecute"
#     }
#   ]
#   # pilot_resources = {
#   #   "requests": {
#   #     "cpu": "200m"
#   #     "memory": "128Mi"
#   #   }
#   #   "limits": {
#   #     "cpu": "500m"
#   #     "memory": "256Mi"
#   #   }
#   # }
#   # mesh_config_tcp_keep_alive = {
#   #   probes = 10
#   # }
#   cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
# }

# resource "time_sleep" "wait_istio" {
#   depends_on = [ module.default_istio, module.deploy_istio_cni ]

#   create_duration  = "300s"
#   destroy_duration = "60s"
# }

# module "default_workload_ingress" {
#   depends_on = [ time_sleep.wait_istio ]
#   source = "../../modules/sm-istio-ingress"
#   name = "def-workload-ingress"
#   namespace = "default-workload-default"
#   create_namespace = true
#   force_controlplane_update = false
#   ingress_loadbalancer_type = "alb"
#   ingress_service_type = "LoadBalancer"
#   ingress_ip_type = "public"
#   istio_mesh_enrollment = "default"
#   # ingress_selectors = {
#   #   "app": "istio-ingress",
#   #   "istio": "worload-1-ingress",
#   #   "gateway-instance": "istio-ingressgateway"
#   # }
#   ingress_selectors = {
#     "istio": "default-workload-ingress",
#   }
#   ingress_alb_subnets = [for subnet in module.vpc.subnets["edge"] : subnet["id"]]
#   # ingress_nlb_zones_subnets = { for subnet in module.vpc.subnets["edge"] :
#   #   subnet["id"] => subnet["zone"]
#   # }
#   ingress_ports = [
#     {
#       "name": "http2"
#       "port": "80"
#       "targetPort": "8000"
#       "proto": "TCP"
#     },
#     {
#       "name": "istio-health"
#       "port": "15021"
#       "targetPort": "15021"
#       "proto": "TCP"
#     }
#   ]
#   # ingress_autoscale_configuration = {
#   #   "enabled": false
#   # }
#   # ingress_pdb_configuration = null
#   # ingress_pdb_configuration = {
#   #   "minAvailable" = "1"
#   # }

#   # ingress_replicas = 3
#   # ingress_resources_configuration = null
#   # ingress_resources_configuration = {
#   #   "limits": {
#   #     "cpu": "200m"
#   #     "memory": "1024Mi"
#   #   },
#   #   "requests": {
#   #     "cpu": "100m"
#   #     "memory": "128Mi"
#   #   }
#   # }
#   # ingress_termination_grace_period = null
#   # ingress_termination_grace_period = 30
#   # ingress_affinity = null
#   # ingress_tolerations = null
#   # cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
# }
