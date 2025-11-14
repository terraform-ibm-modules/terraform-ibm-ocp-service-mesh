variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API Key for a user / serviceId with write access to the corresponding namespace in the OCP cluster"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "ocp-smv3"
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "resource_group" {
  type        = string
  description = "Optionally pass an existing resource group name to be used. If not passed a new one will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "deploy_operator" {
  type        = bool
  description = "Enable installing RedHat Service Mesh Operator"
  default     = true
}

variable "develop_mode" {
  type        = bool
  description = "If true, output more logs, and reduce some wait periods"
  default     = false
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
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
  default = {
    matchLabels : {
      "istio-discovery" : "enabled"
    }
  }
  description = "Istio controlplane discovery label."
}

variable "istio_namespace_discovery_labels" {
  type = map(string)
  default = {
    "istio-discovery" = "enabled"
  }
  description = "Istio controlplane discovery label to apply to controlplane namespace."
}

variable "pilot_autoscaling_enabled" {
  default     = true
  type        = bool
  description = "Enable Istio pilot autoscaling through HorizontalPodAutoscaler."
}

variable "pilot_autoscaling_max_pods" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the maximum amount of pods for Istio pilot HorizontalPodAutoscaler."
  default     = 6
}

variable "pilot_autoscaling_min_pods" {
  type        = number
  default     = 2
  description = "If var.pilot_autoscaling_enabled is enabled this sets the minimum amount of pods for Istio pilot HorizontalPodAutoscaler."
}

variable "pilot_replicas" {
  description = "Sets the number of replicas to deploy the Istio Pilot."
  default     = 3
  type        = number
}

variable "istio_enable_default_pod_disruption_budget" {
  type        = bool
  default     = true
  description = "Controls whether a PodDisruptionBudget with a default minAvailable value of 1 is created for each deployment."
}

variable "pilot_autoscaling_target_memory" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the target memory average load."
  default     = 85
}

variable "pilot_autoscaling_target_cpu" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the target CPU average load"
  default     = 75
}

variable "pilot_node_selector" {
  default     = { "ibm-cloud.kubernetes.io/worker-pool-name" : "default" }
  description = "Node selector configuration for Istio pilot pods"
  type        = map(string)
}

variable "pilot_resources" {
  type = object({
    limits : optional(map(string), null),
    requests : optional(map(string), null)
  })
  description = "Istio pilot pods resources requests and limits for memory and CPU."
  default = {
    "requests" : {
      "cpu" : "200m"
      "memory" : "128Mi"
    }
    "limits" : {
      "cpu" : "500m"
      "memory" : "256Mi"
    }
  }
}

variable "mesh_config_tcp_keep_alive" {
  type = object({
    probes : optional(number, 9),
    time : optional(string, "7200s")
    interval : optional(string, "75s")
  })
  description = "Istio configuration for TCP keepalive"
  default = {
    probes = 10
  }
}

variable "pilot_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default = {
    podAntiAffinity : {
      preferredDuringSchedulingIgnoredDuringExecution : [
        {
          weight : 100,
          podAffinityTerm : {
            labelSelector : {
              matchExpressions : [
                {
                  key : "istio",
                  operator : "In",
                  values : ["istiod"]
                }
              ]
            }
            topologyKey : "topology.kubernetes.io/zone"
          }
        }
      ]
    }
  }
  description = "Istio pilot pods affinity configuration."
}

variable "pilot_tolerations" {
  type = list(any)
  default = [
    {
      key : "dedicated"
      value : "transit"
      effect : "NoExecute"
    }
  ]
  description = "Istio pilot pods tolerations configuration."
}
