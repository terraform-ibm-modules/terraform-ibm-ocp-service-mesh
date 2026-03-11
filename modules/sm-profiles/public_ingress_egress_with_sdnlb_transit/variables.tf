# cluster references

variable "existing_cluster_id" {
  type        = string
  description = "Id of the target IBM Cloud OpenShift Cluster"
}

variable "istio_mesh_enrollment" {
  type        = string
  default     = "default"
  description = "Name of the Istio mesh controlplane to enroll this dataplane with. Default value to \"default\". This value is used to generate discovery selectors, to override the computed values customise var.ingress_discovery_custom_configuration."
}

variable "profile_namespace" {
  type        = string
  description = "Namespace where to install all the profile dataplane (i.e. the gateways resources)."
}

variable "existing_resource_group" {
  type        = string
  description = "The ID of the resource group for the OpenShift Cluster."
}

# public ingress configuration

variable "public_ingress_name" {
  type        = string
  description = "Name of the Istio ingress deployment"
}

variable "public_ingress_loadbalancer_type" {
  type        = string
  default     = "alb"
  nullable    = false
  description = "IBM Cloud LoadBalancer type bound to the ingress: valid values are \"alb\" for Application Load Balancer, \"nlb\" for Network Load Balancer, and \"other\" to define your LoadBalancer with your custom annotations. If var.ingress_service_type == \"ClusterIP\" this value hasn't effect. For more details refer to https://cloud.ibm.com/docs/vpc?topic=vpc-nlb-vs-elb. Default to ALB."
  validation {
    condition     = contains(["alb", "nlb", "other"], var.public_ingress_loadbalancer_type)
    error_message = "The allowed values for var.ingress_service_type are alb, nlb or other."
  }
}

variable "public_ingress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the ingress gateway"
}

variable "public_ingress_custom_annotations" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Istio ingress to customise your ingress LoadBalaner set with var.public_ingress_loadbalancer_type = \"other\". Null not allowed"
}

variable "public_ingress_traffic_selectors" {
  type = map(string)
  default = {
    "app" : "istio-ingress",
    "istio" : "istio-ingress",
  }
  nullable    = false
  description = "Istio ingress selectors to route inbound ingress traffic to the expected istio gateway and to the expected workload. Default to \"app\": \"istio-ingress\" \"istio\": \"istio-ingress\". Null not allowed"
}

variable "public_ingress_alb_idle_timeout" {
  type        = number
  default     = null
  description = "The idle connection timeout of the IBM Cloud Application Loadbalancer listener in seconds. Default to null to adopt platform default configuration. The value cannot be less than 50s and more than 7200s. For more details refer to https://cloud.ibm.com/docs/containers?topic=containers-setup_vpc_alb."
}

variable "public_ingress_alb_subnets" {
  type        = list(string)
  default     = []
  nullable    = false
  description = "List of VPC subnets to attach to the IBM Cloud Application LoadBalancer bound to the cluster. Null value is not allowed. Default to empty list."
}

variable "public_ingress_nlb_zones_subnets" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Map of tuples \"subnetID\": \"VPC zone\" to configure IBM Cloud Network LoadBalancer instances on the expected zone and subnet. Null value is not allowed. Default to empty map."
}

variable "public_ingress_ports" {
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
    },
    {
      port : 15021,
      name : "status-port",
      proto : "TCP",
      targetPort : 15021
  }]
  description = "List of ports to configured on ingress and LoadBalancer to list for inbound traffic. Default to port 443:8443 on TCP."
}

variable "public_ingress_external_traffic_policy" {
  type        = string
  default     = "Cluster"
  description = "External traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/."
  nullable    = false
}

variable "public_ingress_internal_traffic_policy" {
  type        = string
  default     = "Local"
  description = "Internal traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Local. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/."
  nullable    = false
}

variable "public_ingress_autoscale_configuration" {
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
  description = "Public ingress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
}

variable "public_ingress_pdb_configuration" {
  description = "Configuration of the PodDisruptionBudget for the istio ingress definition. Default to null to leverage on Istio default configuration."
  default     = null
  type = object({
    minAvailable   = optional(string, null)
    maxUnavailable = optional(string, null)
  })
}

variable "public_ingress_replicas" {
  type        = number
  default     = 3
  description = "Istio ingress deployment replicaset configuration. If the var.public_ingress_autoscale_configuration.enabled is true this value is ignored. Default to 3."
  nullable    = false
}

variable "public_ingress_resources_configuration" {
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

variable "public_ingress_termination_grace_period" {
  type        = number
  description = "Number of seconds for the Istio ingress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default."
  default     = null
}

variable "public_ingress_pods_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = null
  description = "Istio ingress affinity configuration. Default null setting by default the ingress pods on edge labeled worker nodes. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Ingress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels."
}

