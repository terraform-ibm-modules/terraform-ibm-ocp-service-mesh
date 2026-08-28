locals {
  istio_controlplane_name = "istio-1"
}

########################################################################################################################
# OCP VPC cluster (multi-zone with existing VPC and subnets)
########################################################################################################################

locals {
  worker_pools = [
    {
      subnet_prefix    = "subnet-1"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      operating_system = "RHEL_9_64"
    },
    {
      subnet_prefix    = "subnet-2"
      pool_name        = "pool-2"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      operating_system = "RHEL_9_64"
    },
    {
      subnet_prefix    = "subnet-3"
      pool_name        = "pool-3"
      machine_type     = "bx2.4x16"
      workers_per_zone = 2
      operating_system = "RHEL_9_64"
    }
  ]
}

##############################################################################
# OCP CLUSTER
##############################################################################

module "ocp_base" {
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.91.0"
  resource_group_id                   = var.resource_group_id
  region                              = var.region
  resource_tags                       = var.resource_tags
  cluster_name                        = "${var.prefix}-cluster"
  force_delete_storage                = true
  vpc_id                              = var.vpc_id
  vpc_subnets                         = var.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = true # set as True to enable outbound traffic; required for accessing Operator Hub in the OpenShift console.
}

##############################################################################
# Init cluster config for helm and kubernetes providers
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = var.resource_group_id
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

module "service_mesh_operator" {
  source              = "../.."
  cluster_id          = module.ocp_base.cluster_id
  develop_mode        = var.develop_mode
  resource_group_id   = var.resource_group_id
  sm_operator_version = var.service_mesh_operator_version
}

module "deploy_istio" {
  depends_on        = [module.service_mesh_operator]
  source            = "../../modules/sm-istio"
  name              = local.istio_controlplane_name
  namespace         = "istio-system"
  create_namespace  = true
  cluster_id        = module.ocp_base.cluster_id
  resource_group_id = var.resource_group_id
}

module "deploy_istio_cni" {
  depends_on       = [module.service_mesh_operator]
  source           = "../../modules/sm-istio-cni"
  namespace        = "istio-system-cni"
  create_namespace = true
}

resource "time_sleep" "wait_istio" {
  depends_on = [module.deploy_istio, module.deploy_istio_cni]

  create_duration  = "300s"
  destroy_duration = "60s"
}

module "nlb_workload_ingress" {
  depends_on                       = [time_sleep.wait_istio]
  source                           = "../../modules/sm-istio-ingress"
  name                             = "nlb-ingress"
  namespace                        = "nlb-ingress"
  create_namespace                 = true
  force_dataplane_update           = false
  ingress_loadbalancer_type        = "nlb"
  ingress_service_type             = "LoadBalancer"
  ingress_ip_type                  = "public"
  istio_mesh_enrollment            = local.istio_controlplane_name
  istio_ingress_deployment_timeout = 1200
  ingress_deployment_name          = "nlb-deployment"
  ingress_service_name             = "nlb-service"
  ingress_affinity                 = {}
  ingress_selectors = {
    "istio" : "istio-ingress",
  }
  ingress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8080"
      "protocol" : "TCP"
    }
  ]
  ingress_nlb_zones_subnets = var.ingress_nlb_zones_subnets
  ingress_autoscale_configuration = {
    enabled      = true
    autoscaleMin = 1
    autoscaleMax = 3
    cpu = {
      targetavgutil = 75
    }
    memory = {
      targetavgutil = 70
    }
  }
  cluster_id        = module.ocp_base.cluster_id
  resource_group_id = var.resource_group_id
}

module "default_workload_egress" {
  depends_on             = [time_sleep.wait_istio]
  source                 = "../../modules/sm-istio-egress"
  name                   = "basic-egress"
  namespace              = "basic-egress"
  create_namespace       = true
  force_dataplane_update = true
  istio_mesh_enrollment  = local.istio_controlplane_name
  egress_affinity        = {}
  egress_selectors = {
    "istio" : "istio-egress",
  }
  egress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "protocol" : "TCP"
    },
    {
      "name" : "https"
      "port" : "443"
      "targetPort" : "443"
      "protocol" : "TCP"
    }
  ]
  egress_autoscale_configuration = {
    enabled      = true
    autoscaleMin = 1
    autoscaleMax = 3
    cpu = {
      targetavgutil = 75
    }
    memory = {
      targetavgutil = 70
    }
  }
  cluster_id        = module.ocp_base.cluster_id
  resource_group_id = var.resource_group_id
}

resource "kubernetes_namespace_v1" "sample_app_namespace" {
  depends_on = [time_sleep.wait_istio]
  metadata {
    name = "httpbin"
    # istio injection annotations for istio dataplane
    labels = {
      "istio-discovery" : local.istio_controlplane_name
      "istio.io/rev" : local.istio_controlplane_name
    }
    annotations = {
      "istio-discovery" : local.istio_controlplane_name
      "istio.io/rev" : local.istio_controlplane_name
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

resource "helm_release" "sample_app" {
  depends_on = [kubernetes_namespace_v1.sample_app_namespace]

  name                       = "httpbin-sample-app"
  chart                      = "../charts/sample-app/httpbin"
  namespace                  = "httpbin"
  create_namespace           = false
  timeout                    = 300
  cleanup_on_fail            = true
  wait                       = true
  atomic                     = true
  disable_openapi_validation = false

  set = [{
    name  = "namespace"
    value = "httpbin"
    }, {
    name  = "gateway.istioSelector"
    value = "istio-ingress"
    },
    {
      name  = "gateway.istioPort"
      value = "80"
  }]
}
