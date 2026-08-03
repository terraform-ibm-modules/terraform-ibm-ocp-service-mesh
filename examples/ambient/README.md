# Ambient Mode Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=ocp-service-mesh-ambient-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/examples/ambient">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example demonstrates deploying Istio service mesh in ambient mode (sidecarless) on an IBM Cloud OpenShift cluster.

For a full explanation of how ambient mode differs from sidecar mode, see [docs/sidecar-vs-ambient.md](../../docs/sidecar-vs-ambient.md).

## What this example deploys

| Resource | Module | Purpose |
|---|---|---|
| Istio control plane (ambient profile) | [modules/sm-istio](../../modules/sm-istio) | Core control plane with `is_ambient_mode = true` and `ztunnel_namespace` set |
| IstioCNI (ambient profile) | [modules/sm-istio-cni](../../modules/sm-istio-cni) | CNI plugin with `is_ambient_mode = true` |
| Ztunnel DaemonSet | [modules/ztunnel](../../modules/ztunnel) | Node-level L4 proxy running in `ztunnel-ns` namespace |
| Ingress gateway | [modules/sm-istio-ingress](../../modules/sm-istio-ingress) | ALB-type ingress gateway in `alb-ingress` namespace |
| East-west waypoint (`wp-gw`) | [modules/waypoint](../../modules/waypoint) | Deployed in `waypoint-ns`; used for L7 filtering of httpbin traffic (canary routing, header-based routing, etc.) via `HTTPRoute` |
| Egress waypoint (`waypoint-egress-gateway`) | [modules/waypoint](../../modules/waypoint) | Deployed in `istio-egress-ns`; acts as an egress gateway — outbound traffic for external domains is routed through it via a `ServiceEntry` |
| Sample httpbin app | Helm chart | Deployed in `httpbin` namespace, enrolled in the ambient mesh |

## Ambient Mode Configuration

Ambient mode is enabled by the following settings in [`main.tf`](./main.tf):

```hcl
# 1. Istiod — ambient profile + trusted ztunnel namespace
module "deploy_istio" {
  source            = "../../modules/sm-istio"
  is_ambient_mode   = true
  ztunnel_namespace = "ztunnel-ns"
  ...
}

# 2. IstioCNI — ambient profile
module "deploy_istio_cni" {
  source          = "../../modules/sm-istio-cni"
  is_ambient_mode = true
  ...
}

# 3. Ztunnel DaemonSet
module "deploy_ztunnel" {
  source    = "../../modules/ztunnel"
  namespace = "ztunnel-ns"
  ...
}
```

## Application Namespace Labels

Instead of sidecar injection, application namespaces carry ambient-mode labels. The `httpbin` namespace in this example is configured as follows:

```yaml
labels:
  istio-discovery: enabled                     # makes namespace visible to Istiod
  istio.io/dataplane-mode: ambient             # enrolls pods into the ambient mesh (ztunnel intercepts traffic)
  istio.io/use-waypoint: wp-gw                 # routes traffic through the east-west waypoint for L7 filtering
  istio.io/use-waypoint-namespace: waypoint-ns # waypoint lives in a different namespace than the app
```

## Two Waypoint Deployments

This example intentionally deploys **two separate waypoints** for different purposes:

### 1. East-west waypoint (`wp-gw` in `waypoint-ns`)

Used for **inbound L7 traffic management** for the httpbin application. By labelling the `httpbin` namespace with `istio.io/use-waypoint: wp-gw`, all traffic destined for httpbin services passes through this waypoint. This enables:
- Canary traffic splitting (e.g. 90/10 weight between `httpbin-v1` and `httpbin-v2`)
- Header-based routing
- `AuthorizationPolicy` enforcement at L7

See [modules/waypoint README](../../modules/waypoint/README.md) for details on `HTTPRoute` examples.

### 2. Egress waypoint (`waypoint-egress-gateway` in `istio-egress-ns`)

Used for **outbound traffic control** to external destinations. A `ServiceEntry` resource with the label `istio.io/use-waypoint: waypoint-egress-gateway` causes ztunnel to route all outbound traffic matching that entry through the egress waypoint proxies. This provides a single point of egress observability and policy enforcement without a dedicated Istio egress gateway.

See the [Waypoint as Egress Gateway](../../modules/waypoint/README.md#waypoint-as-egress-gateway) section of the waypoint README for a `ServiceEntry` example.
