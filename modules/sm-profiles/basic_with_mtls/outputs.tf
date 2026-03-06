output "public_alb_ingress" {
  value       = module.public_alb_ingress
  description = "Details for the ALB ingress gateway"
}

output "public_egress" {
  value       = module.public_egress
  description = "Details for the egress gateway"
}
