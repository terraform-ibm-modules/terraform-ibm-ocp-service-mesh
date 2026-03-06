module "public_alb_ingress" {
  # depends_on                = [time_sleep.wait_istio]
  source                    = "../../sm-istio-ingress"
  name                      = var.public_ingress_name
  namespace                 = var.public_ingress_namespace
  create_namespace          = true
  force_dataplane_update    = false
  ingress_loadbalancer_type = "alb"
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "public"

  istio_ingress_deployment_timeout       = var.public_ingress_deployment_timeout
  istio_mesh_enrollment                  = var.istio_mesh_enrollment
  ingress_discovery_custom_configuration = var.public_ingress_discovery_custom_configuration
  ingress_affinity                       = var.public_ingress_pods_affinity
  ingress_selectors                      = var.public_ingress_traffic_selectors
  ingress_ports                          = var.public_ingress_ports
  ingress_alb_idle_timeout               = var.public_ingress_alb_idle_timeout
  ingress_external_traffic_policy        = var.public_ingress_external_traffic_policy
  ingress_internal_traffic_policy        = var.public_ingress_internal_traffic_policy
  ingress_alb_subnets                    = var.public_ingress_alb_subnets
  ingress_autoscale_configuration        = var.public_ingress_autoscale_configuration
  ingress_pdb_configuration              = var.public_ingress_pdb_configuration
  ingress_replicas                       = var.public_ingress_replicas
  ingress_resources_configuration        = var.public_ingress_resources_configuration
  ingress_termination_grace_period       = var.public_ingress_termination_grace_period
  ingress_tolerations                    = var.public_ingress_tolerations
  ingress_enable_proxy_protocol          = var.public_ingress_enable_proxy_protocol
  ingress_proxy_protocol_allow_without   = var.public_ingress_proxy_protocol_allow_without
  ingress_custom_annotations             = var.ingress_custom_annotations

  cluster_id        = var.existing_cluster_id
  resource_group_id = var.existing_resource_group
}

module "public_egress" {
  # depends_on             = [time_sleep.wait_istio]
  source                                = "../../sm-istio-egress"
  name                                  = var.public_egress_name
  namespace                             = var.public_egress_namespace
  create_namespace                      = false
  force_dataplane_update                = true
  istio_mesh_enrollment                 = var.istio_mesh_enrollment
  egress_affinity                       = var.public_egress_pods_affinity
  egress_selectors                      = var.public_egress_traffic_selectors
  istio_egress_deployment_timeout       = var.public_egress_deployment_timeout
  egress_ports                          = var.public_egress_ports
  egress_discovery_custom_configuration = var.public_egress_discovery_custom_configuration
  egress_internal_traffic_policy        = var.public_egress_internal_traffic_policy
  egress_autoscale_configuration        = var.public_egress_autoscale_configuration
  egress_pdb_configuration              = var.public_egress_pdb_configuration
  egress_replicas                       = var.public_egress_replicas
  egress_resources_configuration        = var.public_egress_resources_configuration
  egress_termination_grace_period       = var.public_egress_termination_grace_period
  egress_tolerations                    = var.public_egress_tolerations

  cluster_id        = var.existing_cluster_id
  resource_group_id = var.existing_resource_group
}
