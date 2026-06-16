variable "create_namespace" {
  type        = bool
  description = "Flag to create the namespace where to install ZTunnel. Default to true"
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace where to install ZTunnel"
  default     = "ztunnel"
}

variable "name" {
  type        = string
  description = "Name of the ZTunnel resource"
  default     = "default"
}

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}