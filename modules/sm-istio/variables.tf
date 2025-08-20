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

variable "outboundtrafficpolicy" {
  type        = string
  default     = "ALLOW_ANY"
  description = "Istio controlplane output traffic policy configuration. Default to ALLOW_ANY. Values allowed ALLOW_ANY or REGISTRY_ONLY"
  validation {
    condition     = var.outboundtrafficpolicy == "ALLOW_ANY" || var.outboundtrafficpolicy == "REGISTRY_ONLY"
    error_message = "The outboundtrafficpolicy value must be one of the following: ALLOW_ANY, REGISTRY_ONLY"
  }
}

variable "enable_mtls" {
  type        = bool
  description = "Enable mTLS in the Istio controlplane. Default to true"
  default     = true
}
