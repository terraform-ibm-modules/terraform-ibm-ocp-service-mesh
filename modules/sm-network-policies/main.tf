locals {

  network_policy_names_prefix = var.network_policy_names_prefix != null ? trimspace(var.network_policy_names_prefix) != "" ? "${var.network_policy_names_prefix}-" : "" : ""

  istio_network_policy_chart_path  = "sm-network-policy"
  istio_network_policy_label_key   = "istio-revision"
  istio_network_policy_label_value = var.network_policy_istio_controlplane
  istio_network_policy_default_namespace_selector_value = var.network_policy_istio_controlplane == "default" ? {
    "istio-injection" : "enabled"
    } : {
    "istio.io/rev" : var.network_policy_istio_controlplane
  }
  istio_network_policy_default_ingress_selector = var.add_default_istio_network_policy ? {
    "networkpolicy" : {
      "ingressSelectors" : [
        {
          "from" : [
            {
              "namespaceSelector" : {
                "matchLabels" : local.istio_network_policy_default_namespace_selector_value
              }
            }
          ]
        }
      ]
    }
    } : {
    "networkpolicy" : {
      "ingressSelectors" : null
    }
  }

  istio_network_policy_default_ingress_selector_istiod = var.add_default_istio_network_policy ? {
    "networkpolicy" : {
      "ingressSelectors" : [
        {}
      ]
    }
    } : {
    "networkpolicy" : {
      "ingressSelectors" : null
    }
  }

  istio_network_policy_default_pods_selector_istiod = var.add_default_istio_network_policy ? {
    "networkpolicy" : {
      "podSelector" : {}
    }
    } : {
    "networkpolicy" : {
      "podSelector" : null
    }
  }
}

resource "helm_release" "istio_default_network_policy" {
  count             = var.add_default_istio_network_policy ? 1 : 0
  name              = "${local.network_policy_names_prefix}${replace(var.network_policy_istio_controlplane, "_", "-")}-np-is"
  chart             = "${path.module}/../../chart/${local.istio_network_policy_chart_path}"
  namespace         = var.network_policy_namespace
  create_namespace  = false
  timeout           = var.network_policy_deployment_timeout
  force_update      = var.force_network_policies_update
  dependency_update = true
  cleanup_on_fail   = false
  # atomic            = true
  atomic = false
  wait   = true

  disable_openapi_validation = false

  set = [
    {
      name  = "networkpolicy.name"
      type  = "string"
      value = "${local.network_policy_names_prefix}${replace(var.network_policy_istio_controlplane, "_", "-")}-np-is"
    },
    {
      name  = "networkpolicy.namespace"
      type  = "string"
      value = var.network_policy_namespace
    },
    {
      name  = "networkpolicy.label.key"
      type  = "string"
      value = local.istio_network_policy_label_key
    },
    {
      name  = "networkpolicy.label.value"
      type  = "string"
      value = local.istio_network_policy_label_value
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
    yamlencode(local.istio_network_policy_default_ingress_selector)
  ]
}

resource "helm_release" "istio_default_network_policy_istiod" {
  count             = var.add_default_istio_network_policy ? 1 : 0
  name              = "${local.network_policy_names_prefix}${replace(var.network_policy_istio_controlplane, "_", "-")}-np-istiod"
  chart             = "${path.module}/../../chart/${local.istio_network_policy_chart_path}"
  namespace         = var.network_policy_namespace
  create_namespace  = false
  timeout           = var.network_policy_deployment_timeout
  force_update      = var.force_network_policies_update
  dependency_update = true
  cleanup_on_fail   = false
  # atomic            = true
  atomic = false
  wait   = true

  disable_openapi_validation = false

  set = [
    {
      name  = "networkpolicy.name"
      type  = "string"
      value = "${local.network_policy_names_prefix}${replace(var.network_policy_istio_controlplane, "_", "-")}-np-istiod"
    },
    {
      name  = "networkpolicy.namespace"
      type  = "string"
      value = var.network_policy_namespace
    },
    {
      name  = "networkpolicy.podSelector"
      type  = "string"
      value = null
    },
    {
      name  = "networkpolicy.label.key"
      type  = "string"
      value = local.istio_network_policy_label_key
    },
    {
      name  = "networkpolicy.label.value"
      type  = "string"
      value = local.istio_network_policy_label_value
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
    yamlencode(local.istio_network_policy_default_ingress_selector_istiod),
    yamlencode(local.istio_network_policy_default_pods_selector_istiod)
  ]
}

resource "helm_release" "istio_custom_network_policies" {
  for_each = {
    for index, p in var.additional_custom_network_policies :
    index => p
  }

  name              = "${local.network_policy_names_prefix}${replace(each.value.policyName, "_", "-")}"
  chart             = "${path.module}/../../chart/${local.istio_network_policy_chart_path}"
  namespace         = var.network_policy_namespace
  create_namespace  = false
  timeout           = var.network_policy_deployment_timeout
  dependency_update = true
  force_update      = var.force_network_policies_update
  cleanup_on_fail   = false
  atomic            = true
  wait              = true

  disable_openapi_validation = false

  set = [
    {
      name  = "networkpolicy.name"
      type  = "string"
      value = "${local.network_policy_names_prefix}${replace(each.value.policyName, "_", "-")}"
    },
    {
      name  = "networkpolicy.namespace"
      type  = "string"
      value = var.network_policy_namespace
    },
    {
      name  = "networkpolicy.label.key"
      type  = "string"
      value = local.istio_network_policy_label_key
    },
    {
      name  = "networkpolicy.label.value"
      type  = "string"
      value = local.istio_network_policy_label_value
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
