variable "namespace" {
  type        = string
  description = "Namespace where to install ZTunnel"
  default     = "ztunnel"
}

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}
