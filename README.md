<!-- Update this title with a descriptive name. Use sentence case. -->
# Terraform modules template project

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

<!--
Add a description of modules in this repo.
Expand on the repo short description in the .github/settings.yml file.

For information, see "Module names and descriptions" at
https://terraform-ibm-modules.github.io/documentation/#/implementation-guidelines?id=module-names-and-descriptions
-->

TODO: Replace this with a description of the modules in this repo.


<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-ocp-service-mesh](#terraform-ibm-ocp-service-mesh)
* [Examples](./examples)
* [Contributing](#contributing)
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

<!--
Add an example of the use of the module in the following code block.

Use real values instead of "var.<var_name>" or other placeholder values
unless real values don't help users know what to change.
-->

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

module "module_template" {
  source            = "terraform-ibm-modules/<replace>/ibm"
  version           = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  region            = local.region
  name              = "instance-name"
  resource_group_id = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX" # Replace with the actual ID of resource group to use
}
```

### Required access policies

<!-- PERMISSIONS REQUIRED TO RUN MODULE
If this module requires permissions, uncomment the following block and update
the sample permissions, following the format.
Replace the 'Sample IBM Cloud' service and roles with applicable values.
The required information can usually be found in the services official
IBM Cloud documentation.
To view all available service permissions, you can go in the
console at Manage > Access (IAM) > Access groups and click into an existing group
(or create a new one) and in the 'Access' tab click 'Assign access'.
-->

<!--
You need the following permissions to run this module:

- Service
    - **Resource group only**
        - `Viewer` access on the specific resource group
    - **Sample IBM Cloud** service
        - `Editor` platform access
        - `Manager` service access
-->

<!-- NO PERMISSIONS FOR MODULE
If no permissions are required for the module, uncomment the following
statement instead the previous block.
-->

<!-- No permissions are needed to run this module.-->


<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.8.0, < 3.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, < 2.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.service_mesh_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.undeploy_servicemesh](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait_operators](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Id of the target IBM Cloud OpenShift Cluster | `string` | n/a | yes |
| <a name="input_deploy_operator"></a> [deploy\_operator](#input\_deploy\_operator) | Enable installing RedHat Service Mesh Operator | `bool` | `true` | no |
| <a name="input_develop_mode"></a> [develop\_mode](#input\_develop\_mode) | If true, output more logs, and reduce some wait periods | `bool` | `false` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set-up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
