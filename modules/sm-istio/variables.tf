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

# istio controlplane configuration

variable "name" {
  type        = string
  description = "Name of the Istio controlplane revision"
}

variable "create_namespace" {
  type        = bool
  description = "Flag to create the namespace where to install istio controlplane. Default to true"
  default     = true
}

variable "add_istio_labels_annotations_to_existing_namespace" {
  type        = bool
  description = "Flag to add istio labels and annotations like the discovery ones or the value of var.istio_namespace_discovery_custom_labels to an existing namespace. Default to false. If var.create_namespace is true this flag is ignored."
  default     = false
}

variable "namespace" {
  type        = string
  description = "Namespace where to install istio controlplane."
}

variable "istio_discovery_custom_configuration" {
  type = object({
    matchLabels : optional(map(string), null),
    matchExpressions : optional(list(object({
      key : string
      operator : string
      values : list(string)
    })), [])
  })
  default     = null
  description = "Istio controlplane discovery label. Default to null to autogenerate the labels according to var.name value to matchLabels: {\"istio-discovery\" : \"enabled\"}. For more details https://istio.io/latest/blog/2021/discovery-selectors/ https://github.com/istio/api/blob/master/mesh/v1alpha1/config.proto#L1411 https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-installing-service-mesh#ossm-discoveryselectors-scope-service-mesh_ossm-installing-openshift-service-mesh"
}

variable "istio_namespace_discovery_custom_labels" {
  type        = map(string)
  default     = null
  description = "Istio controlplane discovery label to apply to controlplane namespace. Default to null to autogenerate the labels according to var.name to {\"istio-discovery\" : \"enabled\"}. If overridden consider it to be coherent with selectors of var.istio_discovery_configuration. For more details https://istio.io/latest/blog/2021/discovery-selectors/"
}

variable "istio_enable_default_pod_disruption_budget" {
  type        = bool
  description = "Controls whether a PodDisruptionBudget with a default minAvailable value of 1 is created for each deployment. Default to null, using Istio default configuration. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#defaultpoddisruptionbudgetconfig"
  default     = null
}

variable "istio_update_strategy_type" {
  type        = string
  description = "Type of strategy to use. Allowed values are InPlace or RevisionBased. When InPlace strategy is used, the existing Istio control plane is updated in-place. When the RevisionBased strategy is used, a new Istio control plane instance is created for every change to the Istio.spec.version field. For more details refer to https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#updatestrategytype. Default to InPlace"
  default     = "InPlace"
  nullable    = false
  validation {
    error_message = "Invalid update strategy type for Istio. Valid values are 'InPlace' or 'RevisionBased'"
    condition     = contains(["InPlace", "RevisionBased"], var.istio_update_strategy_type)
  }
}

variable "pilot_enabled" {
  type        = bool
  description = "Enable Istio pilot. Default to true."
  nullable    = false
  default     = true
}

variable "istio_enable_network_policy" {
  type        = bool
  description = "Enable Istio to deploy its Network Policy. Default to true. For more details refer to https://istio.io/latest/docs/setup/additional-setup/network-policy/"
  nullable    = false
  default     = true
}

variable "pilot_autoscaling_enabled" {
  type        = bool
  description = "Enable Istio pilot autoscaling through HorizontalPodAutoscaler. Default to false"
  default     = false
}

variable "pilot_autoscaling_min_pods" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the minimum amount of pods for Istio pilot HorizontalPodAutoscaler. Default to 1"
  default     = 1
}

variable "pilot_autoscaling_max_pods" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the maximum amount of pods for Istio pilot HorizontalPodAutoscaler. Default to 5"
  default     = 5
}

variable "pilot_autoscaling_target_cpu" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the target CPU average load. Default to 80 (%). Set to null to leverage on Istio default value."
  default     = 80
}

variable "pilot_autoscaling_target_memory" {
  type        = number
  description = "If var.pilot_autoscaling_enabled is enabled this sets the target memory average load. Default to 80 (%). Set to null to leverage on Istio default value."
  default     = 80
}

variable "pilot_replicas" {
  type        = number
  description = "Sets the number of replicas to deploy the Istio Pilot. Valid only if var.pilot_autoscaling_enabled is false. Default to 1"
  default     = 1
}

variable "pilot_node_selector" {
  type        = map(string)
  default     = null
  description = "Node selector configuration for Istio pilot pods. Default to null. For more details https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector"
}

variable "pilot_resources" {
  type = object({
    limits : optional(map(string), null),
    requests : optional(map(string), null)
  })
  default = {
    limits : {
      cpu : "100m"
      memory : "256M"
    },
    requests : {
      cpu : "10m"
      memory : "128M"
    }
  }
  description = "Istio pilot pods resources requests and limits for memory and CPU. Default to requests CPU 10m memory 128M limits CPU 100m memory 256M, using the default Istio values. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#resourcerequirements-v1-core"
}

variable "pilot_affinity" {
  type = object({
    podAntiAffinity : optional(any, null),
    podAffinity : optional(any, null),
    nodeAffinity : optional(any, null)
  })
  default     = {}
  description = "Istio pilot pods affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Default to empty configuration"
}

variable "pilot_tolerations" {
  type        = list(any)
  default     = []
  description = "Istio pilot pods tolerations configuration. Default to empty list. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core"
}

variable "outboundtrafficpolicy" {
  type        = string
  default     = "ALLOW_ANY"
  description = "Istio controlplane output traffic policy configuration. Default to ALLOW_ANY. Values allowed ALLOW_ANY or REGISTRY_ONLY"
  validation {
    condition     = var.outboundtrafficpolicy == "ALLOW_ANY" || var.outboundtrafficpolicy == "REGISTRY_ONLY"
    error_message = "The outboundtrafficpolicy value must be one of the following: ALLOW_ANY, REGISTRY_ONLY"
  }
}

