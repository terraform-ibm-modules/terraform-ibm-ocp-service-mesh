locals {

  ingress_network_policy_names_prefix = var.ingress_network_policy_names_prefix != null ? trimspace(var.ingress_network_policy_names_prefix) != "" ? "${var.ingress_network_policy_names_prefix}-" : "" : ""

  istio_ingress_network_policy_chart_path  = "sm-network-policy"
  istio_ingress_network_policy_label_key   = "istio-revision"
  istio_ingress_network_policy_label_value = var.ingress_network_policy_istio_controlplane
  istio_ingress_network_policy_default_namespace_selector_value = var.ingress_network_policy_istio_controlplane == "default" ? {
    "istio-injection" : "enabled"
    } : {
    "istio.io/rev" : var.ingress_network_policy_istio_controlplane
  }

  istio_ingress_network_policy_default_traffic_selectors = length(var.ingress_network_policy_istio_traffic_selectors) > 0 ? {
    "networkpolicy" : {
      "podSelector" : {
        "matchLabels" : var.ingress_network_policy_istio_traffic_selectors
      }
    }
    } : {
    "networkpolicy" : {
      "podSelector" : {}
    }
  }

  istio_ingress_network_policy_default_ingress_selector = var.add_default_istio_ingress_network_policies ? {
    "networkpolicy" : {
      "ingressSelectors" : [
        {
          "from" : [
            {
              "namespaceSelector" : {
                "matchLabels" : local.istio_ingress_network_policy_default_namespace_selector_value
              }
            }
          ]
        }
      ]
    }
    } : {
    "ingressSelectors" : null
  }
}

resource "helm_release" "istio_default_ingress_network_policy_traffic_selectors" {
  count             = var.add_default_istio_ingress_network_policies ? 1 : 0
  name              = "${local.ingress_network_policy_names_prefix}${replace(var.ingress_network_policy_istio_controlplane, "_", "-")}-np-ts"
  chart             = "${path.module}/../../chart/${local.istio_ingress_network_policy_chart_path}"
  namespace         = var.ingress_network_policy_namespace
  create_namespace  = false
  timeout           = var.ingress_network_policy_deployment_timeout
  dependency_update = true
  cleanup_on_fail   = false
  atomic            = true
  wait              = true
  force_update      = var.force_ingress_network_policies_update

  disable_openapi_validation = false

  set = [
    {
      name  = "networkpolicy.name"
      type  = "string"
      value = "${local.ingress_network_policy_names_prefix}${replace(var.ingress_network_policy_istio_controlplane, "_", "-")}-np-ts"
    },
    {
      name  = "networkpolicy.namespace"
      type  = "string"
      value = var.ingress_network_policy_namespace
    },
    {
      name  = "networkpolicy.ingressSelectors"
      type  = "string"
      value = null
    },
    {
      name  = "networkpolicy.label.key"
      type  = "string"
      value = local.istio_ingress_network_policy_label_key
    },
    {
      name  = "networkpolicy.label.value"
      type  = "string"
      value = local.istio_ingress_network_policy_label_value
    },
    {
      name  = "networkpolicy.isIngressPolicy"
      value = true
    },
    {
      name  = "networkpolicy.isEgressPolicy"
      value = false
    }
  ]

  values = [
    yamlencode(local.istio_ingress_network_policy_default_traffic_selectors)
  ]
}

resource "helm_release" "istio_default_ingress_network_policy_controlplane" {
  count             = var.add_default_istio_ingress_network_policies ? 1 : 0
  name              = "${local.ingress_network_policy_names_prefix}${replace(var.ingress_network_policy_istio_controlplane, "_", "-")}-np-cp"
  chart             = "${path.module}/../../chart/${local.istio_ingress_network_policy_chart_path}"
  namespace         = var.ingress_network_policy_namespace
  create_namespace  = false
  timeout           = var.ingress_network_policy_deployment_timeout
  dependency_update = true
  cleanup_on_fail   = false
  atomic            = true
  wait              = true
  force_update      = var.force_ingress_network_policies_update

  disable_openapi_validation = false

  set = [
    {
      name  = "networkpolicy.name"
      type  = "string"
      value = "${local.ingress_network_policy_names_prefix}${replace(var.ingress_network_policy_istio_controlplane, "_", "-")}-np-cp"
    },
    {
      name  = "networkpolicy.namespace"
      type  = "string"
      value = var.ingress_network_policy_namespace
    },
    {
      name  = "networkpolicy.podSelector"
      type  = "string"
      value = null
    },
    {
      name  = "networkpolicy.label.key"
      type  = "string"
      value = local.istio_ingress_network_policy_label_key
    },
    {
      name  = "networkpolicy.label.value"
      type  = "string"
      value = local.istio_ingress_network_policy_label_value
    },
    {
      name  = "networkpolicy.isIngressPolicy"
      value = true
    },
    {
      name  = "networkpolicy.isEgressPolicy"
      value = false
    }
  ]

  values = [
    yamlencode(local.istio_ingress_network_policy_default_ingress_selector)
  ]
}

