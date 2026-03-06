# cluster references

variable "existing_cluster_id" {
  type        = string
  description = "Id of the target IBM Cloud OpenShift Cluster"
}

variable "existing_resource_group" {
  type        = string
  description = "The ID of the resource group for the OpenShift Cluster."
}

# ingress configuration

# variable "istio_controlplane_name" {
#   type        = string
#   default     = "default"
#   description = "Name of the Istio controlplane to use for ingress and egress"
# }

variable "public_ingress_name" {
  type        = string
  description = "Name of the Istio ingress deployment"
}

variable "public_ingress_namespace" {
  type        = string
  description = "Namespace where to install istio ingress dataplane."
}

variable "istio_mesh_enrollment" {
  type        = string
  default     = "default"
  description = "Name of the Istio mesh controlplane to enroll this dataplane with. Default value to \"default\". This value is used to generate discovery selectors, to override the computed values customise var.ingress_discovery_custom_configuration."
}

variable "public_ingress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the ingress gateway"
}

variable "public_ingress_discovery_custom_configuration" {
  type        = map(string)
  default     = null
  description = "Map of key-value entries to set custom istio discovery labels. Default to null to autogenerate the labels according to var.istio_mesh_enrollment value. For more details about istio discovery configuration refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-about-sidecar-injection_ossm-sidecar-injection and https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-deploying-multiple-service-meshes-on-single-cluster."
}

variable "ingress_custom_annotations" {
  type        = map(string)
  default     = {}
  nullable    = false
  description = "Istio ingress to customise your ingress LoadBalaner set with var.ingress_loadbalancer_type = \"other\". Null not allowed"
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
  description = "Ingress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
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
  description = "Istio ingress deployment replicaset configuration. If the var.ingress_autoscale_configuration.enabled is true this value is ignored. Default to 3."
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
  default     = {}
  description = "Istio ingress affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Ingress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels. Default to empty configuration."
}

variable "public_ingress_tolerations" {
  type        = list(any)
  default     = []
  description = "Istio ingress tolerations configuration. Default to tolerate 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
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





variable "public_egress_name" {
  type        = string
  description = "Name of the Istio egress deployment"
}

variable "public_egress_namespace" {
  type        = string
  description = "Namespace where to install istio egress dataplane."
}

variable "public_egress_deployment_timeout" {
  type        = string
  default     = null
  description = "Timeout for the helm release deployment for the egress gateway"
}

variable "public_egress_discovery_custom_configuration" {
  type        = map(string)
  default     = null
  description = "Map of key-value entries to set custom istio discovery labels. Default to null to autogenerate the labels according to var.istio_mesh_enrollment value. For more details about istio discovery configuration refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-about-sidecar-injection_ossm-sidecar-injection and https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-deploying-multiple-service-meshes-on-single-cluster."
}

variable "public_egress_traffic_selectors" {
  type = map(string)
  default = {
    "app" : "istio-egress",
    "istio" : "istio-egress",
  }
  nullable    = false
  description = "Istio egress selectors to route outbound egress traffic to the expected istio gateway and to the expected workload. Default to \"app\": \"istio-egress\" \"istio\": \"istio-egress\" \"gateway-instance\": \"istio-egressgateway\". Null not allowed"
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
  description = "egress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false."
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
  default     = {}
  description = "Istio egress affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Egress pods are provided of a label with key \"istio.io/gateway\" and value \"[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]\" in order to allow to set them as antiAffinity labels. Default to empty configuration."
}

variable "public_egress_tolerations" {
  type        = list(any)
  default     = []
  description = "Istio egress tolerations configuration. Default to tolerate 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}
