# Ztunnel Module

This module deploys the ztunnel component for Istio ambient mode on OpenShift clusters.

## About Istio Ambient Mode and Ztunnel

### Traditional Istio Sidecar vs Ambient Mode

In traditional Istio dataplane deployments, each pod that is part of the service mesh comes with a **sidecar container** (Envoy proxy) that handles all traffic management, security, and observability features. While powerful, this approach has some drawbacks:

- **Resource overhead**: Each pod requires additional CPU and memory for the sidecar
- **Scaling challenges**: As the number of pods increases, so does the resource consumption
- **Complexity**: Managing sidecar injection and lifecycle can be complex

### What is Ztunnel?

**Ztunnel** (Zero Trust Tunnel) is a key component of Istio's ambient mode that fundamentally changes how the service mesh operates. Instead of deploying a sidecar container in each application pod, ztunnel runs as a **node-level DaemonSet pod** that intercepts traffic at the **Layer 4 (L4) level**.

#### Key Benefits:

- **Significantly reduced resource usage**: No per-pod sidecar overhead means lower CPU and memory consumption for applications
- **Simplified operations**: No sidecar injection required
- **Transparent mTLS**: Handles mutual TLS encryption/decryption at the node level
- **Zero-trust security**: Provides secure communication between services without application changes
- **Better scalability**: Resource usage scales with nodes, not pods

Ztunnel intercepts network traffic and provides:
- Mutual TLS (mTLS) encryption between services
- L4 authorization policies
- Telemetry collection
- Traffic routing at the network layer

## Prerequisites

To deploy ztunnel in ambient mode, the following configuration requirements must be met:

### 1. Istio Resource Configuration

Your Istio resource **must** have the **ambient profile** enabled and reference the ztunnel namespace.

Additionally, you must set `trustedZtunnelNamespace` under the `pilot` configuration in your Istio resource:

```yaml
pilot:
  trustedZtunnelNamespace: ztunnel
```

### 2. IstioCNI Resource Configuration

Your IstioCNI resource **must** also have the **ambient profile** enabled to support ambient mode operations.

### 3. Ztunnel Namespace Configuration

The ztunnel namespace **must be discoverable** by the Istio Control Plane. This is achieved by setting the appropriate label on the namespace:

```yaml
metadata:
  name: ztunnel-ns
  labels:
    istio-discovery: enabled  # Required for Istio discovery
```

**Important:** Create the namespace separately with the proper labels before deploying ztunnel.

## Application Namespace Configuration

For applications to participate in the ambient mesh and have their traffic intercepted by ztunnel, the application namespace must be properly configured with specific labels:

### Required Labels

1. **Ambient Mode Label**: The namespace must have the `istio.io/dataplane-mode=ambient` label to enable ztunnel traffic interception:

```yaml
metadata:
  name: my-app-namespace
  labels:
    istio.io/dataplane-mode: ambient
```

This label signals to ztunnel that pods in this namespace should have their traffic intercepted and managed at the L4 level.

2. **Istio Discovery Label**: The namespace must also be discoverable by the Istio Control Plane by satisfying the Istio `discoverySelectors` condition. This is typically achieved by adding the `istio-discovery: enabled` label:

```yaml
metadata:
  name: my-app-namespace
  labels:
    istio.io/dataplane-mode: ambient
    istio-discovery: enabled
```

### Complete Example

Here's a complete example of an application namespace configured for ambient mode:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app-namespace
  labels:
    istio.io/dataplane-mode: ambient  # Enable ambient mode
    istio-discovery: enabled           # Make discoverable by Istio
```

**Important Notes:**
- Without the `istio.io/dataplane-mode=ambient` label, ztunnel will not intercept traffic for pods in the namespace
- Without satisfying the Istio `discoverySelectors` condition (typically via `istio-discovery: enabled`), the Istio Control Plane will not manage the namespace
- Both labels are required for proper ambient mesh functionality

## Layer 7 Traffic Management with Waypoints

While ztunnel handles L4 traffic management efficiently, some use cases require **Layer 7 (L7) filtering** capabilities such as:

- Canary traffic splitting based on percentages
- Traffic routing based on HTTP headers
- Request/response manipulation
- Advanced routing rules

In traditional sidecar mode, these L7 features were handled by the Envoy proxy in each pod using resources like `VirtualService`, `DestinationRule`, etc.

### Waypoint Proxies

In ambient mode, L7 traffic management is handled by **waypoint proxies**. A waypoint is an optional L7 proxy that can be deployed per namespace or per service account to handle advanced traffic management.

To create a waypoint:

1. Create a Kubernetes Gateway with the `istio-waypoint` gateway class:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bookinfo-gateway
  namespace: bookinfo
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
```

2. Attach HTTPRoutes to your services for L7 filtering:

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

Waypoints provide the same L7 capabilities as sidecars but with better resource efficiency since they're deployed only where needed, not in every pod.

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
| [helm_release.ztunnel](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where to install ZTunnel | `string` | `"ztunnel"` | no |
| <a name="input_rollback_on_failure"></a> [rollback\_on\_failure](#input\_rollback\_on\_failure) | Flag to automatically rollback the helm chart on installation failure. | `bool` | `true` | no |
| <a name="input_ztunnel_resources_configuration"></a> [ztunnel\_resources\_configuration](#input\_ztunnel\_resources\_configuration) | ZTunnel resources deployment configuration (cpu/memory requests and limits). Default configuration is null and leverages on Istio default setting. | <pre>object(<br/>    {<br/>      limits : optional(object(<br/>        {<br/>          cpu : optional(string, null),<br/>          memory : optional(string, null)<br/>      }), null),<br/>      requests : optional(object(<br/>        {<br/>          cpu : optional(string, null)<br/>          memory : optional(string, null)<br/>      }), null)<br/>    }<br/>  )</pre> | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_ztunnel_release_name"></a> [ztunnel\_release\_name](#output\_ztunnel\_release\_name) | Helm release name for ZTunnel |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
