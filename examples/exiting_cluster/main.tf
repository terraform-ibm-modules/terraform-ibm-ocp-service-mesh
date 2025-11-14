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