resource "helm_release" "istio_custom_ingress_network_policies" {
  for_each = {
    for index, p in var.additional_custom_ingress_network_policies :
    index => p
  }

  name              = "${local.ingress_network_policy_names_prefix}${replace(each.value.policyName, "_", "-")}"
  chart             = "${path.module}/../../chart/${local.istio_ingress_network_policy_chart_path}"
  namespace         = var.ingress_network_policy_namespace
  create_namespace  = false
  timeout           = var.ingress_network_policy_deployment_timeout
  dependency_update = true
  cleanup_on_fail   = false
  atomic            = true
  wait              = true
  force_update      = var.force_ingress_network_policies_update

  disable_openapi_validation = false

  set = [
    {
      name  = "networkpolicy.name"
      type  = "string"
      value = "${local.ingress_network_policy_names_prefix}${replace(each.value.policyName, "_", "-")}"
    },
    {
      name  = "networkpolicy.namespace"
      type  = "string"
      value = var.ingress_network_policy_namespace
    },
    {
      name  = "networkpolicy.label.key"
      type  = "string"
      value = local.istio_ingress_network_policy_label_key
    },
    {
      name  = "networkpolicy.label.value"
      type  = "string"
      value = local.istio_ingress_network_policy_label_value
    },
    {
      name  = "networkpolicy.isIngressPolicy"
      value = each.value.isIngressPolicy
    },
    {
      name  = "networkpolicy.isEgressPolicy"
      value = each.value.isEgressPolicy
    }
  ]

  values = [
    yamlencode({
      "networkpolicy" : {
        "ingressSelectors" : each.value.ingressSelectors
      }
    }),
    yamlencode({
      "networkpolicy" : {
        "egressSelectors" : each.value.egressSelectors
      }
    }),
    yamlencode({
      "networkpolicy" : {
        "podSelector" : each.value.podSelector
      }
    })
  ]
}




# apiVersion: networking.k8s.io/v1
#   kind: NetworkPolicy
#   metadata:
#     annotations:
#       kubectl.kubernetes.io/last-applied-configuration: |
#         {"apiVersion":"networking.k8s.io/v1","kind":"NetworkPolicy","metadata":{"annotations":{"maistra.io/internal":"true","maistra.io/mesh-generation":"OSSM_2.6.15-2"},"labels":{"app":"ingress-gw","app.kubernetes.io/component":"istio-ingress","app.kubernetes.io/instance":"istio-system","app.kubernetes.io/managed-by":"maistra-istio-operator","app.kubernetes.io/name":"istio-ingress","app.kubernetes.io/part-of":"istio","app.kubernetes.io/version":"OSSM_2.6.15-2","istio":"ingress-gw","maistra-version":"2.6.15","maistra.io/owner":"istio-system","maistra.io/owner-name":"gateways-on-edge-transit-pool","release":"istio"},"name":"istio-ingressgateway","namespace":"istio-system","ownerReferences":[{"apiVersion":"maistra.io/v2","blockOwnerDeletion":true,"controller":true,"kind":"ServiceMeshControlPlane","name":"gateways-on-edge-transit-pool","uid":"4791afe2-9e02-46c5-aaa4-e186788117fd"}]},"spec":{"ingress":[{}],"podSelector":{"matchLabels":{"app":"ingress-gw","istio":"ingress-gw"}}}}
#       maistra.io/internal: "true"
#       maistra.io/mesh-generation: OSSM_2.6.15-2
#     creationTimestamp: "2026-05-11T12:35:38Z"
#     generation: 1
#     labels:
#       app: ingress-gw
#       app.kubernetes.io/component: istio-ingress
#       app.kubernetes.io/instance: istio-system
#       app.kubernetes.io/managed-by: maistra-istio-operator
#       app.kubernetes.io/name: istio-ingress
#       app.kubernetes.io/part-of: istio
#       app.kubernetes.io/version: OSSM_2.6.15-2
#       istio: ingress-gw
#       maistra-version: 2.6.15
#       maistra.io/owner: istio-system
#       maistra.io/owner-name: gateways-on-edge-transit-pool
#       release: istio
#     name: istio-ingressgateway
#     namespace: istio-system
#     ownerReferences:
#     - apiVersion: maistra.io/v2
#       blockOwnerDeletion: true
#       controller: true
#       kind: ServiceMeshControlPlane
#       name: gateways-on-edge-transit-pool
#       uid: 4791afe2-9e02-46c5-aaa4-e186788117fd
#     resourceVersion: "65939"
#     uid: 42a99360-e976-4f38-9407-f717c2e3b47b
#   spec:
#     ingress:
#     - {}
#     podSelector:
#       matchLabels:
#         app: ingress-gw
#         istio: ingress-gw
#     policyTypes:
#     - Ingress


