##############################################################################
# Existing Resource Group
##############################################################################

module "existing_resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.5.0"
  existing_resource_group_name = var.existing_resource_group
}

##############################################################################
# Init cluster config for helm and kubernetes providers
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.existing_cluster_id
  resource_group_id = module.existing_resource_group.resource_group_id
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

module "service_mesh_operator" {
  source                        = "../.."
  cluster_id                    = var.existing_cluster_id
  develop_mode                  = var.develop_mode
  resource_group_id             = module.existing_resource_group.resource_group_id
  clean_servicemesh_on_undeploy = true
}

module "deploy_istio" {
  depends_on                = [module.service_mesh_operator]
  source                    = "../../modules/sm-istio"
  name                      = var.istio_controlplane_name
  namespace                 = var.istio_controlplane_namespace
  create_namespace          = true
  cluster_id                = var.existing_cluster_id
  resource_group_id         = module.existing_resource_group.resource_group_id
  force_controlplane_update = true
  mesh_config_enable_mtls   = true
  istio_discovery_custom_configuration = {
    matchLabels : {
      "istio-discovery" : var.istio_controlplane_name
    }
  }
  istio_namespace_discovery_custom_labels = {
    "istio-discovery" : var.istio_controlplane_name
  }
  pilot_autoscaling_enabled  = true
  pilot_autoscaling_max_pods = 5
  pilot_autoscaling_min_pods = 2
  pilot_node_selector        = { "ibm-cloud.kubernetes.io/worker-pool-name" : "default" }

  pilot_affinity = {
    podAntiAffinity : {
      preferredDuringSchedulingIgnoredDuringExecution : [
        {
          weight : 100,
          podAffinityTerm : {
            labelSelector : {
              matchExpressions : [
                {
                  key : "istio",
                  operator : "In",
                  values : ["istiod"]
                }
              ]
            }
            topologyKey : "topology.kubernetes.io/zone"
          }
        }
      ]
    }
  }

}

module "deploy_istio_cni" {
  depends_on       = [module.service_mesh_operator]
  source           = "../../modules/sm-istio-cni"
  namespace        = "istio-system-v3-cni"
  create_namespace = true
}

resource "time_sleep" "wait_istio" {
  depends_on = [module.deploy_istio, module.deploy_istio_cni]

  create_duration  = "300s"
  destroy_duration = "60s"
}


module "basic_workload_ingress" {
  depends_on                = [time_sleep.wait_istio]
  source                    = "../../modules/sm-istio-ingress"
  name                      = "basic-ingress"
  namespace                 = "basic-ingress"
  create_namespace          = true
  force_dataplane_update    = false
  ingress_loadbalancer_type = "alb"
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "public"
  istio_mesh_enrollment     = var.istio_controlplane_name
  ingress_affinity          = {}
  ingress_selectors = {
    "istio" : "ingress-gw",
  }
  ingress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "9080"
      "proto" : "TCP"
    }
  ]
  cluster_id          = var.existing_cluster_id
  resource_group_id   = module.existing_resource_group.resource_group_id
  ingress_alb_subnets = [] # set the subnets to the ones you would like to attach to the Loadbalancer
}

module "default_workload_egress" {
  depends_on             = [time_sleep.wait_istio]
  source                 = "../../modules/sm-istio-egress"
  name                   = "basic-egress"
  namespace              = "basic-egress"
  create_namespace       = true
  force_dataplane_update = true
  istio_mesh_enrollment  = var.istio_controlplane_name
  egress_affinity        = {}
  egress_selectors = {
    "istio" : "egress-gateway",
  }
  egress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "proto" : "TCP"
    },
    {
      "name" : "https"
      "port" : "443"
      "targetPort" : "443"
      "proto" : "TCP"
    }
  ]
  cluster_id        = var.existing_cluster_id
  resource_group_id = module.existing_resource_group.resource_group_id
}

##############################################################################
# Deploy BookInfo sample app
##############################################################################

resource "kubernetes_namespace_v1" "bookinfo_v3" {
  metadata {
    name = "bookinfo-v3"
    labels = {
      "istio-discovery" : var.istio_controlplane_name
      "istio.io/rev" : var.istio_controlplane_name
    }
    annotations = {
      "istio-discovery" : var.istio_controlplane_name
      "istio.io/rev" : var.istio_controlplane_name
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

resource "helm_release" "bookinfo" {
  depends_on = [kubernetes_namespace_v1.bookinfo_v3]

  name                       = "bookinfo-sample-istio-app"
  chart                      = "../sample-app/bookinfo"
  namespace                  = "bookinfo-v3"
  create_namespace           = false
  timeout                    = 300
  cleanup_on_fail            = true
  wait                       = true
  disable_openapi_validation = false

  set = [{
    name  = "gateway.istioSelector"
    value = "ingress-gw"
    },
    {
      name  = "gateway.istioPort"
      value = "80"
  }]
}