variable "public_ingress_tolerations" {
  type        = list(any)
  default     = null
  description = "Istio ingress tolerations configuration. Default null setting toleration to 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}

variable "public_ingress_enable_proxy_protocol" {
  description = "Flag to enable Proxy Protocol on ingress LoadBalancer (only ALB type) and to enable the EnvoyFilter to implement Proxy Protocol on ingress gateway"
  type        = bool
  default     = false
}

variable "public_ingress_proxy_protocol_allow_without" {
  description = "Flag to support traffic with or without Proxy Protocol on ingress LoadBalancer (only ALB type) and on the EnvoyFilter that implements Proxy Protocol on ingress gateway"
  type        = bool
  default     = false
}

# public egress configuration

variable "public_egress_name" {
  type        = string
  description = "Name of the Istio egress deployment"
}

variable "public_egress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the egress gateway"
}

variable "public_egress_traffic_selectors" {
  type = map(string)
  default = {
    "app" : "istio-egress",
    "istio" : "istio-egress",
  }
  nullable    = false
  description = "Istio egress selectors to route outbound egress traffic to the expected istio gateway and to the expected workload. Default to \"app\": \"istio-egress\" \"istio\": \"istio-egress\". Null not allowed"
}

variable "public_egress_ports" {
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
    targetPort : 443
  }]
  description = "List of ports to configured on egress for outbound traffic. Default to port 443:443 on TCP."
}

variable "public_egress_internal_traffic_policy" {
  type        = string
  default     = "Cluster"
  description = "Internal traffic policy configuration for the egress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-egress/."
  nullable    = false
}

variable "public_egress_autoscale_configuration" {
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
  description = "Public egress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
}

variable "public_egress_pdb_configuration" {
  description = "Configuration of the PodDisruptionBudget for the istio egress definition. Default to null to leverage on Istio default configuration."
  default     = null
  type = object({
    minAvailable   = optional(string, null)
    maxUnavailable = optional(string, null)
  })
}

variable "public_egress_replicas" {
  type        = number
  default     = 3
  description = "Istio egress deployment replicaset configuration. If the var.egress_autoscale_configuration.enabled is true this value is ignored. Default to 3."
  nullable    = false
}

variable "public_egress_resources_configuration" {
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

variable "public_egress_termination_grace_period" {
  type        = number
  description = "Number of seconds for the Istio egress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default."
  default     = null
}

variable "public_egress_pods_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = null
  description = "Istio egress affinity configuration. Default null setting by default the ingress pods on edge labeled worker nodes. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Egress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels. Default to empty configuration."
}

variable "public_egress_tolerations" {
  type        = list(any)
  default     = null
  description = "Istio egress tolerations configuration. Default null setting toleration to 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}

# transit ingress configuration

variable "transit_ingress_name" {
  type        = string
  description = "Name of the Istio ingress deployment"
}

variable "transit_ingress_loadbalancer_type" {
  type        = string
  default     = "other"
  nullable    = false
  description = "IBM Cloud LoadBalancer type bound to the ingress: valid values are \"alb\" for Application Load Balancer, \"nlb\" for Network Load Balancer, and \"other\" to define your LoadBalancer with your custom annotations. If var.ingress_service_type == \"ClusterIP\" this value hasn't effect. For more details refer to https://cloud.ibm.com/docs/vpc?topic=vpc-nlb-vs-elb. Default to other."
  validation {
    condition     = contains(["alb", "nlb", "other"], var.transit_ingress_loadbalancer_type)
    error_message = "The allowed values for var.ingress_service_type are alb, nlb or other."
  }
}

variable "transit_ingress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the transit ingress gateway"
}

variable "transit_ingress_custom_annotations" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Istio ingress to customise your ingress LoadBalaner set with var.transit_ingress_loadbalancer_type = \"other\". Null not allowed. Empty value makes the ingress to get predefined annotations for transit ingress."
}

variable "transit_ingress_traffic_selectors" {
  type = map(string)
  default = {
    "app" : "istio-transit-ingress",
    "istio" : "istio-transit-ingress",
  }
  nullable    = false
  description = "Istio transit ingress selectors to route inbound transit ingress traffic to the expected istio gateway and to the expected workload. Default to \"app\": \"istio-transit-ingress\" \"istio\": \"istio-transit-ingress\". Null not allowed"
}

variable "transit_ingress_ports" {
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
    },
    {
      port : 15021,
      name : "status-port",
      proto : "TCP",
      targetPort : 15021
    },
    {
      port : 15443,
      name : "tls",
      proto : "TCP",
      targetPort : 15443
  }]
  description = "List of ports to configured on transit ingress and LoadBalancer to list for inbound traffic. Default to port 443:8443 on TCP."
}

