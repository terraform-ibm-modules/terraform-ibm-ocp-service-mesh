output "transit_ingress" {
  value       = module.transit_ingress
  description = "Details for the ALB ingress gateway"
}

output "transit_egress" {
  value       = module.transit_egress
  description = "Details for the egress gateway"
}
