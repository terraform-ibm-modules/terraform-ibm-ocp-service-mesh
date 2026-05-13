output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "The id of the cluster"
}

output "vpc_id" {
  description = "ID of the deployed VPC"
  value       = module.ocp_base.vpc_id
}

##############################################################################
# Ingress Service Details Outputs
##############################################################################

output "ingress_loadbalancer_hostname" {
  description = "Load balancer hostname(s) - map of service name to hostname for ALB and NLB types, empty map for other types"
  value       = module.basic_workload_ingress.ingress_loadbalancer_hostname
}

output "ingress_loadbalancer_ips" {
  description = "Load balancer IPs - map of service_name to IP for NLB type, map of indexed keys to IPs for other types, empty map for ALB"
  value       = module.basic_workload_ingress.ingress_loadbalancer_ips
}

# # This works
# output "istio_network_policy_metadata" {
#   value = module.istio_network_policy.istio_default_network_policy_metadata
# }

# # Manifest fails
# output "istio_network_policy_manifest" {
#   value = module.istio_network_policy.istio_default_network_policy_manifest
# }

# output "istio_network_policy_default_ingress_selector" {
#   value = module.istio_network_policy.istio_network_policy_default_ingress_selector
# }
