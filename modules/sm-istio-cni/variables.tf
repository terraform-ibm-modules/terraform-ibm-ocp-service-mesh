variable "create_namespace" {
  type        = bool
  description = "Flag to create the namespace where to install Istio CNI. Default to true"
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace where to install Istio CNI"
}

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}
variable "is_ambient_mode" {
  type        = bool
  default     = false
  nullable    = false
  description = "Enable Istio ambient mode. Ambient mode is a sidecarless approach for service mesh that uses a shared node proxy instead of per-pod sidecars."
}
