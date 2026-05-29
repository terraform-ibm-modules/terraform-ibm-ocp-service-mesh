# Service Mesh Istio module

## Overview
This module deploys the Istio resource that defines a single Istio controlplane on a cluster

### Discovery selectors configuration

This module allows to setup the controlplane discovery selectors according to the controlplane name or to customise the selectors according to user's own labels and keys, following the Red Hat Service Mesh [requirements](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-installing-service-mesh#ossm-scoping-service-mesh-with-discoveryselectors_ossm-installing-openshift-service-mesh)

- if the input parameter `var.istio_discovery_custom_configuration` is left to its default value `null` the controlplane discovery selector is configured with the following logic:
  - if the Istio controlplane name (`var.name`) is left to its default value `default` the discovery selectors are set with `"matchLabels" : { "istio-discovery" : "enabled" }` configuration
  - if the Istio controlplane name (`var.name`) is not set to `default` the discovery selectors are set with `"matchLabels" : { "istio-discovery" : var.name }`
- if the input parameter `var.istio_discovery_custom_configuration` is customised its values are configured into the discovery selectors of the controlplane

For the controlplane namespace, that must be configured with the same discovery selectors set for the controlplane discovery, it is possible to follow a similar logic through the input variable `var.istio_namespace_discovery_custom_labels`:
- if left to its default `null` value the controlplane namespace is labeled with `{ "istio-discovery" = "enabled" }` if the controlplane name is the default value `default` or with `{ "istio-discovery" : var.name }` if the controlplane name is not `default`
- if not null, it will be used to label the controlplane namespace

### Example: Basic default configuration

This configuration deploys a default Istio controlplane with the default configurations for controlplane named `default` and discovery selectors `"matchLabels" : { "istio-discovery" : "enabled" }`

```
module "deploy_istio" {
  depends_on               = [module.service_mesh_operator]
  source                   = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio"
  version                  = "X.Y.Z"
  name                     = "default"
  namespace                = "istio-system"
  create_namespace         = true
  cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}
```

### Affinity and Antiaffinity configuration

Through the input variable `pilot_affinity` it is possible to configure the following affinity attributes:

- podAntiAffinity
- podAffinity
- nodeAffinity

The content of each of these map keys is then converted to the yaml configuration. For example to make the pilot pods to avoid to run on the same worker you can use the following antiAffinity configuration:

```
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
```

### Pilot pods node selectors

Through the input variable `pilot_node_selector` it is possible to configure the node selectors key and values that are used to configure the pods node selectors.
For example to configure the pilot pods to run on the worker nodes labeled with label key `ibm-cloud.kubernetes.io/worker-pool-name` and with value `default` set the following content

```
{ "ibm-cloud.kubernetes.io/worker-pool-name" : "default" }
```

### Pilot pods resources requests and limits

Through the input variable `pilot_resources` you can set the following pilot pods resources configuration:
- cpu limits
- memory limits
- cpu initial request
- memory initial request

The default values are the below ones:
```
{
  limits : {
    cpu : "100m"
    memory : "256M"
  },
  requests : {
    cpu : "10m"
    memory : "128M"
  }
}
```

### DNS Capture Configuration for ServiceEntry Resources

DNS capture is **enabled by default** in this module to support ServiceEntry resources that rely on DNS resolution. The default configuration sets `ISTIO_META_DNS_AUTO_ALLOCATE` and `ISTIO_META_DNS_CAPTURE` to `"true"` in the proxy metadata.

**Important:** ServiceEntry resources that use DNS resolution require DNS capture to be enabled. Disabling it will result in application errors such as "Name or service not known" when accessing external services.

#### Configuration Options

- **Default behavior**: DNS capture is enabled automatically. See the [basic example](../../examples/basic) for a working configuration.
- **Disabling DNS capture**: Set `ISTIO_META_DNS_AUTO_ALLOCATE` and `ISTIO_META_DNS_CAPTURE` to `"false"` in the `proxy_metadata` variable.
- **Adding proxy settings**: Use the `proxy_metadata` variable to add HTTP proxy configuration or other custom metadata while preserving DNS capture defaults.

For complete configuration examples, see the [examples folder](../../examples/).

### Example: Advanced configuration

