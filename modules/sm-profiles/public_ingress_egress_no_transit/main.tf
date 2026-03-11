locals {
  public_ingress_pods_affinity = var.public_ingress_pods_affinity != null ? var.public_ingress_pods_affinity : {
    podAffinity : {},
    nodeAffinity : {
      requiredDuringSchedulingIgnoredDuringExecution : {
        nodeSelectorTerms : [
          {
            matchExpressions : [
              {
                key : "ibm-cloud.kubernetes.io/worker-pool-name",
                operator : "In",
                values : ["edge"]
              }
            ]
          }
        ]
      }
    },
    podAntiAffinity : {
      preferredDuringSchedulingIgnoredDuringExecution : [
        {
          podAffinityTerm : {
            labelSelector : {
              matchExpressions : [
                {
                  key : "istio.io/gateway",
                  operator : "In",
                  values : ["${var.public_ingress_name}.${var.profile_namespace}"]
                }
              ]
            }
            topologyKey : "topology.kubernetes.io/zone"
          }
          weight : 100
        }
      ]
    }
  }

  public_ingress_tolerations = var.public_ingress_tolerations != null ? var.public_ingress_tolerations : [
    {
      key : "dedicated"
      value : "edge"
      effect : "NoExecute"
    }
  ]
}

module "public_ingress" {
  source                    = "../../sm-istio-ingress"
  name                      = var.public_ingress_name
  namespace                 = var.profile_namespace
  create_namespace          = true
  force_dataplane_update    = false
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "public"
  ingress_loadbalancer_type = var.public_ingress_loadbalancer_type

  istio_ingress_deployment_timeout     = var.public_ingress_deployment_timeout
  istio_mesh_enrollment                = var.istio_mesh_enrollment
  ingress_affinity                     = local.public_ingress_pods_affinity
  ingress_selectors                    = var.public_ingress_traffic_selectors
  ingress_ports                        = var.public_ingress_ports
  ingress_alb_idle_timeout             = var.public_ingress_alb_idle_timeout
  ingress_external_traffic_policy      = var.public_ingress_external_traffic_policy
  ingress_internal_traffic_policy      = var.public_ingress_internal_traffic_policy
  ingress_alb_subnets                  = var.public_ingress_alb_subnets
  ingress_nlb_zones_subnets            = var.public_ingress_nlb_zones_subnets
  ingress_autoscale_configuration      = var.public_ingress_autoscale_configuration
  ingress_pdb_configuration            = var.public_ingress_pdb_configuration
  ingress_replicas                     = var.public_ingress_replicas
  ingress_resources_configuration      = var.public_ingress_resources_configuration
  ingress_termination_grace_period     = var.public_ingress_termination_grace_period
  ingress_tolerations                  = local.public_ingress_tolerations
  ingress_enable_proxy_protocol        = var.public_ingress_enable_proxy_protocol
  ingress_proxy_protocol_allow_without = var.public_ingress_proxy_protocol_allow_without
  ingress_custom_annotations           = var.ingress_custom_annotations

  cluster_id        = var.existing_cluster_id
  resource_group_id = var.existing_resource_group
}

locals {
  public_egress_pods_affinity = var.public_egress_pods_affinity != null ? var.public_egress_pods_affinity : {
    podAffinity : {},
    nodeAffinity : {
      requiredDuringSchedulingIgnoredDuringExecution : {
        nodeSelectorTerms : [
          {
            matchExpressions : [
              {
                key : "ibm-cloud.kubernetes.io/worker-pool-name",
                operator : "In",
                values : ["edge"]
              }
            ]
          }
        ]
      }
    },
    podAntiAffinity : {
      preferredDuringSchedulingIgnoredDuringExecution : [
        {
          podAffinityTerm : {
            labelSelector : {
              matchExpressions : [
                {
                  key : "istio.io/gateway",
                  operator : "In",
                  values : ["${var.public_egress_name}.${var.profile_namespace}"]
                }
              ]
            }
            topologyKey : "topology.kubernetes.io/zone"
          }
          weight : 100
        }
      ]
    }
  }

  public_egress_tolerations = var.public_egress_tolerations != null ? var.public_egress_tolerations : [
    {
      key : "dedicated"
      value : "edge"
      effect : "NoExecute"
    }
  ]
}

module "public_egress" {
  source                          = "../../sm-istio-egress"
  name                            = var.public_egress_name
  namespace                       = var.profile_namespace
  create_namespace                = false
  force_dataplane_update          = true
  istio_mesh_enrollment           = var.istio_mesh_enrollment
  egress_affinity                 = local.public_egress_pods_affinity
  egress_selectors                = var.public_egress_traffic_selectors
  istio_egress_deployment_timeout = var.public_egress_deployment_timeout
  egress_ports                    = var.public_egress_ports
  egress_internal_traffic_policy  = var.public_egress_internal_traffic_policy
  egress_autoscale_configuration  = var.public_egress_autoscale_configuration
  egress_pdb_configuration        = var.public_egress_pdb_configuration
  egress_replicas                 = var.public_egress_replicas
  egress_resources_configuration  = var.public_egress_resources_configuration
  egress_termination_grace_period = var.public_egress_termination_grace_period
  egress_tolerations              = local.public_egress_tolerations

  cluster_id        = var.existing_cluster_id
  resource_group_id = var.existing_resource_group
}
