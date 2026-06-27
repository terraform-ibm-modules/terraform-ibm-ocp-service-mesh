output "ztunnel_release_name" {
  description = "Helm release name for ZTunnel"
  value       = helm_release.ztunnel.name
}
