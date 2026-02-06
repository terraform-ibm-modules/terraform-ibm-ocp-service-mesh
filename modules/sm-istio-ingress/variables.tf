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

# ingress configuration

variable "name" {
  type        = string
  description = "Name of the Istio ingress deployment"
}

variable "create_namespace" {
  type        = bool
  description = "Flag to create the namespace where to install istio ingress dataplane. Default to true"
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace where to install istio ingress dataplane."
}

variable "force_dataplane_update" {
  description = "Force dataplane to be updated"
  default     = false
  type        = bool
  nullable    = false
}

variable "ingress_service_type" {
  type        = string
  description = "Istio ingress type for the service (svc) resource definition: possible values are LoadBalancer and ClusterIP.  Default to LoadBalancer"
  default     = "LoadBalancer"
  nullable    = false
  validation {
    condition     = contains(["LoadBalancer", "ClusterIP"], var.ingress_service_type)
    error_message = "The allowed values for var.ingress_service_type are LoadBalancer and ClusterIP."
  }
}

variable "ingress_loadbalancer_type" {
  type        = string
  default     = "alb"
  nullable    = false
  description = "IBM Cloud LoadBalancer type bound to the ingress: valid values are \"alb\" for Application Load Balancer and \"nlb\" for Network Load Balancer. If var.ingress_service_type == \"ClusterIP\" this value hasn't effect. For more details refer to https://cloud.ibm.com/docs/vpc?topic=vpc-nlb-vs-elb. Default to alb."
  validation {
    condition     = contains(["alb", "nlb"], var.ingress_loadbalancer_type)
    error_message = "The allowed values for var.ingress_service_type are alb and nlb."
  }
}

variable "ingress_ip_type" {
  type        = string
  default     = "public"
  description = "IBM Cloud LoadBalancer IP type: valid values are public and private. Default to public. If var.ingress_service_type == \"ClusterIP\" this value hasn't effect."
  nullable    = false
  validation {
    condition     = contains(["public", "private"], var.ingress_ip_type)
    error_message = "The allowed values for var.ingress_ip_type are public and private."
  }
}

variable "istio_mesh_enrollment" {
  type        = string
  default     = "default"
  description = "Name of the Istio mesh controlplane to enroll this dataplane with. Default value to default. This value is used to generate discovery selectors, to override the computed values customise var.ingress_discovery_custom_configuration."
}

variable "istio_ingress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the ingress gateway"
}

variable "ingress_discovery_custom_configuration" {
  type        = map(string)
  default     = null
  description = "Map of key-value entries to set custom istio discovery labels. Default to null to autogenerate the labels according to var.istio_mesh_enrollment value. For more details about istio discovery configuration refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-about-sidecar-injection_ossm-sidecar-injection and https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-deploying-multiple-service-meshes-on-single-cluster."
}

variable "ingress_selectors" {
  type = map(string)
  default = {
    "app" : "istio-ingress",
    "istio" : "istio-ingress",
  }
  nullable    = false
  description = "Istio ingress selectors to route inbound ingress traffic to the expected istio gateway and to the expected workload. Default to \"app\": \"istio-ingress\" \"istio\": \"istio-ingress\". Null not allowed"
}

variable "ingress_alb_idle_timeout" {
  type        = number
  default     = null
  description = "The idle connection timeout of the IBM Cloud Application Loadbalancer listener in seconds. Default to null to adopt platform default configuration. The value cannot be less than 50s and more than 7200s. For more details refer to https://cloud.ibm.com/docs/containers?topic=containers-setup_vpc_alb."
  validation {
    condition     = var.ingress_alb_idle_timeout != null ? (var.ingress_alb_idle_timeout >= 50 && var.ingress_alb_idle_timeout <= 7200) : true
    error_message = "The ALB listener idle connection timeout is a number between 50 and 7200 seconds."
  }
}

variable "ingress_alb_subnets" {
  type        = list(string)
  default     = []
  nullable    = false
  description = "List of VPC subnets to attach to the IBM Cloud Application LoadBalancer bound to the cluster. Null value is not allowed. Default to empty list."
}

variable "ingress_nlb_zones_subnets" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of tuples \"subnetID\": \"VPC zone\" to configure IBM Cloud Network LoadBalancer instances on the expected zone and subnet. Null value is not allowed. Default to empty map."
}

