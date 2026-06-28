output "waypoint_release_name" {
  description = "Helm release name for the east-west waypoint"
  value       = helm_release.east_west_waypoint.name
}
