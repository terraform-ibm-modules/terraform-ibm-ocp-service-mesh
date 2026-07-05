output "waypoint_release_name" {
  description = "Helm release name for the waypoint"
  value       = helm_release.waypoint.name
}