variable "mesh_config_enable_mtls" {
  type        = bool
  description = "Enable mTLS in the Istio controlplane. Default to true"
  default     = true
}

variable "mesh_config_connect_timeout" {
  type        = string
  description = "Connection timeout used by Envoy. Default to 10s"
  default     = "10s"
}

variable "mesh_config_tcp_keep_alive" {
  type = object({
    probes : optional(number, 9),
    time : optional(string, "7200s")
    interval : optional(string, "75s")
  })
  default     = null
  description = "Istio configuration for TCP keepalive. Default to null, using the Istio default configuration. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#connectionpoolsettingstcpsettingstcpkeepalive"
}

variable "mesh_config_ingress_controller_mode" {
  type        = string
  default     = "STRICT"
  description = "Istio Mesh configuration for ingress controller mode. Default to STRICT. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfigingresscontrollermode"
  validation {
    condition     = var.mesh_config_ingress_controller_mode == "UNSPECIFIED" || var.mesh_config_ingress_controller_mode == "OFF" || var.mesh_config_ingress_controller_mode == "DEFAULT" || var.mesh_config_ingress_controller_mode == "STRICT"
    error_message = "The mesh_config_ingress_controller_mode value must be one of the following: DEFAULT, OFF, STRICT, UNSPECIFIED"
  }
}

variable "mesh_config_ingress_service" {
  type        = string
  default     = "istio-ingressgateway"
  description = "Name of the Kubernetes service used for the istio ingress controller. If no ingress controller is specified, the default value istio-ingressgateway is used. Default to istio-ingressgateway. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig"
}

variable "mesh_config_ingress_selector" {
  description = "Defines which gateway deployment to use as the Ingress controller. This field corresponds to the Gateway.selector field, and will be set as istio: INGRESS_SELECTOR. By default, ingressgateway is used, which will select the default IngressGateway as it has the istio: ingressgateway labels. It is recommended that this is the same value as ingressService. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig"
  default     = "ingressgateway"
  type        = string
}

variable "force_controlplane_update" {
  description = "Force controlplane to be recreated when updated. Default to false (may require to taint the resource to apply changes)"
  default     = false
  type        = bool
  nullable    = false
}

variable "mesh_config_mesh_mtls" {
  description = "Defines the mesh mTLS configuration. For more details https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig and https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfigtlsconfig."
  type = object({
    minProtocolVersion : optional(string, "TLSV1_2")
    ecdhCurves : optional(list(string), null)
    cipherSuites : optional(list(string), ["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"])
  })
  nullable = false
  default = {
    minProtocolVersion : "TLSV1_2"
    cipherSuites : ["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"]
  }
}

variable "mesh_config_mesh_tls_defaults" {
  description = "Defines the TLS for all traffic except for ISTIO_MUTUAL mode For ISTIO_MUTUAL TLS settings, use var.mesh_config_mesh_mtls . For more details https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig and https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfigtlsconfig."
  type = object({
    minProtocolVersion : optional(string, "TLSV1_2")
    ecdhCurves : optional(list(string), null)
    cipherSuites : optional(list(string), ["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"])
  })
  nullable = false
  default = {
    minProtocolVersion : "TLSV1_2"
    cipherSuites : ["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"]
  }
}

variable "mesh_config_access_log_file" {
  description = "File address for the Istio proxy access log. Empty value disables access logging. Default to /dev/stdout"
  default     = "/dev/stdout"
  type        = string
}

variable "mesh_config_access_log_encoding" {
  description = "Encoding for the Istio proxy access log. Default value set to JSON. Allowed values TEXT or JSON"
  default     = "JSON"
  type        = string
  validation {
    condition     = var.mesh_config_access_log_encoding == "JSON" || var.mesh_config_access_log_encoding == "TEXT"
    error_message = "The mesh_config_access_log_encoding value must be one of the following: JSON, TEXT"
  }
}

variable "mesh_config_access_log_format" {
  description = "Format for the Istio proxy access log. Set to empty or null to use proxy's default access log format."
  default     = "[%START_TIME%] [%REQ(:AUTHORITY)%] [%BYTES_RECEIVED%] [%BYTES_SENT%] [%DOWNSTREAM_LOCAL_ADDRESS%] [%DOWNSTREAM_LOCAL_ADDRESS%] [%DOWNSTREAM_REMOTE_ADDRESS%] [%DOWNSTREAM_TLS_VERSION%] [%DURATION%] [%REQUEST_DURATION%] [%RESPONSE_DURATION%] [%RESPONSE_TX_DURATION%] [%DYNAMIC_METADATA(istio.mixer:status)%] [%REQ(:METHOD)%] [%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%] [%PROTOCOL%] [%REQ(X-REQUEST-ID)%] [%REQUESTED_SERVER_NAME%] [%RESPONSE_CODE%] [%RESPONSE_CODE_DETAILS%] [%RESPONSE_FLAGS%] [%ROUTE_NAME%] [%START_TIME%] [%UPSTREAM_CLUSTER%] [%UPSTREAM_HOST%] [%UPSTREAM_LOCAL_ADDRESS%] [%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%] [%UPSTREAM_TRANSPORT_FAILURE_REASON%] [%REQ(USER-AGENT)%] [%REQ(X-FORWARDED-FOR)%] [%REQ(X-ENVOY-ATTEMPT-COUNT)%]"
  type        = string
}

variable "rollback_on_failure" {
  description = "Flag to automatically rollback the helm chart on installation failure."
  type        = bool
  default     = true
}
