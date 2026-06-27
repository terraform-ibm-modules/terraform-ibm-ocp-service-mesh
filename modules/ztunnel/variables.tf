variable "namespace" {
  type        = string
  description = "Namespace where to install ZTunnel"
  default     = "ztunnel"
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

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}
