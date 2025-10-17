output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "Cluster ID"
}

output "vpc_id" {
  value       = module.ocp_base.vpc_id
  description = "VPC ID"
}

output "subnets" {
  value       = module.vpc.subnets
  description = "Generated VPC subnets"
}
