variable "name" {
  type        = string
  description = "Name of the Istio controlplane revision"
}

variable "create_namespace" {
  type        = bool
  description = "Flag to create the namespace where to install istio controlplane. Default to true"
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace where to install istio controlplane."
}

variable "istio_discovery_configuration" {
  type = object({
    matchLabels : optional(map(string), null),
    matchExpressions : optional(list(object({
      key : string
      operator : string
      values : list(string)
    })), [])
  })
  default     = null
  description = "Istio controlplane discovery label. Default to enabled."
}

variable "istio_enable_default_pod_disruption_budget" {
  type        = bool
  description = "Controls whether a PodDisruptionBudget with a default minAvailable value of 1 is created for each deployment. Default to null, using Istio default configuration. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#defaultpoddisruptionbudgetconfig"
  default     = null
}

# variable "istio_discovery_configuration" {
#   type = list(any)
#   default     = null
#   description = "Istio controlplane discovery label. Default to enabled."
# }

# istio_discovery_configuration = {
#     "istioconfiguration": {
#       "meshConfig": {
#         "discoverySelectors": [
#           {"matchLabels": {"istio-discovery": "enabled", "app": "test"}},
#           {"matchExpressions": [
#             {key: "app", operator: "In", values: ["test1", "test2"]}
#           ]}
#         ]
#       }
#     }
#   }

variable "pilot_enabled" {
  type        = bool
  description = "Enable Istio pilot. Default to true."
  nullable    = false
  default     = true
}

variable "pilot_autoscaling_enabled" {
  type        = bool
  description = "Enable Istio pilot autoscaling through HorizontalPodAutoscaler. Default to false"
  default     = false
}

variable "pilot_autoscaling_min_pods" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the minimum amount of pods for Istio pilot HorizontalPodAutoscaler. Default to 1"
  default     = 1
}

variable "pilot_autoscaling_max_pods" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the maximum amount of pods for Istio pilot HorizontalPodAutoscaler. Default to 5"
  default     = 5
}

variable "pilot_autoscaling_target_cpu" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the target CPU average load. Default to 80 (%)"
  default     = 80
}

variable "pilot_autoscaling_target_memory" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the target memory average load. Default to 80 (%)"
  default     = 80
}

variable "pilot_replicas" {
  type        = number
  description = "Sets the number of replicas to deploy the Istio Pilot. Valid only if var.pilot_autoscaling_enabled is false. Default to 1"
  default     = 1
}

variable "pilot_node_selector" {
  type        = map(string)
  default     = null
  description = "Node selector configuration for Istio pilot pods. Default to null"
}

variable "pilot_resources" {
  type = object({
    limits : optional(map(string), null),
    requests : optional(map(string), null)
  })
  default     = null
  description = "Istio pilot resources requests and limits. Default to null"
}

variable "pilot_affinity" {
  type        = list(any)
  default     = null
  description = "Istio pilot affinity configuration. Default to null"
}

variable "pilot_tolerations" {
  type        = list(any)
  default     = null
  description = "Istio pilot tolerations configuration. Default to null"
}

variable "outboundtrafficpolicy" {
  type        = string
  default     = "ALLOW_ANY"
  description = "Istio controlplane output traffic policy configuration. Default to ALLOW_ANY. Values allowed ALLOW_ANY or REGISTRY_ONLY"
  validation {
    condition     = var.outboundtrafficpolicy == "ALLOW_ANY" || var.outboundtrafficpolicy == "REGISTRY_ONLY"
    error_message = "The outboundtrafficpolicy value must be one of the following: ALLOW_ANY, REGISTRY_ONLY"
  }
}

variable "mesh_config_enable_mtls" {
  type        = bool
  description = "Enable mTLS in the Istio controlplane. Default to true"
  default     = true
}

variable "mesh_config_connect_timeout" {
  type        = string
  description = "Connection timeout used by Envoy. Default to 10s"
  default     = "10s"
}

variable "mesh_config_tcp_keep_alive" {
  type = object({
    probes : optional(number, 9),
    time : optional(string, "7200s")
    interval : optional(string, "75s")
  })
  default     = null
  description = "Istio configuration for TCP keepalive. Default to null, using the Istio default configuration. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#connectionpoolsettingstcpsettingstcpkeepalive"
}

variable "mesh_config_ingress_controller_mode" {
  type        = string
  default     = "STRICT"
  description = "Istio Mesh configuration for ingress controller mode. Default to STRICT. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfigingresscontrollermode"
  validation {
    condition     = var.mesh_config_ingress_controller_mode == "UNSPECIFIED" || var.mesh_config_ingress_controller_mode == "OFF" || var.mesh_config_ingress_controller_mode == "DEFAULT" || var.mesh_config_ingress_controller_mode == "STRICT"
    error_message = "The mesh_config_ingress_controller_mode value must be one of the following: DEFAULT, OFF, STRICT, UNSPECIFIED"
  }
}

variable "mesh_config_ingress_service" {
  type        = string
  default     = "istio-ingressgateway"
  description = "Name of the Kubernetes service used for the istio ingress controller. If no ingress controller is specified, the default value istio-ingressgateway is used. Default to istio-ingressgateway. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig"
}

variable "mesh_config_ingress_selector" {
  description = "Defines which gateway deployment to use as the Ingress controller. This field corresponds to the Gateway.selector field, and will be set as istio: INGRESS_SELECTOR. By default, ingressgateway is used, which will select the default IngressGateway as it has the istio: ingressgateway labels. It is recommended that this is the same value as ingressService. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig"
  default     = "ingressgateway"
  type        = string
}

variable "force_controlplane_update" {
  description = "value"
  default     = true
  type        = bool
  nullable    = false
}
