##############################################################################
# Locals
##############################################################################

locals {
  # sample_app_namespace = "bookinfo"
}

##############################################################################
# Resource Group - loading existing one
##############################################################################

module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.2.0"
  existing_resource_group_name = var.resource_group
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
