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
  source     = "git::https://github.ibm.com/GoldenEye/cluster-proxy-module.git?ref=4.2.4"
  cluster_id = var.existing_cluster_id
}

##############################################################################
# Init cluster config for helm and kubernetes providers for existing cluster
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.existing_cluster_id
  resource_group_id = module.resource_group.resource_group_id
}

module "service_mesh_operator" {
  source                       = "../.."
  cluster_id                   = var.existing_cluster_id
  deploy_operator              = var.deploy_operator
  develop_mode                 = var.develop_mode
  cluster_config_endpoint_type = var.cluster_config_endpoint_type
}

module "deploy_istio_cni" {
  depends_on       = [module.service_mesh_operator]
  source           = "../../modules/sm-istio-cni"
  namespace        = "istio-system-cni"
  create_namespace = true
}

module "deploy_istio" {
  depends_on               = [module.service_mesh_operator]
  source                   = "../../modules/sm-istio"
  name                     = "default"
  namespace                = "istio-system"
  create_namespace         = true
  cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}

resource "time_sleep" "wait_istio" {
  depends_on = [module.deploy_istio, module.deploy_istio_cni]

  create_duration  = "300s"
  destroy_duration = "60s"
}

module "default_workload_ingress" {
  depends_on                = [time_sleep.wait_istio]
  source                    = "../../modules/sm-istio-ingress"
  name                      = "workload-ingress"
  namespace                 = "default-workload"
  create_namespace          = true
  force_dataplane_update    = false
  ingress_loadbalancer_type = "alb"
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "public"
  istio_mesh_enrollment     = "default"
  ingress_selectors = {
    "istio" : "default-workload-ingress",
  }
  ingress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "proto" : "TCP"
    },
    {
      "name" : "istio-health"
      "port" : "15021"
      "targetPort" : "15021"
      "proto" : "TCP"
    }
  ]
  ingress_autoscale_configuration = {
    "enabled" : false
  }
  ingress_pdb_configuration = {
    "minAvailable" = "1"
  }
  ingress_replicas = 3
  ingress_resources_configuration = {
    "limits" : {
      "cpu" : "200m"
      "memory" : "1024Mi"
    },
    "requests" : {
      "cpu" : "100m"
      "memory" : "128Mi"
    }
  }
  ingress_termination_grace_period = 30
  # cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}


module "default_workload_egress" {
  depends_on             = [time_sleep.wait_istio]
  source                 = "../../modules/sm-istio-egress"
  name                   = "workload-eress"
  namespace              = "workload-default"
  create_namespace       = false
  force_dataplane_update = true
  istio_mesh_enrollment  = "default"
  egress_selectors = {
    "istio" : "egress-gateway",
  }
  egress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "proto" : "TCP"
    },
    {
      "name" : "https"
      "port" : "443"
      "targetPort" : "443"
      "proto" : "TCP"
    }
  ]
}
