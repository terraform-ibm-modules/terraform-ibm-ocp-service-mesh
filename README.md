<!-- Update this title with a descriptive name. Use sentence case. -->
# Red Hat OpenShift Container Platform Service Mesh module

<!--
Update status and "latest release" badges:
  1. For the status options, see https://terraform-ibm-modules.github.io/documentation/#/badge-status
  2. Update the "latest release" badge to point to the correct module's repo. Replace "terraform-ibm-module-template" in two places.
-->
[![Incubating (Not yet consumable)](https://img.shields.io/badge/status-Incubating%20(Not%20yet%20consumable)-red)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-ocp-service-mesh?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module deploys the [Red Hat OpenShift Service Mesh v3](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0) by configuring Istio and IstioCNI resources through Istio [Sail operator](###), allows to configure the Istio Pilot deployment, to configure two or more Istio controlplanes in the same cluster by setting up Service Mesh discovery selectors and sidecar injection, to deploy and configure Istio ingress and egress gateways for Istio dataplanes.
You can also control placement of the gateways on the desired cluster's worker nodes to support, for example, a double DMZ architecture.

For more details about the Red Hat OpenShift Service Mesh, see [Red Hat OpenShift Service Mesh 3.0](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0) and [Installing Red Hat OpenShift Service Mesh](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-installing-service-mesh)

### Service Mesh discovery selectors

The submodule [modules/sm-istio](./modules/sm-istio) supports configuring Service Mesh discovery selectors, to configure each Istio controlplane workloads discovery attributes.

For more details about Service Mesh discovery selectors, see [Scoping the Service Mesh with discovery selectors](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-installing-service-mesh#ossm-scoping-service-mesh-with-discoveryselectors_ossm-installing-openshift-service-mesh)

### Service Mesh sidecar injection

The submodule [modules/sm-istio](./modules/sm-istio) supports configuring Service Mesh sidecar injection, to configure each Istio controlplane to inject with sidecar proxies the workloads according to specific attributes

This module supports sidecar inject at namespace level in this moment, following the rules below:

| IstioRevision name | Enabled label & value	| Disabled value |
| --- | --- | --- |
| default | istio-injection=enabled | istio-injection=disabled |
| not default - i.e. `my-mesh-1` | istio.io/rev=my-mesh-1 | istio-injection=disabled |

For more details about Service Mesh sidecar injection, see [Sidecar injection](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-sidecar-injection)

For more details about excluding single workload from the Service Mesh, see [Exclude a workload from the mesh](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-enabling-sidecar-injection-exclude-workload-from-mesh_ossm-sidecar-injection)

### Multiple Service Mesh controlplanes deployment on the same cluster

By appropriately configuring the controlplanes discovery selectors and sidecar injection properties with multiple instances of [modules/sm-istio](./modules/sm-istio) this module allows to deploy multiple controlplanes on the sidecar, each one discovering the appropriate workloads and injecting the related sidecars.

https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-deploying-multiple-service-meshes-on-single-cluster#ossm-about-deploying-multiple-control-planes_ossm-deploying-multiple-service-meshes-on-single-cluster

#### Gateway injection

The submodule [modules/sm-istio-ingress](./modules/sm-istio-ingress) and [modules/sm-istio-egress](./modules/sm-istio-egress), through allows to deploy ingress and egress istio gateways into the cluster through the Gateway injection. Gateway injection relies upon the same mechanism as sidecar injection to inject the Envoy proxy into gateway pods. To install a gateway using gateway injection, you create a Kubernetes Deployment object and an associated Kubernetes Service object in a namespace that is visible to the Istio control plane. When creating the Deployment object you label and annotate it so that the Istio control plane injects a proxy, and the proxy is configured as a gateway. After installing the gateway, you configure it to control ingress and egress traffic using the Istio Gateway and VirtualService resources.

For more details about Gateway injection, see [Gateways](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/gateways/index) and [About gateway injection](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/gateways/ossm-about-gateways#ossm-about-gateway-injection_ossm-about-gateways)

<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
<ul>
  <li><a href="#terraform-ibm-ocp-service-mesh">terraform-ibm-ocp-service-mesh</a></li>
  <li><a href="./modules">Submodules</a>
    <ul>
      <li><a href="./modules/sm-ingress-network-policies">sm-ingress-network-policies</a></li>
      <li><a href="./modules/sm-istio">sm-istio</a></li>
      <li><a href="./modules/sm-istio-egress">sm-istio-egress</a></li>
      <li><a href="./modules/sm-istio-ingress">sm-istio-ingress</a></li>
      <li><a href="./modules/sm-network-policies">sm-network-policies</a></li>
    </ul>
  </li>
  <li><a href="./examples">Examples</a>
    <ul>
      <li>
        <a href="./examples/advanced">Advanced OCP cluster single zone and single subnet with RedHat ServiceMesh v3, customised ingress and egress configurations and network policies</a>
        <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=ocp-service-mesh-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/examples/advanced"><img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom; margin-left: 5px;"></a>
      </li>
      <li>
        <a href="./examples/basic">Basic OCP cluster single zone and single subnet with RedHat ServiceMesh v3</a>
        <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=ocp-service-mesh-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/examples/basic"><img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom; margin-left: 5px;"></a>
      </li>
      <li>
        <a href="./examples/existing_cluster">Basic OCP cluster single zone and single subnet with RedHat ServiceMesh v3</a>
        <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=ocp-service-mesh-existing_cluster-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/examples/existing_cluster"><img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom; margin-left: 5px;"></a>
      </li>
    </ul>
    ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
  </li>
  <li><a href="#contributing">Contributing</a></li>
</ul>
<!-- END OVERVIEW HOOK -->

<!--
If this repo contains any reference architectures, uncomment the heading below and link to them.
(Usually in the `/reference-architectures` directory.)
See "Reference architecture" in the public documentation at
https://terraform-ibm-modules.github.io/documentation/#/implementation-guidelines?id=reference-architecture
-->
<!-- ## Reference architectures -->


<!-- Replace this heading with the name of the root level module (the repo name) -->
## terraform-ibm-ocp-service-mesh

### Usage

```hcl
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "X.Y.Z"  # Lock into a provider version that satisfies the module constraints
    }
  }
}

locals {
    region = "us-south"
}

provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXX"  # replace with apikey value
  region           = local.region
}

provider "helm" {
  kubernetes = {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
}

provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_config.host
  token                  = data.ibm_container_cluster_config.cluster_config.token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.resource_group_id
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

# deploy servicemesh operator
module "service_mesh_operator" {
  source                       = "terraform-ibm-modules/ocp-service-mesh/ibm"
  version                      = "X.Y.Z"
  cluster_id                   = var.cluster_id
  develop_mode                 = var.develop_mode
  resource_group_id            = var.resource_group_id
}

module "deploy_istio" {
  depends_on        = [module.service_mesh_operator]
  source            = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio"
  version           = "X.Y.Z"
  name              = "default"
  namespace         = "istio-system"
  create_namespace  = true
  cluster_id        = var.cluster_id
  resource_group_id = var.resource_group_id
}

module "deploy_istio_cni" {
  depends_on       = [module.service_mesh_operator]
  source           = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio-cni"
  version          = "X.Y.Z"
  namespace        = "istio-system-cni"
  create_namespace = true
}

# wait for istio components to complete deployment and start
resource "time_sleep" "wait_istio" {
  depends_on = [module.deploy_istio, module.deploy_istio_cni]

  create_duration  = "300s"
  destroy_duration = "60s"
}

# deploy standard ingress gateway
module "basic_workload_ingress" {
  depends_on                = [time_sleep.wait_istio]
  source                   = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio-ingress"
  version                  = "X.Y.Z"
  name                      = "basic-ingress"
  namespace                 = "basic-ingress"
  create_namespace          = true
  force_dataplane_update    = true
  ingress_loadbalancer_type = "alb"
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "public"
  istio_mesh_enrollment     = "default"
  ingress_selectors = {
    "istio" : "ingress-gateway",
  }
  ingress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "protocol" : "TCP"
    }
  ]
  cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}

# deploy standard egress gateway
module "default_workload_egress" {
  depends_on             = [time_sleep.wait_istio]
  source                 = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio-egress"
  version                = "X.Y.Z"
  name                   = "basic-egress"
  namespace              = "basic-egress"
  create_namespace       = false
  force_dataplane_update = true
  istio_mesh_enrollment  = "default"
  egress_selectors = {
    "istio" : "egress-gateway",
  }
  egress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "protocol" : "TCP"
    },
    {
      "name" : "https"
      "port" : "443"
      "targetPort" : "443"
      "protocol" : "TCP"
    }
  ]
  cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}

```

### Required access policies

You need the following permissions to run this module.

- IAM Services
  - **Kubernetes** service
      - `Viewer` platform access
      - `Manager` service access

For more information about the access you need to run Terraform IBM modules, see [IBM Cloud IAM roles](https://cloud.ibm.com/docs/account?topic=account-userroles).


<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0, <4.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, < 3.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.service_mesh_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [terraform_data.undeploy_servicemesh](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.wait_operators](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_clean_servicemesh_on_undeploy"></a> [clean\_servicemesh\_on\_undeploy](#input\_clean\_servicemesh\_on\_undeploy) | Flag to perform a cleanup of ServiceMesh operator custom resources when undeploying the module. Default to true. For more details refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.1/html-single/uninstalling/index . | `bool` | `true` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Id of the target IBM Cloud OpenShift Cluster | `string` | n/a | yes |
| <a name="input_develop_mode"></a> [develop\_mode](#input\_develop\_mode) | If set to true, increases the wait time for operator deployment and undeployment to facilitate cluster debugging, and prevents the `helm_release` resource from automatically rolling back changes if the helm deployment fails. | `bool` | `false` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group for the OpenShift Cluster. | `string` | n/a | yes |
| <a name="input_sm_operator_custom_catalog_description"></a> [sm\_operator\_custom\_catalog\_description](#input\_sm\_operator\_custom\_catalog\_description) | Description of the custom Catalog Source for the Service Mesh Operator | `string` | `null` | no |
| <a name="input_sm_operator_custom_catalog_image_digest"></a> [sm\_operator\_custom\_catalog\_image\_digest](#input\_sm\_operator\_custom\_catalog\_image\_digest) | Digest of the catalog index image for the custom Catalog Source for the Service Mesh Operator | `string` | `null` | no |
| <a name="input_sm_operator_custom_catalog_index_name"></a> [sm\_operator\_custom\_catalog\_index\_name](#input\_sm\_operator\_custom\_catalog\_index\_name) | Name of the catalog index for the custom Catalog Source for the Service Mesh Operator | `string` | `null` | no |
| <a name="input_sm_operator_custom_catalog_name"></a> [sm\_operator\_custom\_catalog\_name](#input\_sm\_operator\_custom\_catalog\_name) | Name of the custom Catalog Source for the Service Mesh Operator | `string` | `null` | no |
| <a name="input_sm_operator_custom_catalog_namespace"></a> [sm\_operator\_custom\_catalog\_namespace](#input\_sm\_operator\_custom\_catalog\_namespace) | Namespace of the custom Catalog Source for the Service Mesh Operator | `string` | `"openshift-marketplace"` | no |
| <a name="input_sm_operator_custom_catalog_publisher"></a> [sm\_operator\_custom\_catalog\_publisher](#input\_sm\_operator\_custom\_catalog\_publisher) | Publisher of the custom Catalog Source for the Service Mesh Operator | `string` | `null` | no |
| <a name="input_sm_operator_custom_catalog_registry_pullsecret_name"></a> [sm\_operator\_custom\_catalog\_registry\_pullsecret\_name](#input\_sm\_operator\_custom\_catalog\_registry\_pullsecret\_name) | Name of the cluster secret to store the pull secret to access the registry for the mirrored Service Mesh Operator images | `string` | `null` | no |
| <a name="input_sm_operator_custom_catalog_registry_pullsecret_value"></a> [sm\_operator\_custom\_catalog\_registry\_pullsecret\_value](#input\_sm\_operator\_custom\_catalog\_registry\_pullsecret\_value) | Value of the pull secret to access the registry for the mirrored Service Mesh Operator images | `string` | `null` | no |
| <a name="input_sm_operator_custom_catalog_registry_url"></a> [sm\_operator\_custom\_catalog\_registry\_url](#input\_sm\_operator\_custom\_catalog\_registry\_url) | Registry URL for the mirrored Service Mesh Operator images | `string` | `"icr.io"` | no |
| <a name="input_sm_operator_installplan_approval"></a> [sm\_operator\_installplan\_approval](#input\_sm\_operator\_installplan\_approval) | OpenShift OLM install plan approval strategy. Valid values are 'Automatic', to automatically perform installation and upgrades, or 'Manual' to required manual approval | `string` | `"Automatic"` | no |
| <a name="input_sm_operator_version"></a> [sm\_operator\_version](#input\_sm\_operator\_version) | OpenShift ServiceMesh Operator v3 version to install. Default to null to use the latest version available in the catalog. | `string` | `null` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set-up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
