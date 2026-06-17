output "ztunnel_name" {
  description = "Name of the ZTunnel resource"
  value       = var.name
}

output "ztunnel_namespace" {
  description = "Namespace where ZTunnel is installed"
  value       = var.namespace
}

output "ztunnel_release_name" {
  description = "Helm release name for ZTunnel"
  value       = helm_release.ztunnel.name
}
