# Sidecar Mode vs Ambient Mode

This document compares the two Istio dataplane modes — **sidecar** and **ambient** — and describes how each component is deployed and managed within this Terraform module collection. Use this as a guide when choosing a mode or when migrating from sidecar to ambient.

## Background

Istio traditionally operated in **sidecar mode**, where an Envoy proxy is injected as a sidecar container into every application pod. While powerful, this approach adds per-pod resource overhead and operational complexity.

**Ambient mode** removes the per-pod sidecar entirely. Instead, a lightweight node-level component (ztunnel) handles L4 traffic for all pods on a node. Optional waypoint proxies can be introduced on a per-namespace or per-service basis when L7 capabilities are needed, keeping the resource footprint minimal and targeted.

## Component Comparison

| Component | Sidecar Mode | Ambient Mode |
|---|---|---|
| **Istiod** | Deployed using [modules/sm-istio](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/sm-istio). Standard `Istio` custom resource with the default profile. | Deployed using [modules/sm-istio](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/sm-istio) with the same chart, but `spec.profile` is explicitly set to `ambient`. Additionally, `spec.values.pilot.trustedZtunnelNamespace` must be set to the namespace in which ztunnel is installed so that Istiod trusts the ztunnel component. |
| **IstioCNI** | Deployed using [modules/sm-istio-cni](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/sm-istio-cni). Standard `IstioCNI` custom resource with the default profile. | Deployed using [modules/sm-istio-cni](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/sm-istio-cni) with the same chart, but `spec.profile` is explicitly set to `ambient` to enable ambient-mode CNI support. |
| **Ztunnel** | Not used. In sidecar mode, each application pod carries its own Envoy sidecar proxy that intercepts all inbound and outbound traffic. | Deployed as a DaemonSet using [modules/ztunnel](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/ztunnel), which creates a `ZTunnel` custom resource. A ztunnel pod runs on every node in the cluster. All traffic to and from application pods is transparently intercepted by the ztunnel pod co-located on the same node, providing L4 mTLS, authorization, and telemetry without any per-pod proxy. |
| **Ingress** | Deployed using [modules/sm-istio-ingress](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/sm-istio-ingress). | Deployed using [modules/sm-istio-ingress](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/sm-istio-ingress). There are no differences between the two modes for ingress. |
| **Egress** | Deployed using [modules/sm-istio-egress](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/sm-istio-egress) to run a dedicated Istio egress gateway. | Instead of a dedicated egress gateway, [modules/waypoint](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/waypoint) can be used to create a Kubernetes `Gateway` resource that runs standalone pods using the Istio proxy image. A `ServiceEntry` resource pointing to the name of that `Gateway` routes outbound traffic for a given domain through the waypoint proxies, providing the same level of egress control and observability. |
| **Proxy / L7 Filtering** | Each application pod runs alongside an Envoy sidecar that intercepts inbound and outbound traffic natively. Istio resources such as `VirtualService` and `AuthorizationPolicy` provide full L7 traffic management out of the box. | There are no per-pod sidecars. For L7 filtering, [modules/waypoint](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/waypoint) creates a Kubernetes `Gateway` resource that deploys a set of standalone pods running the Istio proxy image. `HTTPRoute` and other Gateway API resources can then be applied to perform L7 routing, header-based matching, and traffic splitting. Waypoints can be scoped to a namespace or a specific service, so only the traffic that requires L7 processing passes through them. See [modules/waypoint/README.md](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/waypoint) for full details. |
| **Resource Efficiency** | Every application pod carries an Envoy sidecar container, resulting in additional CPU and memory consumption that scales with the total number of pods in the mesh. | Ztunnel runs as a single node-level pod per node rather than alongside every container, resulting in significantly lower resource usage. When L7 filtering is required, waypoint proxies are deployed only where needed — scoped to a namespace or a specific application service — rather than duplicated for every pod. |

## Ingress: Kubernetes Gateway API vs Istio Gateway API

Istio recommends using the **Kubernetes Gateway API** (`gateway.networking.k8s.io/v1`) together with `HTTPRoute` for ingress traffic, as it is the upstream-endorsed approach and aligns with the broader Kubernetes ecosystem direction. That said, the classic **Istio Gateway** (`networking.istio.io/v1`) combined with `VirtualService` is fully supported and works without issues — there is no functional difference in capabilities for most use cases.

The sample application under `examples/charts/sample-app/httpbin/templates/` ships with both approaches side by side, controlled by a `useGatewayApi` Helm value:

| Approach | Resources | Files |
|---|---|---|
| Istio Gateway API (classic) | `Gateway` + `VirtualService` | [`gateway.yaml`](../examples/charts/sample-app/httpbin/templates/gateway.yaml), [`virtualservice.yaml`](../examples/charts/sample-app/httpbin/templates/virtualservice.yaml) |
| Kubernetes Gateway API (recommended) | `Gateway` + `HTTPRoute` | [`k8sgateway.yaml`](../examples/charts/sample-app/httpbin/templates/k8sgateway.yaml), [`route.yaml`](../examples/charts/sample-app/httpbin/templates/route.yaml) |

In [`k8sgateway.yaml`](../examples/charts/sample-app/httpbin/templates/k8sgateway.yaml), the `spec.addresses[].value` field must be set to the cluster-local hostname of the Istio ingress gateway service, in the format `<istio-ingress-svc-name>.<istio-ingress-namespace>.svc.cluster.local`.

## Example: Ambient Mode with Waypoint

The [`examples/ambient`](../examples/ambient) folder contains a working end-to-end example that uses Istio ambient mode. It demonstrates:

- A **waypoint deployed for egress** — using [modules/waypoint](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/waypoint) in place of a traditional egress gateway. A `ServiceEntry` routes outbound traffic for a given domain through the waypoint proxies, providing egress control and observability.
- A **second waypoint deployment for L7 filtering** — a separate [modules/waypoint](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/waypoint) instance scoped to the httpbin application namespace, enabling advanced L7 features such as canary traffic splitting and header-based routing for httpbin if needed, via `HTTPRoute` resources.

## Further Reading

- [modules/ztunnel README](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/ztunnel) — ztunnel deployment, namespace configuration, and ambient mode prerequisites.
- [modules/waypoint README](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/modules/waypoint) — waypoint proxy setup, `istio.io/use-waypoint` labelling, and L7 traffic management examples.
- [Red Hat OpenShift Service Mesh — Istio Ambient Mode](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.3/html/installing/ossm-istio-ambient-mode#ossm-about-istio-ambient-mode_ossm-istio-ambient-mode) — official upstream documentation covering architecture, migration, and best practices.
