##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.8"
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
  version                             = "3.81.5"
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
  source            = "../.."
  cluster_id        = module.ocp_base.cluster_id
  develop_mode      = var.develop_mode
  resource_group_id = module.resource_group.resource_group_id
}

module "deploy_istio" {
  depends_on        = [module.service_mesh_operator]
  source            = "../../modules/sm-istio"
  name              = "default"
  namespace         = "istio-system"
  create_namespace  = true
  cluster_id        = module.ocp_base.cluster_id
  resource_group_id = module.resource_group.resource_group_id
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

module "basic_with_mtls_profile" {
  depends_on              = [module.deploy_istio_cni, time_sleep.wait_istio]
  source                  = "../../modules/sm-profiles/basic_with_mtls"
  existing_cluster_id     = module.ocp_base.cluster_id
  existing_resource_group = module.resource_group.resource_group_id

  public_ingress_name      = "public-ingress"
  public_ingress_namespace = "basic-profile"
  istio_mesh_enrollment    = "default"

  # ingress_custom_annotations

  public_ingress_traffic_selectors = {
    "app" : "istio-ingress",
    "istio" : "istio-ingress",
  }

  public_ingress_alb_idle_timeout = 75

  public_ingress_alb_subnets = [] # [ for subnet in module.vpc.subnets["default"] : subnet["id"] ]
  public_ingress_ports = [{
    port : 443,
    name : "https",
    proto : "TCP",
    targetPort : 8443
    },
    {
      port : 80,
      name : "http2",
      proto : "TCP",
      targetPort : 8080
  }]

  public_ingress_external_traffic_policy = "Cluster"

  public_ingress_internal_traffic_policy = "Local"

  public_ingress_replicas = 4

  # public_ingress_resources_configuration

  # public_ingress_termination_grace_period

  # public_ingress_pods_affinity

  # public_ingress_tolerations

  # public_ingress_enable_proxy_protocol = false

  # public_ingress_proxy_protocol_allow_without = false

  public_egress_name = "public-egress"

  public_egress_namespace = "basic-profile"

  public_egress_traffic_selectors = {
    "app" : "istio-egress",
    "istio" : "istio-egress",
  }


  public_egress_ports = [{
    port : 443,
    name : "https",
    proto : "TCP",
    targetPort : 443
  }]

  public_egress_internal_traffic_policy = "Cluster"

  public_egress_autoscale_configuration = {
    enabled : true,
    autoscaleMin : 1,
    autoscaleMax : 4,
    cpu : {
      targetavgutil : 85
    },
    memory : {
      targetavgutil : 85
    }
  }

  # public_egress_resources_configuration

  # public_egress_termination_grace_period

  # public_egress_pods_affinity = {}

  # public_egress_tolerations = []

}

# resource "helm_release" "sample_app" {
#   depends_on = [kubernetes_namespace_v1.sample_app_namespace]

#   name                       = "httpbin-sample-app"
#   chart                      = "../charts/sample-app/httpbin"
#   namespace                  = "httpbin"
#   create_namespace           = false
#   timeout                    = 300
#   cleanup_on_fail            = true
#   wait                       = true
#   disable_openapi_validation = false

#   set = [{
#     name  = "namespace"
#     value = "httpbin"
#     }, {
#     name  = "gateway.istioSelector"
#     value = "ingress-gateway"
#     },
#     {
#       name  = "gateway.istioPort"
#       value = "80"
#   }]
# }