The following controlplane is configured with the following attributes:
- name: `mesh-2`
- namespace: `istio-system-2`
- discovery selector: match on the label `istio-discovery = "mesh-2"`
- controlplane force to be recreated when the resource is updated (default to not force, which may need to taint the resource to update)
- ServiceMesh mTLS enabled (default)
- pilot autoscaling enabled with max and min pods, target memory and cpu
- pilot pods node selector set to nodes label `"ibm-cloud.kubernetes.io/worker-pool-name": "default"`
- pilot pods toleration
- pilot resources requests and limits for memory and CPU
- tcp keep alive for the mesh

```
module "istio" {
  depends_on       = [module.service_mesh]
  source           = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio"
  version          = "X.Y.Z"
  name             = "mesh-2"
  namespace        = "istio-system-2"
  istio_discovery_custom_configuration = {
    matchLabels = {
        istio-discovery = "mesh-2"
    }
  force_controlplane_update = true
  mesh_config_enable_mtls = true
  pilot_autoscaling_enabled = true
  pilot_autoscaling_max_pods = 10
  pilot_autoscaling_min_pods = 3
  pilot_autoscaling_target_memory = 75
  pilot_autoscaling_target_cpu = 70
  pilot_node_selector = { "ibm-cloud.kubernetes.io/worker-pool-name": "default" }
  pilot_tolerations = [
    {
      key : "dedicated"
      value : "transit"
      effect : "NoExecute"
    }
  ]
  pilot_resources = {
    "requests": {
      "cpu": "200m"
      "memory": "128Mi"
    }
    "limits": {
      "cpu": "500m"
      "memory": "256Mi"
    }
  }
  mesh_config_tcp_keep_alive = {
    probes = 10
  }
  cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}
```

For all the configuration parameters details refer to the section below

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0, <4.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 3.0.1, < 4.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_istio_namespace"></a> [istio\_namespace](#module\_istio\_namespace) | terraform-ibm-modules/namespace/ibm | v2.0.1 |

### Resources

