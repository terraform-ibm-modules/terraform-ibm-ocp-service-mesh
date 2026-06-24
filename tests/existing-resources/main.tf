##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# VPC
##############################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.tags
}

##############################################################################
# Public Gateways
##############################################################################

resource "ibm_is_public_gateway" "pgw_zone_1" {
  name           = "${var.prefix}-pgw-${var.region}-1"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-1"
  resource_group = module.resource_group.resource_group_id
  tags           = var.tags
}

resource "ibm_is_public_gateway" "pgw_zone_2" {
  name           = "${var.prefix}-pgw-${var.region}-2"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-2"
  resource_group = module.resource_group.resource_group_id
  tags           = var.tags
}

resource "ibm_is_public_gateway" "pgw_zone_3" {
  name           = "${var.prefix}-pgw-${var.region}-3"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.region}-3"
  resource_group = module.resource_group.resource_group_id
  tags           = var.tags
}

##############################################################################
# Subnets
##############################################################################

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-${var.region}-1"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.pgw_zone_1.id
  resource_group           = module.resource_group.resource_group_id
  tags                     = var.tags
}

resource "ibm_is_subnet" "subnet_zone_2" {
  name                     = "${var.prefix}-subnet-${var.region}-2"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-2"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.pgw_zone_2.id
  resource_group           = module.resource_group.resource_group_id
  tags                     = var.tags
}

resource "ibm_is_subnet" "subnet_zone_3" {
  name                     = "${var.prefix}-subnet-${var.region}-3"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-3"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.pgw_zone_3.id
  resource_group           = module.resource_group.resource_group_id
  tags                     = var.tags
}
