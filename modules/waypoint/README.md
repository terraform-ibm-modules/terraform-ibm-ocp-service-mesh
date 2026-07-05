# Waypoint Module

This module deploys istio-proxy pods also known as waypoint proxies by creating a Kubernetes deployment specifically for ambient mode. These proxies run as standalone pods and do not act as a sidecar container for application pods and these can be shared by multiple pods for efficient resource usage purpose. These istio-proxy additional pods can be used by applications to do Layer 7 filtering. It is required in ambient mode if L7 filtering is needed because application pods do not have istio-proxy sidecar running with them because of which layer 7 traffic filtering can't be done natively which was possible in traditional sidecar mode.

## Layer 7 Traffic Management with Waypoints

While ztunnel handles L4 traffic management efficiently, some use cases require **Layer 7 (L7) filtering** capabilities such as:

- Canary traffic splitting based on percentages
- Traffic routing based on HTTP headers
- Request/response manipulation
- Advanced routing rules

In traditional sidecar mode, these L7 features were handled by the Envoy proxy in each pod using resources like `VirtualService`, `DestinationRule`, etc.

### Waypoint Proxies

In ambient mode, L7 traffic management is handled by **waypoint proxies**. A waypoint is an optional L7 proxy that can be deployed to handle advanced traffic management.

This module creates two Kubernetes resources to deploy a waypoint:

1. A **ConfigMap** (`waypoint-config`) that holds the waypoint deployment configuration (replicas, resources, affinity, tolerations, labels, annotations for the Deployment and Service).

2. A **Gateway** resource with `gatewayClassName: istio-waypoint` that references the ConfigMap via `spec.infrastructure.parametersRef`.

### The `istio.io/waypoint-for` Label

The Gateway carries an `istio.io/waypoint-for` label that controls which traffic types the waypoint is eligible to intercept. Valid values are:

| Value | Behaviour |
|---|---|
| `service` | Waypoint proxies intercept traffic addressed to Services (default) |
| `workload` | Waypoint proxies intercept traffic addressed directly to pod IPs |
| `all` | Waypoint proxies intercept both service and workload traffic |
| `none` | Waypoint is deployed but intercepts no traffic |

### The `istio.io/use-waypoint` Label

Deploying a waypoint and setting `istio.io/waypoint-for` is only half the picture. The waypoint will not intercept any traffic unless the application side is also explicitly opted in using the `istio.io/use-waypoint` label, set to the name of the Gateway resource:

```
istio.io/use-waypoint: <gateway-name>
```

This label can be applied at three levels, in order of increasing granularity:

| Applied on | Effect |
|---|---|
| **Namespace** | All services and pods in the namespace use the waypoint. Individual services or pods can override this by setting their own `istio.io/use-waypoint` value. |
| **Service** | Only traffic to that specific Service is routed through the waypoint, regardless of namespace-level settings. |
| **Pod** | Only traffic to that specific pod is routed through the waypoint, regardless of namespace or service-level settings. |

**Important:** If `istio.io/use-waypoint` is not present on the namespace, the service, or the pod, the waypoint proxy is never invoked for that traffic — even if the Gateway and `istio.io/waypoint-for` are correctly configured.

#### Example — Enroll an entire namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: bookinfo
  labels:
    istio.io/dataplane-mode: ambient
    istio-discovery: enabled
    istio.io/use-waypoint: wp-gw  # Name of the waypoint gateway to use as proxy
    istio.io/use-waypoint-namespace: waypoint-ns # if waypoint gateway is present in same namespace as application namespace then this field can be omitted
```

#### Example — Enroll a single Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: reviews
  namespace: bookinfo
  labels:
    istio.io/use-waypoint: wp-gw # only traffic to this Service goes through the waypoint
    istio.io/use-waypoint-namespace: waypoint-ns # if waypoint gateway is present in same namespace as application namespace then this field can be omitted
```

### Example — Namespace Waypoint with HTTPRoute

After deploying this module, attach HTTPRoutes to your application service for L7 traffic management:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
```

Waypoints provide the same L7 capabilities as sidecars but with better resource efficiency since they are deployed only where needed, not in every pod.

## Prerequisites

The namespace where the waypoint is deployed must already exist. It only requires the `istio-discovery: enabled` label so that the Istio control plane can discover and manage it. The `istio.io/dataplane-mode: ambient` label is **not** required on the waypoint namespace — that label belongs on **application** namespaces whose workload traffic should be intercepted by ztunnel.

```yaml
metadata:
  name: waypoint-ns
  labels:
    istio-discovery: enabled  # Make discoverable by Istio control plane
