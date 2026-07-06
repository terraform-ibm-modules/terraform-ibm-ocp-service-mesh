##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

locals {
  cluster_vpc_subnets = {
    default = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2 # minimum of 2 is allowed when using single zone
      operating_system = "RHEL_9_64"
    }
  ]
}

##############################################################################
# OCP CLUSTER
##############################################################################

module "ocp_base" {
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.87.1"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  tags                                = var.resource_tags
  cluster_name                        = "${var.prefix}-cluster"
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  vpc_subnets                         = local.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  disable_outbound_traffic_protection = true # set as True to enable outbound traffic; required for accessing Operator Hub in the OpenShift console.
}

##############################################################################
# Init cluster config for helm and kubernetes providers
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = module.resource_group.resource_group_id
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

module "service_mesh_operator" {
  source              = "../.."
  cluster_id          = module.ocp_base.cluster_id
  develop_mode        = var.develop_mode
  resource_group_id   = module.resource_group.resource_group_id
  sm_operator_version = var.service_mesh_operator_version
}

module "deploy_istio" {
  depends_on        = [module.service_mesh_operator]
  source            = "../../modules/sm-istio"
  name              = "default"
  namespace         = "istio-system"
  create_namespace  = true
  cluster_id        = module.ocp_base.cluster_id
  resource_group_id = module.resource_group.resource_group_id
  is_ambient_mode   = true
  ztunnel_namespace = "ztunnel-ns"
}

module "deploy_istio_cni" {
  depends_on       = [module.service_mesh_operator]
  source           = "../../modules/sm-istio-cni"
  namespace        = "istio-system-cni"
  create_namespace = true
  is_ambient_mode  = true
}

resource "kubernetes_namespace_v1" "ztunnel_namespace" {
  depends_on = [module.deploy_istio]
  metadata {
    name = "ztunnel-ns"
    labels = {
      "istio-discovery" = "enabled"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

module "deploy_ztunnel" {
  depends_on = [kubernetes_namespace_v1.ztunnel_namespace]
  source     = "../../modules/ztunnel"
  namespace  = kubernetes_namespace_v1.ztunnel_namespace.metadata[0].name
}


resource "time_sleep" "wait_istio" {
  depends_on = [module.deploy_istio, module.deploy_istio_cni, module.deploy_ztunnel]

  create_duration  = "300s"
  destroy_duration = "60s"
}

module "basic_workload_ingress" {
  depends_on                = [time_sleep.wait_istio]
  source                    = "../../modules/sm-istio-ingress"
  name                      = "alb-ingress"
  namespace                 = "alb-ingress"
  create_namespace          = true
  force_dataplane_update    = false
  ingress_loadbalancer_type = "alb"
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "public"
  istio_mesh_enrollment     = "default"
  ingress_affinity          = {} # local.alb_affinity
  ingress_selectors = {
    "istio" : "ingress-gateway",
  }
  ingress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000" # ingress gateway target port, to match in network policy, in the gateway configuration and in the workload service configuration
      "protocol" : "TCP"
    }
  ]
  cluster_id        = module.ocp_base.cluster_id
  resource_group_id = module.resource_group.resource_group_id
}



resource "kubernetes_namespace_v1" "waypoint_namespace" {
  depends_on = [module.deploy_istio]
  metadata {
    name = "waypoint-ns"
    labels = {
      "istio-discovery" = "enabled"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

module "deploy_east_west_waypoint" {
  depends_on     = [kubernetes_namespace_v1.waypoint_namespace]
  source         = "../../modules/waypoint"
  namespace      = kubernetes_namespace_v1.waypoint_namespace.metadata[0].name
  configmap_name = "wp-cm"
  gateway_name   = "wp-gw"

  resources_configuration = {
    requests = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }

  deployment_labels = {
    "app.kubernetes.io/component" = "waypoint"
  }

  waypoint_pod_labels = {
    "workload-type" = "waypoint"
  }

  service_labels = {
    "service-owner" = "platform"
  }

  gateway_labels = {
    "environment" = "dev"
  }

  affinity = {
    nodeAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = [
        {
          weight = 100
          preference = {
            matchExpressions = [
              {
                key      = "node-role.kubernetes.io/worker"
                operator = "Exists"
              }
            ]
          }
        }
      ]
    }
  }
}


resource "kubernetes_namespace_v1" "egress_namespace" {
  depends_on = [module.deploy_istio]
  metadata {
    name = "istio-egress"
    labels = {
      "istio-discovery" = "enabled"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

module "egress_waypoint" {
  depends_on     = [kubernetes_namespace_v1.egress_namespace]
  source         = "../../modules/waypoint"
  namespace      = kubernetes_namespace_v1.egress_namespace.metadata[0].name
  configmap_name = "wp-egress-config"
  gateway_name   = "wp-egress-gateway"
  replicas       = 3
}

resource "kubernetes_namespace_v1" "sample_app_namespace" {
  depends_on = [time_sleep.wait_istio]
  metadata {
    name = "httpbin"
    labels = {
      "istio-discovery" : "enabled"
      "istio.io/dataplane-mode" : "ambient"
      "istio.io/use-waypoint-namespace" : "waypoint-ns"
      "istio.io/use-waypoint" : "wp-gw"
    }
    annotations = {
      "istio-discovery" : "enabled"
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
    value = "ingress-gateway"
    },
    {
      name  = "gateway.istioPort"
      value = "80"
    },
    {
      name  = "useGatewayApi"
      value = "true"
  }]
}
