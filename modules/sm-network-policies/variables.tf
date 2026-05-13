variable "force_network_policies_update" {
  description = "Force network policies to be recreated when updated. Default to false (may require to taint the resource to apply changes)"
  default     = false
  type        = bool
  nullable    = false
}

variable "network_policy_names_prefix" {
  type        = string
  description = "The prefix to use for the network policies names. If set the network policies are named with this prefix. Default to null."
  default     = null
}

variable "network_policy_deployment_timeout" {
  type        = number
  description = "Deployment timeout in seconds for the network policy resources. Default to 120 seconds."
  default     = 120
  nullable    = false
}

variable "network_policy_namespace" {
  type        = string
  nullable    = false
  description = "Namespace to use to deploy the network policies. Cannot be null."
}

variable "network_policy_istio_controlplane" {
  type        = string
  nullable    = false
  description = "The controlplane name to use for the default network policy to limit the ingress traffic to the namespaces enrolled in the same controlplane. Cannot be null."
}

variable "add_default_istio_network_policy" {
  type        = bool
  nullable    = false
  description = "Flag to create the default network policy to limit the ingress traffic to the namespaces enrolled in the same controlplane"
  default     = true
}

variable "additional_custom_network_policies" {
  type = list(object(
    {
      policyName : string,
      isEgressPolicy : optional(bool, false),
      isIngressPolicy : optional(bool, false),
      ingressSelectors : optional(any, null),
      egressSelectors : optional(any, null),
      podSelector : optional(any, null),
    }
  ))
  default     = []
  nullable    = false
  description = "Custom network policies to create along with the default one, if enabled, in the input namespace. Default to empty"
}
