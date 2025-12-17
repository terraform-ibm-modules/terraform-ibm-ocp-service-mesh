output "istio_egress_metadata" {
  description = "istio_egress definition metadata"
  value       = helm_release.istio_egress.metadata
}
