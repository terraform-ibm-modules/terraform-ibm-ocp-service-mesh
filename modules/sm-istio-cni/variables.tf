variable "create_namespace" {
  type        = bool
  description = "Flag to create the namespace where to install Istio CNI. Default to true"
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace where to install Istio CNI"
}
