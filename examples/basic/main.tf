##############################################################################
# Locals
##############################################################################

locals {
  # sample_app_namespace = "bookinfo"

  # VPC Configuration
  acl_rules_map = {
    private = concat(
      module.acl_profile.base_acl,
      module.acl_profile.https_acl,
      [
        {
          name        = "allow-workload-http-inbound"
          source      = "0.0.0.0/0"
          action      = "allow"
          destination = "0.0.0.0/0"
          direction   = "inbound"
          tcp = {
            source_port_min = 1
            source_port_max = 65535
            port_min        = 80
            port_max        = 80
          }
        },
        {
          name        = "allow-workload-http-outbound"
          source      = "0.0.0.0/0"
          action      = "allow"
          destination = "0.0.0.0/0"
          direction   = "outbound"
          tcp = {
            source_port_min = 80
            source_port_max = 80
            port_min        = 1
            port_max        = 65535
          }
        }
      ],
      module.acl_profile.deny_all_acl
    )
  }
  vpc_cidr_bases = {
    private = "192.168.0.0/20",
    transit = "192.168.16.0/20",
    edge    = "192.168.32.0/20"
  }

  # OCP Configuration
  ocp_worker_pools = [
    {
      subnet_prefix    = "private"
      pool_name        = "default"
      machine_type     = "bx2.4x16"
      workers_per_zone = 1
      operating_system = "RHEL_9_64"
    },
    {
      subnet_prefix    = "edge"
      pool_name        = "edge"
      machine_type     = "bx2.4x16"
      workers_per_zone = 1
      operating_system = "RHEL_9_64"
    }
    ,
    {
      subnet_prefix    = "transit"
      pool_name        = "transit"
      machine_type     = "bx2.4x16"
      workers_per_zone = 1
      operating_system = "RHEL_9_64"
    }
  ]

  worker_pools_taints = {
    all = []
    transit = [
      {
        key   = "dedicated"
        value = "transit"
        # Pod is evicted from the node if it is already running on the node,
        # and is not scheduled onto the node if it is not yet running on the node.
        effect = "NoExecute"
      }
    ]
    edge = [
      {
        key   = "dedicated"
        value = "edge"
        # Pod is evicted from the node if it is already running on the node,
        # and is not scheduled onto the node if it is not yet running on the node.
        effect = "NoExecute"
      }
    ]
    default = []
  }

}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.2.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# VPC ACLs
##############################################################################

module "acl_profile" {
  source = "git::https://github.ibm.com/GoldenEye/acl-profile-ocp.git?ref=1.3.3"
}

##############################################################################
# VPC
##############################################################################

module "vpc" {
  source                    = "git::https://github.ibm.com/GoldenEye/vpc-module.git?ref=6.6.1"
  unique_name               = var.prefix
  ibm_region                = var.region
  resource_group_id         = module.resource_group.resource_group_id
  cidr_bases                = local.vpc_cidr_bases
  acl_rules_map             = local.acl_rules_map
  virtual_private_endpoints = {}
  vpc_tags                  = var.resource_tags
}

##############################################################################
# OCP CLUSTER
##############################################################################

module "ocp_base" {
  source               = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version              = "3.49.3"
  cluster_name         = "${var.prefix}-cluster"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  force_delete_storage = true
  vpc_id               = module.vpc.vpc_id
  vpc_subnets          = module.vpc.subnets
  worker_pools         = local.ocp_worker_pools
  worker_pools_taints  = local.worker_pools_taints
  tags                 = var.resource_tags
  # outbound required by cluster proxy
  disable_outbound_traffic_protection = true
}

##############################################################################
# Init cluster config for helm and kubernetes providers
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  # cluster_name_id   = module.ocp_base.cluster_id
  cluster_name_id   = var.cluster_id
  resource_group_id = module.resource_group.resource_group_id
}

module "service_mesh" {
  source     = "../.."
  cluster_id = var.cluster_id
  # ibmcloud_api_key             = var.ibmcloud_api_key
  deploy_operator              = var.deploy_operator
  develop_mode                 = var.develop_mode
  cluster_config_endpoint_type = var.cluster_config_endpoint_type
}
