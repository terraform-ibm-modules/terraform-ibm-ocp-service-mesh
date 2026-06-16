# Ambient Mode Example

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