variable "transit_ingress_external_traffic_policy" {
  type        = string
  default     = "Cluster"
  description = "External traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/."
  nullable    = false
}

variable "transit_ingress_internal_traffic_policy" {
  type        = string
  default     = "Local"
  description = "Internal traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Local. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/."
  nullable    = false
}

variable "transit_ingress_autoscale_configuration" {
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
  description = "Transit ingress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
}

variable "transit_ingress_pdb_configuration" {
  description = "Configuration of the PodDisruptionBudget for the istio transit ingress definition. Default to null to leverage on Istio default configuration."
  default     = null
  type = object({
    minAvailable   = optional(string, null)
    maxUnavailable = optional(string, null)
  })
}

variable "transit_ingress_replicas" {
  type        = number
  default     = 3
  description = "Istio transit ingress deployment replicaset configuration. If the var.transit_ingress_autoscale_configuration.enabled is true this value is ignored. Default to 3."
  nullable    = false
}

variable "transit_ingress_resources_configuration" {
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
  description = "Istio transit ingress resources deployment configuration. Default configuration is null and leverages on Istio default setting."
  default     = null
}

variable "transit_ingress_termination_grace_period" {
  type        = number
  description = "Number of seconds for the Istio trasit ingress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default."
  default     = null
}

variable "transit_ingress_pods_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = null
  description = "Istio transit ingress affinity configuration. Default null setting by default the ingress pods on transit labeled worker nodes. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Ingress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels."
}

variable "transit_ingress_tolerations" {
  type        = list(any)
  default     = null
  description = "Istio transit ingress tolerations configuration. Default null setting toleration to 'dedicated: transit' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}

variable "transit_ingress_enable_proxy_protocol" {
  description = "Flag to enable Proxy Protocol on ingress LoadBalancer and to enable the EnvoyFilter to implement Proxy Protocol on ingress gateway"
  type        = bool
  default     = false
}

variable "transit_ingress_proxy_protocol_allow_without" {
  description = "Flag to support traffic with or without Proxy Protocol on ingress LoadBalancer and on the EnvoyFilter that implements Proxy Protocol on ingress gateway"
  type        = bool
  default     = false
}

variable "transit_ingress_service_crn_to_register" {
  type        = string
  default     = null
  description = "Service CRN to register with transit loadbalancer IPs. If null or empty no registration is performed. Default to null."
}

# transit egress configuration

variable "transit_egress_name" {
  type        = string
  description = "Name of the Istio transit egress deployment"
}

variable "transit_egress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the transit egress gateway"
}

variable "transit_egress_traffic_selectors" {
  type = map(string)
  default = {
    "app" : "istio-transit-egress",
    "istio" : "istio-transit-egress",
  }
  nullable    = false
  description = "Istio egress selectors to route outbound transit egress traffic to the expected istio gateway and to the expected workload. Default to \"app\": \"istio-transit-egress\" \"istio\": \"istio-transit-egress\". Null not allowed"
}

variable "transit_egress_ports" {
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
    targetPort : 443
  }]
  description = "List of ports to configured on transit egress for outbound traffic. Default to port 443:443 on TCP."
}

variable "transit_egress_internal_traffic_policy" {
  type        = string
  default     = "Cluster"
  description = "Internal traffic policy configuration for the transit egress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-egress/."
  nullable    = false
}

variable "transit_egress_autoscale_configuration" {
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
  description = "Transit egress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
}

variable "transit_egress_pdb_configuration" {
  description = "Configuration of the PodDisruptionBudget for the istio transit egress definition. Default to null to leverage on Istio default configuration."
  default     = null
  type = object({
    minAvailable   = optional(string, null)
    maxUnavailable = optional(string, null)
  })
}

variable "transit_egress_replicas" {
  type        = number
  default     = 3
  description = "Istio transit egress deployment replicaset configuration. If the var.transit_egress_autoscale_configuration.enabled is true this value is ignored. Default to 3."
  nullable    = false
}

variable "transit_egress_resources_configuration" {
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
  description = "Transit istio egress resources deployment configuration. Default configuration is null and leverages on Istio default setting."
  default     = null
}

variable "transit_egress_termination_grace_period" {
  type        = number
  description = "Number of seconds for the transit istio egress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default."
  default     = null
}

variable "transit_egress_pods_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = null
  description = "Istio transit egress affinity configuration. Default null setting by default the ingress pods on transit labeled worker nodes. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Egress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels. Default to empty configuration."
}

variable "transit_egress_tolerations" {
  type        = list(any)
  default     = null
  description = "Istio transit egress tolerations configuration. Default null setting toleration to 'dedicated: transit' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}
