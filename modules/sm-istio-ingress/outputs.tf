output "istio_ingress_metadata" {
  description = "Istio ingress helm release metadata"
  value       = helm_release.istio_ingress.metadata
}

output "ingress_loadbalancer_hostname" {
  description = "Load balancer hostname(s). For ALB: returns map with single hostname. For NLB: returns map of service name to hostname per zone. For other types: returns empty map."
  value = var.ingress_loadbalancer_type != "other" ? {
    for k, v in data.kubernetes_service_v1.ingress_services :
    k => try(v.status[0].load_balancer[0].ingress[0].hostname, null)
  } : {}
}

output "ingress_loadbalancer_ips" {
  description = "Load balancer IP addresses. For NLB: returns map of service name to IP. For other types: returns map with indexed keys (ip-0, ip-1, etc). Returns empty map for ALB."
  value = var.ingress_loadbalancer_type == "nlb" ? {
    for k, v in data.kubernetes_service_v1.ingress_services :
    k => try(v.status[0].load_balancer[0].ingress[0].ip, null)
    } : var.ingress_loadbalancer_type == "other" && length(data.kubernetes_service_v1.ingress_services) > 0 ? {
    for idx, ip in try(
      data.kubernetes_service_v1.ingress_services["${local.prefix}${var.name}"].status[0].load_balancer[0].ingress[*].ip,
      []
    ) : "ip-${idx}" => ip
  } : {}
}
