output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "The id of the cluster"
}

output "vpc_id" {
  description = "ID of the deployed VPC"
  value       = module.ocp_base.vpc_id
}
