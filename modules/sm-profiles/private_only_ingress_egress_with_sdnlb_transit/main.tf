locals {
  transit_ingress_pods_affinity = var.transit_ingress_pods_affinity != null ? var.transit_ingress_pods_affinity : {
    podAffinity : {},
    nodeAffinity : {
      requiredDuringSchedulingIgnoredDuringExecution : {
        nodeSelectorTerms : [
          {
            matchExpressions : [
              {
                key : "ibm-cloud.kubernetes.io/worker-pool-name",
                operator : "In",
                values : ["transit"]
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
                  values : ["${var.transit_ingress_name}.${var.profile_namespace}"]
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

  transit_ingress_tolerations = var.transit_ingress_tolerations != null ? var.transit_ingress_tolerations : [
    {
      key : "dedicated"
      value : "transit"
      effect : "NoExecute"
    }
  ]

  transit_ingress_annotations = var.transit_ingress_custom_annotations != {} ? var.transit_ingress_custom_annotations : {
    "service.kubernetes.io/ibm-load-balancer-cloud-provider-enable-features" : "service-dnlb"
    "service.kubernetes.io/ibm-load-balancer-cloud-provider-ip-type" : "private"
    "service.kubernetes.io/ibm-load-balancer-cloud-provider-vpc-node-selector" : "transit"
    "service.kubernetes.io/ibm-load-balancer-cloud-provider-vpc-service-crn" : var.transit_ingress_service_crn_to_register != null ? var.transit_ingress_service_crn_to_register : ""
  }
}

module "transit_ingress" {
  source                    = "../../sm-istio-ingress"
  name                      = var.transit_ingress_name
  namespace                 = var.profile_namespace
  create_namespace          = false
  force_dataplane_update    = false
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "private"
  ingress_loadbalancer_type = var.transit_ingress_loadbalancer_type

  istio_ingress_deployment_timeout     = var.transit_ingress_deployment_timeout
  istio_mesh_enrollment                = var.istio_mesh_enrollment
  ingress_affinity                     = local.transit_ingress_pods_affinity
  ingress_selectors                    = var.transit_ingress_traffic_selectors
  ingress_ports                        = var.transit_ingress_ports
  ingress_external_traffic_policy      = var.transit_ingress_external_traffic_policy
  ingress_internal_traffic_policy      = var.transit_ingress_internal_traffic_policy
  ingress_autoscale_configuration      = var.transit_ingress_autoscale_configuration
  ingress_pdb_configuration            = var.transit_ingress_pdb_configuration
  ingress_replicas                     = var.transit_ingress_replicas
  ingress_resources_configuration      = var.transit_ingress_resources_configuration
  ingress_termination_grace_period     = var.transit_ingress_termination_grace_period
  ingress_tolerations                  = local.transit_ingress_tolerations
  ingress_enable_proxy_protocol        = var.transit_ingress_enable_proxy_protocol
  ingress_proxy_protocol_allow_without = var.transit_ingress_proxy_protocol_allow_without
  ingress_custom_annotations           = local.transit_ingress_annotations

  cluster_id        = var.existing_cluster_id
  resource_group_id = var.existing_resource_group
}

locals {
  transit_egress_pods_affinity = var.transit_egress_pods_affinity != null ? var.transit_egress_pods_affinity : {
    podAffinity : {},
    nodeAffinity : {
      requiredDuringSchedulingIgnoredDuringExecution : {
        nodeSelectorTerms : [
          {
            matchExpressions : [
              {
                key : "ibm-cloud.kubernetes.io/worker-pool-name",
                operator : "In",
                values : ["transit"]
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
                  values : ["${var.transit_egress_name}.${var.profile_namespace}"]
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

  transit_egress_tolerations = var.transit_egress_tolerations != null ? var.transit_egress_tolerations : [
    {
      key : "dedicated"
      value : "transit"
      effect : "NoExecute"
    }
  ]
}

module "transit_egress" {
  source                          = "../../sm-istio-egress"
  name                            = var.transit_egress_name
  namespace                       = var.profile_namespace
  create_namespace                = false
  force_dataplane_update          = true
  istio_mesh_enrollment           = var.istio_mesh_enrollment
  egress_affinity                 = local.transit_egress_pods_affinity
  egress_selectors                = var.transit_egress_traffic_selectors
  istio_egress_deployment_timeout = var.transit_egress_deployment_timeout
  egress_ports                    = var.transit_egress_ports
  egress_internal_traffic_policy  = var.transit_egress_internal_traffic_policy
  egress_autoscale_configuration  = var.transit_egress_autoscale_configuration
  egress_pdb_configuration        = var.transit_egress_pdb_configuration
  egress_replicas                 = var.transit_egress_replicas
  egress_resources_configuration  = var.transit_egress_resources_configuration
  egress_termination_grace_period = var.transit_egress_termination_grace_period
  egress_tolerations              = local.transit_egress_tolerations

  cluster_id        = var.existing_cluster_id
  resource_group_id = var.existing_resource_group
}