```

This module sets `create_namespace = false` — the namespace must be created and labelled before calling this module.

## Learn More

For comprehensive information about Istio ambient mode, ztunnel, and waypoints, refer to the official Red Hat OpenShift Service Mesh documentation:

**[Red Hat OpenShift Service Mesh - Istio Ambient Mode](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.3/html/installing/ossm-istio-ambient-mode#ossm-about-istio-ambient-mode_ossm-istio-ambient-mode)**

This documentation covers:
- Detailed architecture of ambient mode
- Ztunnel deployment and configuration
- Waypoint proxy setup and usage
- Migration from sidecar to ambient mode
- Best practices and troubleshooting

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0, <4.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.waypoint](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_affinity"></a> [affinity](#input\_affinity) | Affinity configuration for the waypoint pods. Default to empty configuration. | <pre>object({<br/>    podAntiAffinity : optional(any, null),<br/>    podAffinity : optional(any, null),<br/>    nodeAffinity : optional(any, null)<br/>  })</pre> | `{}` | no |
| <a name="input_allowed_routes"></a> [allowed\_routes](#input\_allowed\_routes) | Controls which namespaces are allowed to attach routes to this Gateway listener. Valid values are Same (only the same namespace as the Gateway) and All (all namespaces). Default to All. | `string` | `"All"` | no |
| <a name="input_configmap_name"></a> [configmap\_name](#input\_configmap\_name) | Name of the waypoint ConfigMap resource. | `string` | `"waypoint-config"` | no |
| <a name="input_deployment_annotations"></a> [deployment\_annotations](#input\_deployment\_annotations) | Map of annotations to set under metadata.annotations of the waypoint Deployment in the ConfigMap. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_deployment_labels"></a> [deployment\_labels](#input\_deployment\_labels) | Map of labels to set under metadata.labels of the waypoint Deployment in the ConfigMap. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_gateway_annotations"></a> [gateway\_annotations](#input\_gateway\_annotations) | Map of annotations to set under spec.infrastructure.annotations of the Gateway resource. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_gateway_labels"></a> [gateway\_labels](#input\_gateway\_labels) | Map of labels to set under spec.infrastructure.labels of the Gateway resource. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_gateway_name"></a> [gateway\_name](#input\_gateway\_name) | Name of the waypoint Gateway resource. | `string` | `"wp-gw"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the waypoint resources will be deployed. | `string` | n/a | yes |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Number of replicas for the waypoint Deployment. Default to null to leverage on Istio default setting. | `number` | `null` | no |
| <a name="input_resources_configuration"></a> [resources\_configuration](#input\_resources\_configuration) | Waypoint pod resources configuration (cpu/memory requests and limits). Default to null to leverage on Istio default setting. | <pre>object(<br/>    {<br/>      limits : optional(object(<br/>        {<br/>          cpu : optional(string, null),<br/>          memory : optional(string, null)<br/>      }), null),<br/>      requests : optional(object(<br/>        {<br/>          cpu : optional(string, null)<br/>          memory : optional(string, null)<br/>      }), null)<br/>    }<br/>  )</pre> | `null` | no |
| <a name="input_rollback_on_failure"></a> [rollback\_on\_failure](#input\_rollback\_on\_failure) | Flag to automatically rollback the helm chart on installation failure. | `bool` | `true` | no |
| <a name="input_service_annotations"></a> [service\_annotations](#input\_service\_annotations) | Map of annotations to set under metadata.annotations of the waypoint Service in the ConfigMap. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_service_labels"></a> [service\_labels](#input\_service\_labels) | Map of labels to set under metadata.labels of the waypoint Service in the ConfigMap. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | Tolerations to apply to the waypoint pods. Default to a single entry tolerating all taints. | <pre>list(object({<br/>    key                = optional(string)<br/>    operator           = optional(string)<br/>    value              = optional(string)<br/>    effect             = optional(string)<br/>    toleration_seconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_waypoint_for"></a> [waypoint\_for](#input\_waypoint\_for) | Value for the istio.io/waypoint-for label on the Gateway. Controls which traffic types are intercepted by the waypoint. Valid values are: service, workload, all, none. Default to service. | `string` | `"service"` | no |
| <a name="input_waypoint_pod_annotations"></a> [waypoint\_pod\_annotations](#input\_waypoint\_pod\_annotations) | Map of annotations to set under spec.template.metadata.annotations of the waypoint Deployment in the ConfigMap. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_waypoint_pod_labels"></a> [waypoint\_pod\_labels](#input\_waypoint\_pod\_labels) | Map of labels to set under spec.template.metadata.labels of the waypoint Deployment in the ConfigMap. Default to empty map. | `map(string)` | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_waypoint_release_name"></a> [waypoint\_release\_name](#output\_waypoint\_release\_name) | Helm release name for the waypoint |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
