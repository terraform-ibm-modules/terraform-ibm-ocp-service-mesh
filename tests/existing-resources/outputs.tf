##############################################################################
# Resource Group ID Output
##############################################################################

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.resource_group_id
}

##############################################################################
# Region Output
##############################################################################

output "region" {
  description = "Region where resources are deployed"
  value       = var.region
}

##############################################################################
# VPC ID Output
##############################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = ibm_is_vpc.vpc.id
}

##############################################################################
# Cluster VPC Subnets Output (for ocp_base module)
##############################################################################

output "cluster_vpc_subnets" {
  description = "Map of subnet lists for cluster creation, formatted for ocp_base module"
  value = {
    subnet-1 = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
    subnet-2 = [
      {
        id         = ibm_is_subnet.subnet_zone_2.id
        cidr_block = ibm_is_subnet.subnet_zone_2.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_2.zone
      }
    ]
    subnet-3 = [
      {
        id         = ibm_is_subnet.subnet_zone_3.id
        cidr_block = ibm_is_subnet.subnet_zone_3.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_3.zone
      }
    ]
  }
}

##############################################################################
# NLB Zones Subnets Output (for istio-ingress NLB configuration)
##############################################################################

output "nlb_zones_subnets" {
  description = "Map of subnet IDs to zone names for NLB configuration"
  value = {
    (ibm_is_subnet.subnet_zone_1.id) = ibm_is_subnet.subnet_zone_1.zone
    (ibm_is_subnet.subnet_zone_2.id) = ibm_is_subnet.subnet_zone_2.zone
    (ibm_is_subnet.subnet_zone_3.id) = ibm_is_subnet.subnet_zone_3.zone
  }
}