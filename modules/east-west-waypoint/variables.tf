variable "namespace" {
  type        = string
  description = "Namespace where the east-west waypoint resources will be deployed."
}

variable "configmap_name" {
  type        = string
  description = "Name of the waypoint ConfigMap resource."
  default     = "waypoint-config"
}

variable "gateway_name" {
  type        = string
  description = "Name of the waypoint Gateway resource."
  default     = "east-west-waypoint"
}

variable "waypoint_for" {
  type        = string
  description = "Value for the istio.io/waypoint-for label on the Gateway. Controls which traffic types are intercepted by the waypoint. Valid values are: service, workload, all, none. Default to service."
  default     = "service"
  nullable    = false
  validation {
    condition     = contains(["service", "workload", "all", "none"], var.waypoint_for)
    error_message = "The allowed values for var.waypoint_for are service, workload, all, and none."
  }
}

variable "allowed_routes" {
  type        = string
  description = "Controls which namespaces are allowed to attach routes to this Gateway listener. Valid values are Same (only the same namespace as the Gateway) and All (all namespaces). Default to All."
  default     = "All"
  nullable    = false
  validation {
    condition     = contains(["Same", "All"], var.allowed_routes)
    error_message = "The allowed values for var.allowed_routes are Same and All."
  }
}

variable "gateway_labels" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of labels to set under spec.infrastructure.labels of the Gateway resource. Default to empty map."
}

variable "gateway_annotations" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of annotations to set under spec.infrastructure.annotations of the Gateway resource. Default to empty map."
}

variable "deployment_labels" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of labels to set under metadata.labels of the waypoint Deployment in the ConfigMap. Default to empty map."
}

variable "deployment_annotations" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of annotations to set under metadata.annotations of the waypoint Deployment in the ConfigMap. Default to empty map."
}

variable "replicas" {
  type        = number
  default     = null
  description = "Number of replicas for the waypoint Deployment. Default to null to leverage on Istio default setting."
}

variable "waypoint_pod_labels" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of labels to set under spec.template.metadata.labels of the waypoint Deployment in the ConfigMap. Default to empty map."
}

variable "waypoint_pod_annotations" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of annotations to set under spec.template.metadata.annotations of the waypoint Deployment in the ConfigMap. Default to empty map."
}

variable "tolerations" {
  type        = list(any)
  default     = []
  nullable    = false
  description = "Tolerations to apply to the waypoint pods. Default to empty list."
}

variable "affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = {}
  description = "Affinity configuration for the waypoint pods. Default to empty configuration."
}

variable "resources_configuration" {
  type = object(
    {
      limits : optional(object(
        {
          cpu : optional(string, null),
          memory : optional(string, null)
      }), null),
      requests : optional(object(
        {
          cpu : optional(string, null)
          memory : optional(string, null)
      }), null)
    }
  )
  description = "Waypoint pod resources configuration (cpu/memory requests and limits). Default to null to leverage on Istio default setting."
  default     = null
}

variable "service_labels" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of labels to set under metadata.labels of the waypoint Service in the ConfigMap. Default to empty map."
}

variable "service_annotations" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of annotations to set under metadata.annotations of the waypoint Service in the ConfigMap. Default to empty map."
}

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}