# apiVersion: networking.k8s.io/v1
#   kind: NetworkPolicy
#   metadata:
#     annotations:
#       kubectl.kubernetes.io/last-applied-configuration: |
#         {"apiVersion":"networking.k8s.io/v1","kind":"NetworkPolicy","metadata":{"annotations":{"maistra.io/mesh-generation":"OSSM_2.6.15-2"},"labels":{"app":"istio","app.kubernetes.io/component":"mesh-config","app.kubernetes.io/instance":"istio-system","app.kubernetes.io/managed-by":"maistra-istio-operator","app.kubernetes.io/name":"mesh-config","app.kubernetes.io/part-of":"istio","app.kubernetes.io/version":"OSSM_2.6.15-2","maistra-version":"2.6.15","maistra.io/owner":"istio-system","maistra.io/owner-name":"gateways-on-edge-transit-pool","release":"istio"},"name":"istio-mesh-gateways-on-edge-transit-pool","namespace":"istio-system","ownerReferences":[{"apiVersion":"maistra.io/v2","blockOwnerDeletion":true,"controller":true,"kind":"ServiceMeshControlPlane","name":"gateways-on-edge-transit-pool","uid":"4791afe2-9e02-46c5-aaa4-e186788117fd"}]},"spec":{"ingress":[{"from":[{"namespaceSelector":{"matchLabels":{"maistra.io/member-of":"istio-system"}}}]}]}}
#       maistra.io/mesh-generation: OSSM_2.6.15-2
#     creationTimestamp: "2026-05-11T12:35:38Z"
#     generation: 1
#     labels:
#       app: istio
#       app.kubernetes.io/component: mesh-config
#       app.kubernetes.io/instance: istio-system
#       app.kubernetes.io/managed-by: maistra-istio-operator
#       app.kubernetes.io/name: mesh-config
#       app.kubernetes.io/part-of: istio
#       app.kubernetes.io/version: OSSM_2.6.15-2
#       maistra-version: 2.6.15
#       maistra.io/owner: istio-system
#       maistra.io/owner-name: gateways-on-edge-transit-pool
#       release: istio
#     name: istio-mesh-gateways-on-edge-transit-pool
#     namespace: istio-system
#     ownerReferences:
#     - apiVersion: maistra.io/v2
#       blockOwnerDeletion: true
#       controller: true
#       kind: ServiceMeshControlPlane
#       name: gateways-on-edge-transit-pool
#       uid: 4791afe2-9e02-46c5-aaa4-e186788117fd
#     resourceVersion: "65931"
#     uid: 29df1970-0cc9-477f-a18b-5e0cbc353b6c
#   spec:
#     ingress:
#     - from:
#       - namespaceSelector:
#           matchLabels:
#             maistra.io/member-of: istio-system
#     podSelector: {}
#     policyTypes:
#     - Ingress
