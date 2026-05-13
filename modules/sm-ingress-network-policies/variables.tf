variable "force_ingress_network_policies_update" {
  description = "Force ingress network policies to be recreated when updated. Default to false (may require to taint the resource to apply changes)"
  default     = false
  type        = bool
  nullable    = false
}

variable "ingress_network_policy_names_prefix" {
  type        = string
  description = "The prefix to use for the ingress network policies names. If set the network policies are named with this prefix. Default to null."
  default     = null
}

variable "ingress_network_policy_deployment_timeout" {
  type        = number
  description = "Deployment timeout in seconds for the ingress network policy resources. Default to 120 seconds."
  default     = 120
  nullable    = false
}

variable "ingress_network_policy_namespace" {
  type        = string
  nullable    = false
  description = "Namespace to use to deploy the ingress network policies. Cannot be null."
}

variable "ingress_network_policy_istio_controlplane" {
  type        = string
  nullable    = false
  description = "The controlplane name to use for the default ingress network policy to limit the ingress traffic to the namespaces enrolled in the same controlplane and to limit the traffic on the ingress pods only. Cannot be null."
}

variable "add_default_istio_ingress_network_policies" {
  type        = bool
  nullable    = false
  description = "Flag to create the default ingress network policies to to limit the ingress traffic to the namespaces enrolled in the same controlplane and to limit the traffic on the ingress pods only."
  default     = true
}

variable "ingress_network_policy_istio_traffic_selectors" {
  type = map(string)
  default = {
    "app" : "istio-ingress",
    "istio" : "istio-ingress"
  }
  nullable    = false
  description = "Service Mesh ingress traffic selectors used to select the namespaces allowed to reach the ingress pods according to the enrollment controlplane."
}

variable "additional_custom_ingress_network_policies" {
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
  description = "Custom ingress network policies to create along with the default one, if enabled, in the input namespace. Default to empty"
}
