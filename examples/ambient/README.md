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

## Key Features

- Deploys Istio with ambient mode enabled (sidecarless approach)
- Configures IstioCNI with ambient profile
- Deploys ZTunnel for ambient mode data plane
- Sets up ingress and egress gateways
- Deploys a sample httpbin application with ambient mode labels

## Ambient Mode Configuration

The example enables ambient mode by:
- Setting `is_ambient_mode = true` in the `deploy_istio` module
- Setting `is_ambient_mode = true` in the `deploy_istio_cni` module
- Deploying the `ztunnel` module for the ambient data plane
- Using `istio.io/dataplane-mode: ambient` label on application namespaces instead of sidecar injection

## Usage

See the root module README for general usage instructions. This example follows the same pattern as the basic example but with ambient mode enabled.