variable "ingress_ports" {
  type = list(object(
    {
      port : number,
      name : string
      proto : string,
      targetPort : number
    }
  ))
  default = [{
    port : 443,
    name : "https",
    proto : "TCP",
    targetPort : 8443
  }]
  description = "List of ports to configured on ingress and LoadBalancer to list for inbound traffic. Default to port 443:8443 on TCP."
}

variable "ingress_external_traffic_policy" {
  type        = string
  default     = "Cluster"
  description = "External traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/."
  nullable    = false
}

variable "ingress_internal_traffic_policy" {
  type        = string
  default     = "Local"
  description = "Internal traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Local. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/."
  nullable    = false
}

variable "ingress_autoscale_configuration" {
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
  description = "Ingress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
}

variable "ingress_pdb_configuration" {
  description = "Configuration of the PodDisruptionBudget for the istio ingress definition. Default to null to leverage on Istio default configuration."
  default     = null
  type = object({
    minAvailable   = optional(string, null)
    maxUnavailable = optional(string, null)
  })
  validation {
    condition     = var.ingress_pdb_configuration == null ? true : (var.ingress_pdb_configuration.minAvailable != null && var.ingress_pdb_configuration.maxUnavailable != null ? false : true)
    error_message = "only one of minAvailable and maxUnavailable for var.ingress_pdb_configuration can be set to a value not null"
  }
  validation {
    condition     = var.ingress_pdb_configuration == null ? true : (var.ingress_pdb_configuration.minAvailable == null ? true : can(regex("^([0-9]{1,3}%?)$", var.ingress_pdb_configuration.minAvailable)))
    error_message = "minAvailable for var.ingress_pdb_configuration value is not valid. It can be set only to a number or percentage (regex ^([0-9]{1,3}%?)$)"
  }
  validation {
    condition     = var.ingress_pdb_configuration == null ? true : (var.ingress_pdb_configuration.maxUnavailable == null ? true : can(regex("^([0-9]{1,3}%?)$", var.ingress_pdb_configuration.maxUnavailable)))
    error_message = "maxUnavailable for var.ingress_pdb_configuration value is not valid. It can be set only to a number or percentage (regex ^([0-9]{1,3}%?)$)"
  }
  validation {
    condition     = var.ingress_pdb_configuration == null ? true : (var.ingress_pdb_configuration.minAvailable == null ? true : tostring(var.ingress_pdb_configuration.minAvailable) != "0")
    error_message = "minAvailable for var.ingress_pdb_configuration must be set to a value greater than 0"
  }
  validation {
    condition     = var.ingress_pdb_configuration == null ? true : (var.ingress_pdb_configuration.minAvailable == null ? true : var.ingress_pdb_configuration.minAvailable != "0%")
    error_message = "minAvailable for var.ingress_pdb_configuration must be set to a value greater than 0%"
  }
}

variable "ingress_replicas" {
  type        = number
  default     = 3
  description = "Istio ingress deployment replicaset configuration. If the var.ingress_autoscale_configuration.enabled is true this value is ignored. Default to 3."
  nullable    = false
}

variable "ingress_resources_configuration" {
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
  description = "Istio ingress resources deployment configuration. Default configuration is null and leverages on Istio default setting."
  default     = null
}

variable "ingress_termination_grace_period" {
  type        = number
  description = "Number of seconds for the Istio ingress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default."
  default     = null
}

variable "ingress_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = {}
  description = "Istio ingress affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Ingress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels. Default to empty configuration."
}

variable "ingress_tolerations" {
  type        = list(any)
  default     = []
  description = "Istio ingress tolerations configuration. Default to tolerate 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}

variable "ingress_enable_proxy_protocol" {
  description = "Flag to enable Proxy Protocol on ingress LoadBalancer (only ALB type) and to enable the EnvoyFilter to implement Proxy Protocol on ingress gateway"
  type        = bool
  default     = false
}

variable "ingress_proxy_protocol_allow_without" {
  description = "Flag to support traffic with or without Proxy Protocol on ingress LoadBalancer (only ALB type) and on the EnvoyFilter that implements Proxy Protocol on ingress gateway"
  type        = bool
  default     = false
}
