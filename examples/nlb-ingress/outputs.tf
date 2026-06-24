output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "The id of the cluster"
}

output "vpc_id" {
  description = "ID of the VPC used by the cluster"
  value       = module.ocp_base.vpc_id
}

##############################################################################
# Ingress Service Details Outputs
##############################################################################
