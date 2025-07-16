output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "The id of the cluster"
}

# output "vpc_id" {
#   value = module.ocp_base.vpc_id
# }

# output "subnets" {
#     value = module.vpc.subnets
# }

# output "hostname" {
#   value = module.ocp_edge_ingress
# }
