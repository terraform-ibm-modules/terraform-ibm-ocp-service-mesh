# cluster references

variable "cluster_id" {
  type        = string
  description = "Id of the target IBM Cloud OpenShift Cluster"
}

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group for the OpenShift Cluster."
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false
  validation {
    error_message = "Invalid Endpoint Type. Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}
variable "prefix" {
  type        = string
  nullable    = true
  description = "Prefix value to append to the name of the resources. The name of the egress resources created with this module will be in format of <prefix>-<name>."
  default     = null
  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }
}


# egress configuration

variable "name" {
  type        = string
  description = "Name of the Istio egress deployment"
}

variable "create_namespace" {
  type        = bool
  description = "Flag to create the namespace where to install istio egress dataplane. Default to true"
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace where to install istio egress dataplane."
}

variable "force_dataplane_update" {
  description = "Force dataplane to be updated"
  default     = false
  type        = bool
  nullable    = false
}

variable "istio_mesh_enrollment" {
  type        = string
  default     = "default"
  description = "Name of the Istio mesh controlplane to enroll this dataplane with. Default value to default. This value is used to generate discovery selectors, to override the computed values customise var.egress_discovery_custom_configuration."
}

variable "istio_egress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the egress gateway"
}

variable "egress_discovery_custom_configuration" {
  type        = map(string)
  default     = null
  description = "Map of key-value entries to set custom istio discovery labels. Default to null to autogenerate the labels according to var.istio_mesh_enrollment value. For more details about istio discovery configuration refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-about-sidecar-injection_ossm-sidecar-injection and https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-deploying-multiple-service-meshes-on-single-cluster."
}

variable "egress_selectors" {
  type = map(string)
  default = {
    "app" : "istio-egress",
    "istio" : "istio-egress",
  }
  nullable    = false
  description = "Istio egress selectors to route outbound egress traffic to the expected istio gateway and to the expected workload. Default to \"app\": \"istio-egress\" \"istio\": \"istio-egress\" \"gateway-instance\": \"istio-egressgateway\". Null not allowed"
}

variable "egress_ports" {
  type = list(object(
    {
      port : number,
      name : string
      protocol : string,
      targetPort : number
    }
  ))
  default = [{
    port : 443,
    name : "https",
    protocol : "TCP",
    targetPort : 443
  }]
  description = "List of ports to configured on egress for outbound traffic. Default to port 443:443 on TCP."
}

variable "egress_internal_traffic_policy" {
  type        = string
  default     = "Cluster"
  description = "Internal traffic policy configuration for the egress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-egress/."
  nullable    = false
}

variable "egress_autoscale_configuration" {
  type = object({
    enabled : optional(bool, false),
    autoscaleMin : optional(number, 1),
    autoscaleMax : optional(number, 5),
    cpu : optional(object(
      {
        targetavgutil : optional(number, 80)
      }
    ))
    memory : optional(object(
      {
        targetavgutil : optional(number, 80)
      }
    ))
  })
  default = {
    enabled : false
  }
  description = "egress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
}

variable "egress_pdb_configuration" {
  description = "Configuration of the PodDisruptionBudget for the istio egress definition. Default to null to leverage on Istio default configuration."
  default     = null
  type = object({
    minAvailable   = optional(string, null)
    maxUnavailable = optional(string, null)
  })
  validation {
    condition     = var.egress_pdb_configuration == null ? true : (var.egress_pdb_configuration.minAvailable != null && var.egress_pdb_configuration.maxUnavailable != null ? false : true)
    error_message = "only one of minAvailable and maxUnavailable for var.egress_pdb_configuration can be set to a value not null"
  }
  validation {
    condition     = var.egress_pdb_configuration == null ? true : (var.egress_pdb_configuration.minAvailable == null ? true : can(regex("^([0-9]{1,3}%?)$", var.egress_pdb_configuration.minAvailable)))
    error_message = "minAvailable for var.egress_pdb_configuration value is not valid. It can be set only to a number or percentage (regex ^([0-9]{1,3}%?)$)"
  }
  validation {
    condition     = var.egress_pdb_configuration == null ? true : (var.egress_pdb_configuration.maxUnavailable == null ? true : can(regex("^([0-9]{1,3}%?)$", var.egress_pdb_configuration.maxUnavailable)))
    error_message = "maxUnavailable for var.egress_pdb_configuration value is not valid. It can be set only to a number or percentage (regex ^([0-9]{1,3}%?)$)"
  }
  validation {
    condition     = var.egress_pdb_configuration == null ? true : (var.egress_pdb_configuration.minAvailable == null ? true : tostring(var.egress_pdb_configuration.minAvailable) != "0")
    error_message = "minAvailable for var.egress_pdb_configuration must be set to a value greater than 0"
  }
  validation {
    condition     = var.egress_pdb_configuration == null ? true : (var.egress_pdb_configuration.minAvailable == null ? true : var.egress_pdb_configuration.minAvailable != "0%")
    error_message = "minAvailable for var.egress_pdb_configuration must be set to a value greater than 0%"
  }
}

variable "egress_replicas" {
  type        = number
  default     = 3
  description = "Istio egress deployment replicaset configuration. If the var.egress_autoscale_configuration.enabled is true this value is ignored. Default to 3."
  nullable    = false
}

variable "egress_resources_configuration" {
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
  description = "Istio egress resources deployment configuration. Default configuration is null and leverages on Istio default setting."
  default     = null
}

variable "egress_termination_grace_period" {
  type        = number
  description = "Number of seconds for the Istio egress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default."
  default     = null
}

variable "egress_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = {}
  description = "Istio egress affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Egress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels. Default to empty configuration."
}

variable "egress_tolerations" {
  type        = list(any)
  default     = []
  description = "Istio egress tolerations configuration. Default to tolerate 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}
