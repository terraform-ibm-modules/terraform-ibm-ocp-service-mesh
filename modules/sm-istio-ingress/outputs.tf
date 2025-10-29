output "istio_ingress_metadata" {
  description = "istio_ingress definition metadata"
  value       = helm_release.istio_ingress.metadata
}
