output "istio_metadata" {
  description = "Istio definition metadata"
  value       = helm_release.istio_controlplane
  sensitive   = true
}
