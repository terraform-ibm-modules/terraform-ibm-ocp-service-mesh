output "cluster_id" {
  description = "ID of the deployed cluster"
  value       = module.ocp_base.cluster_id
}

output "vpc_id" {
  description = "ID of the deployed VPC"
  value       = module.ocp_base.vpc_id
}

output "subnets" {
  description = "Details of the subnets deployed in the VPC and attached to the cluster"
  value       = module.vpc.subnets
}

output "ingress_alb_subnets" {
  description = "Details of the subnets deployed in the VPC and attached to the cluster to be attached to the ALB loadbalancer"
  value       = [for subnet in module.vpc.subnets["edge"] : subnet["id"]]
}

output "ingress_nlb_subnets" {
  description = "Details of the subnets deployed in the VPC and attached to the cluster to be attached to the NLB loadbalancer"
  value = { for subnet in module.vpc.subnets["edge"] :
    subnet["id"] => subnet["zone"]
  }
}
