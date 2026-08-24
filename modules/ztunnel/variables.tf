variable "namespace" {
  type        = string
  description = "Namespace where to install ZTunnel"
  default     = "ztunnel"

  validation {
    condition     = var.namespace != null && var.namespace != ""
    error_message = "Namespace value can not be null or empty"
  }
}

variable "ztunnel_resources_configuration" {
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
  description = "ZTunnel resources deployment configuration (cpu/memory requests and limits). Default configuration is null and leverages on Istio default setting."
  default     = null
}

variable "tolerations" {
  type = list(object({
    key                = optional(string)
    operator           = optional(string)
    value              = optional(string)
    effect             = optional(string)
    toleration_seconds = optional(number)
  }))
  description = "Tolerations to apply to the ZTunnel DaemonSet pods."
  default = [{
    operator = "Exists"
  }]
}

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}