| Name | Type |
|------|------|
| [helm_release.istio_controlplane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_annotations.istio_namespace_annotations](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [kubernetes_labels.istio_namespace_labels](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/labels) | resource |
| [null_resource.confirm_istio_operational](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_istio_labels_annotations_to_existing_namespace"></a> [add\_istio\_labels\_annotations\_to\_existing\_namespace](#input\_add\_istio\_labels\_annotations\_to\_existing\_namespace) | Flag to add istio labels and annotations like the discovery ones or the value of var.istio\_namespace\_discovery\_custom\_labels to an existing namespace. Default to false. If var.create\_namespace is true this flag is ignored. | `bool` | `false` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Id of the target IBM Cloud OpenShift Cluster | `string` | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Flag to create the namespace where to install istio controlplane. Default to true | `bool` | `true` | no |
| <a name="input_enable_dns_capture"></a> [enable\_dns\_capture](#input\_enable\_dns\_capture) | Enable DNS capture for ServiceEntry resources. When enabled, automatically sets ISTIO\_META\_DNS\_AUTO\_ALLOCATE and ISTIO\_META\_DNS\_CAPTURE to 'true' in proxy metadata. Required for ServiceEntry resources that rely on DNS resolution. [Learn more](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html-single/migrating_from_service_mesh_2_to_service_mesh_3/index#ossm-migrating-read-me-dns-capture-configuration_ossm-migrating-read-me) | `bool` | `true` | no |
| <a name="input_force_controlplane_update"></a> [force\_controlplane\_update](#input\_force\_controlplane\_update) | Force controlplane to be recreated when updated. Default to false (may require to taint the resource to apply changes) | `bool` | `false` | no |
| <a name="input_istio_discovery_custom_configuration"></a> [istio\_discovery\_custom\_configuration](#input\_istio\_discovery\_custom\_configuration) | Istio controlplane discovery label. Default to null to autogenerate the labels according to var.name value to matchLabels: {"istio-discovery" : "enabled"}. For more details https://istio.io/latest/blog/2021/discovery-selectors/ https://github.com/istio/api/blob/master/mesh/v1alpha1/config.proto#L1411 https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-installing-service-mesh#ossm-discoveryselectors-scope-service-mesh_ossm-installing-openshift-service-mesh | <pre>object({<br/>    matchLabels : optional(map(string), null),<br/>    matchExpressions : optional(list(object({<br/>      key : string<br/>      operator : string<br/>      values : list(string)<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_istio_enable_default_pod_disruption_budget"></a> [istio\_enable\_default\_pod\_disruption\_budget](#input\_istio\_enable\_default\_pod\_disruption\_budget) | Controls whether a PodDisruptionBudget with a default minAvailable value of 1 is created for each deployment. Default to null, using Istio default configuration. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#defaultpoddisruptionbudgetconfig | `bool` | `null` | no |
| <a name="input_istio_enable_network_policy"></a> [istio\_enable\_network\_policy](#input\_istio\_enable\_network\_policy) | Enable Istio to deploy its Network Policy. Default to true. For more details refer to https://istio.io/latest/docs/setup/additional-setup/network-policy/ | `bool` | `true` | no |
| <a name="input_istio_namespace_add_discovery_for_workload"></a> [istio\_namespace\_add\_discovery\_for\_workload](#input\_istio\_namespace\_add\_discovery\_for\_workload) | Flag to automatically generate and add the labels and annotations for the workload enrollment and istio injection to the Istio namespace. This would allow to enable istio injection into the istio namespace in order to run the workload gateways and the workload itself in the same namespace. If var.istio\_namespace\_discovery\_custom\_labels is not empty this value is ignored. Default to false. | `bool` | `false` | no |
| <a name="input_istio_namespace_discovery_custom_labels"></a> [istio\_namespace\_discovery\_custom\_labels](#input\_istio\_namespace\_discovery\_custom\_labels) | Istio controlplane discovery label to apply to controlplane namespace. Default to null to autogenerate the labels according to var.name to {"istio-discovery" : "enabled"}. If overridden consider it to be coherent with selectors of var.istio\_discovery\_configuration. For more details https://istio.io/latest/blog/2021/discovery-selectors/ | `map(string)` | `null` | no |
| <a name="input_istio_update_strategy_type"></a> [istio\_update\_strategy\_type](#input\_istio\_update\_strategy\_type) | Type of strategy to use. Allowed values are InPlace or RevisionBased. When InPlace strategy is used, the existing Istio control plane is updated in-place. When the RevisionBased strategy is used, a new Istio control plane instance is created for every change to the Istio.spec.version field. For more details refer to https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#updatestrategytype. Default to InPlace | `string` | `"InPlace"` | no |
| <a name="input_mesh_config_access_log_encoding"></a> [mesh\_config\_access\_log\_encoding](#input\_mesh\_config\_access\_log\_encoding) | Encoding for the Istio proxy access log. Default value set to JSON. Allowed values TEXT or JSON | `string` | `"JSON"` | no |
| <a name="input_mesh_config_access_log_file"></a> [mesh\_config\_access\_log\_file](#input\_mesh\_config\_access\_log\_file) | File address for the Istio proxy access log. Empty value disables access logging. Default to /dev/stdout | `string` | `"/dev/stdout"` | no |
| <a name="input_mesh_config_access_log_format"></a> [mesh\_config\_access\_log\_format](#input\_mesh\_config\_access\_log\_format) | Format for the Istio proxy access log. Set to empty or null to use proxy's default access log format. | `string` | `"[%START_TIME%] [%REQ(:AUTHORITY)%] [%BYTES_RECEIVED%] [%BYTES_SENT%] [%DOWNSTREAM_LOCAL_ADDRESS%] [%DOWNSTREAM_LOCAL_ADDRESS%] [%DOWNSTREAM_REMOTE_ADDRESS%] [%DOWNSTREAM_TLS_VERSION%] [%DURATION%] [%REQUEST_DURATION%] [%RESPONSE_DURATION%] [%RESPONSE_TX_DURATION%] [%DYNAMIC_METADATA(istio.mixer:status)%] [%REQ(:METHOD)%] [%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%] [%PROTOCOL%] [%REQ(X-REQUEST-ID)%] [%REQUESTED_SERVER_NAME%] [%RESPONSE_CODE%] [%RESPONSE_CODE_DETAILS%] [%RESPONSE_FLAGS%] [%ROUTE_NAME%] [%START_TIME%] [%UPSTREAM_CLUSTER%] [%UPSTREAM_HOST%] [%UPSTREAM_LOCAL_ADDRESS%] [%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%] [%UPSTREAM_TRANSPORT_FAILURE_REASON%] [%REQ(USER-AGENT)%] [%REQ(X-FORWARDED-FOR)%] [%REQ(X-ENVOY-ATTEMPT-COUNT)%]"` | no |
| <a name="input_mesh_config_connect_timeout"></a> [mesh\_config\_connect\_timeout](#input\_mesh\_config\_connect\_timeout) | Connection timeout used by Envoy. Default to 10s | `string` | `"10s"` | no |
| <a name="input_mesh_config_enable_mtls"></a> [mesh\_config\_enable\_mtls](#input\_mesh\_config\_enable\_mtls) | Enable mTLS in the Istio controlplane. Default to true | `bool` | `true` | no |
| <a name="input_mesh_config_extension_providers"></a> [mesh\_config\_extension\_providers](#input\_mesh\_config\_extension\_providers) | List of mesh-wide extension providers to place under spec.values.meshConfig.extensionProviders. Default to null. | `list(any)` | `null` | no |
| <a name="input_mesh_config_ingress_controller_mode"></a> [mesh\_config\_ingress\_controller\_mode](#input\_mesh\_config\_ingress\_controller\_mode) | Istio Mesh configuration for ingress controller mode. Default to STRICT. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfigingresscontrollermode | `string` | `"STRICT"` | no |
| <a name="input_mesh_config_ingress_selector"></a> [mesh\_config\_ingress\_selector](#input\_mesh\_config\_ingress\_selector) | Defines which gateway deployment to use as the Ingress controller. This field corresponds to the Gateway.selector field, and will be set as istio: INGRESS\_SELECTOR. By default, ingressgateway is used, which will select the default IngressGateway as it has the istio: ingressgateway labels. It is recommended that this is the same value as ingressService. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig | `string` | `"ingressgateway"` | no |
| <a name="input_mesh_config_ingress_service"></a> [mesh\_config\_ingress\_service](#input\_mesh\_config\_ingress\_service) | Name of the Kubernetes service used for the istio ingress controller. If no ingress controller is specified, the default value istio-ingressgateway is used. Default to istio-ingressgateway. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig | `string` | `"istio-ingressgateway"` | no |
| <a name="input_mesh_config_mesh_mtls"></a> [mesh\_config\_mesh\_mtls](#input\_mesh\_config\_mesh\_mtls) | Defines the mesh mTLS configuration. For more details https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig and https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfigtlsconfig. | <pre>object({<br/>    minProtocolVersion : optional(string, "TLSV1_2")<br/>    ecdhCurves : optional(list(string), null)<br/>    cipherSuites : optional(list(string), ["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"])<br/>  })</pre> | <pre>{<br/>  "cipherSuites": [<br/>    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",<br/>    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",<br/>    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",<br/>    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"<br/>  ],<br/>  "minProtocolVersion": "TLSV1_2"<br/>}</pre> | no |
| <a name="input_mesh_config_mesh_tls_defaults"></a> [mesh\_config\_mesh\_tls\_defaults](#input\_mesh\_config\_mesh\_tls\_defaults) | Defines the TLS for all traffic except for ISTIO\_MUTUAL mode For ISTIO\_MUTUAL TLS settings, use var.mesh\_config\_mesh\_mtls . For more details https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfig and https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#meshconfigtlsconfig. | <pre>object({<br/>    minProtocolVersion : optional(string, "TLSV1_2")<br/>    ecdhCurves : optional(list(string), null)<br/>    cipherSuites : optional(list(string), ["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384", "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"])<br/>  })</pre> | <pre>{<br/>  "cipherSuites": [<br/>    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",<br/>    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",<br/>    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",<br/>    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"<br/>  ],<br/>  "minProtocolVersion": "TLSV1_2"<br/>}</pre> | no |
| <a name="input_mesh_config_tcp_keep_alive"></a> [mesh\_config\_tcp\_keep\_alive](#input\_mesh\_config\_tcp\_keep\_alive) | Istio configuration for TCP keepalive. Default to null, using the Istio default configuration. More details at https://github.com/istio-ecosystem/sail-operator/blob/main/docs/api-reference/sailoperator.io.md#connectionpoolsettingstcpsettingstcpkeepalive | <pre>object({<br/>    probes : optional(number, 9),<br/>    time : optional(string, "7200s")<br/>    interval : optional(string, "75s")<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Istio controlplane revision | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where to install istio controlplane. | `string` | n/a | yes |
| <a name="input_outboundtrafficpolicy"></a> [outboundtrafficpolicy](#input\_outboundtrafficpolicy) | Istio controlplane output traffic policy configuration. Default to ALLOW\_ANY. Values allowed ALLOW\_ANY or REGISTRY\_ONLY | `string` | `"ALLOW_ANY"` | no |
| <a name="input_peer_authentication_name"></a> [peer\_authentication\_name](#input\_peer\_authentication\_name) | Name of the PeerAuthentication policy. Default to null to autogenerate the name as '<controlplane-name>-peerauthentication'. | `string` | `null` | no |
| <a name="input_pilot_affinity"></a> [pilot\_affinity](#input\_pilot\_affinity) | Istio pilot pods affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Default to empty configuration | <pre>object({<br/>    podAntiAffinity : optional(any, null),<br/>    podAffinity : optional(any, null),<br/>    nodeAffinity : optional(any, null)<br/>  })</pre> | `{}` | no |
| <a name="input_pilot_autoscaling_enabled"></a> [pilot\_autoscaling\_enabled](#input\_pilot\_autoscaling\_enabled) | Enable Istio pilot autoscaling through HorizontalPodAutoscaler. Default to false | `bool` | `false` | no |
| <a name="input_pilot_autoscaling_max_pods"></a> [pilot\_autoscaling\_max\_pods](#input\_pilot\_autoscaling\_max\_pods) | If var.pilot\_autoscaling\_enabled is enabled this sets the maximum amount of pods for Istio pilot HorizontalPodAutoscaler. Default to 5 | `number` | `5` | no |
| <a name="input_pilot_autoscaling_min_pods"></a> [pilot\_autoscaling\_min\_pods](#input\_pilot\_autoscaling\_min\_pods) | If var.pilot\_autoscaling\_enabled is enabled this sets the minimum amount of pods for Istio pilot HorizontalPodAutoscaler. Default to 1 | `number` | `1` | no |
| <a name="input_pilot_autoscaling_target_cpu"></a> [pilot\_autoscaling\_target\_cpu](#input\_pilot\_autoscaling\_target\_cpu) | If var.pilot\_autoscaling\_enabled is enabled this sets the target CPU average load. Default to 80 (%). Set to null to leverage on Istio default value. | `number` | `80` | no |
| <a name="input_pilot_autoscaling_target_memory"></a> [pilot\_autoscaling\_target\_memory](#input\_pilot\_autoscaling\_target\_memory) | If var.pilot\_autoscaling\_enabled is enabled this sets the target memory average load. Default to 80 (%). Set to null to leverage on Istio default value. | `number` | `80` | no |
| <a name="input_pilot_enabled"></a> [pilot\_enabled](#input\_pilot\_enabled) | Enable Istio pilot. Default to true. | `bool` | `true` | no |
| <a name="input_pilot_env"></a> [pilot\_env](#input\_pilot\_env) | Optional key-value map of environment variables to set on Istio Pilot deployment. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_pilot_node_selector"></a> [pilot\_node\_selector](#input\_pilot\_node\_selector) | Node selector configuration for Istio pilot pods. Default to null. For more details https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector | `map(string)` | `null` | no |
| <a name="input_pilot_replicas"></a> [pilot\_replicas](#input\_pilot\_replicas) | Sets the number of replicas to deploy the Istio Pilot. Valid only if var.pilot\_autoscaling\_enabled is false. Default to 1 | `number` | `1` | no |
| <a name="input_pilot_resources"></a> [pilot\_resources](#input\_pilot\_resources) | Istio pilot pods resources requests and limits for memory and CPU. Default to requests CPU 10m memory 128M limits CPU 100m memory 256M, using the default Istio values. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#resourcerequirements-v1-core | <pre>object({<br/>    limits : optional(map(string), null),<br/>    requests : optional(map(string), null)<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "cpu": "100m",<br/>    "memory": "256M"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "128M"<br/>  }<br/>}</pre> | no |
| <a name="input_pilot_tolerations"></a> [pilot\_tolerations](#input\_pilot\_tolerations) | Istio pilot pods tolerations configuration. Default to empty list. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core | `list(any)` | `[]` | no |
| <a name="input_proxy_metadata"></a> [proxy\_metadata](#input\_proxy\_metadata) | Additional key-value pairs to configure meshConfig.defaultConfig.proxyMetadata. Use this to add custom proxy metadata like HTTP\_PROXY, HTTPS\_PROXY, etc. When enable\_dns\_capture is true, do not include ISTIO\_META\_DNS\_AUTO\_ALLOCATE or ISTIO\_META\_DNS\_CAPTURE here (use the enable\_dns\_capture flag instead). When enable\_dns\_capture is false, you can set these keys directly in proxy\_metadata if needed. | `map(string)` | `{}` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group for the OpenShift Cluster. | `string` | n/a | yes |
| <a name="input_rollback_on_failure"></a> [rollback\_on\_failure](#input\_rollback\_on\_failure) | Flag to automatically rollback the helm chart on installation failure. | `bool` | `true` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_istio_metadata"></a> [istio\_metadata](#output\_istio\_metadata) | Istio definition metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
