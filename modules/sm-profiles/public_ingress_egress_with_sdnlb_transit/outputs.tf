output "public_ingress" {
  value       = module.public_ingress
  description = "Details for the public ingress gateway"
}

output "public_egress" {
  value       = module.public_egress
  description = "Details for the public egress gateway"
}

output "transit_ingress" {
  value       = module.transit_ingress
  description = "Details for the transit ingress gateway"
}

output "transit_egress" {
  value       = module.transit_egress
  description = "Details for the transit egress gateway"
}
