# ServiceMesh Network policies

This module allows to create a set of [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) for a specific RedHat Openshift Service Mesh v3 controlplane to implement a 'Secure by default' pattern: essentially it creates two network policies for ingress type traffic to allow only the Pods members of the same controlplane to reach the controlplane pods and to allow the istiod pods to be reached by all the sources
The first rule named `[prefix-][control plane name]-np-is` is performed through the namespaceSelector condition on the label used to enroll the other namespaces in this controlplane `"istio-injection" : "enabled"` or `"istio.io/rev" : "[control plane name]"`
The second rule `[prefix-][control plane name]-np-istiod` allows all the ingress traffic on the istiod pods.
Both the network policies are also labeled with the same label key and value.

In addiction to this the submodule allows to add custom network policies that integrate with the default one to customise the controlplane namespace network control.

<!-- The following content is automatically populated by the pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->

<!-- END OVERVIEW HOOK -->

<!-- The following content is automatically populated by the pre-commit hook -->
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
| [helm_release.istio_custom_network_policies](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_default_network_policy](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_default_network_policy_istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_default_istio_network_policy"></a> [add\_default\_istio\_network\_policy](#input\_add\_default\_istio\_network\_policy) | Flag to create the default network policy to limit the ingress traffic to the namespaces enrolled in the same controlplane | `bool` | `true` | no |
| <a name="input_additional_custom_network_policies"></a> [additional\_custom\_network\_policies](#input\_additional\_custom\_network\_policies) | Custom network policies to create along with the default one, if enabled, in the input namespace. Default to empty | <pre>list(object(<br/>    {<br/>      policyName : string,<br/>      isEgressPolicy : optional(bool, false),<br/>      isIngressPolicy : optional(bool, false),<br/>      ingressSelectors : optional(any, null),<br/>      egressSelectors : optional(any, null),<br/>      podSelector : optional(any, null),<br/>    }<br/>  ))</pre> | `[]` | no |
| <a name="input_force_network_policies_update"></a> [force\_network\_policies\_update](#input\_force\_network\_policies\_update) | Force network policies to be recreated when updated. Default to false (may require to taint the resource to apply changes) | `bool` | `false` | no |
| <a name="input_network_policy_deployment_timeout"></a> [network\_policy\_deployment\_timeout](#input\_network\_policy\_deployment\_timeout) | Deployment timeout in seconds for the network policy resources. Default to 120 seconds. | `number` | `120` | no |
| <a name="input_network_policy_istio_controlplane"></a> [network\_policy\_istio\_controlplane](#input\_network\_policy\_istio\_controlplane) | The controlplane name to use for the default network policy to limit the ingress traffic to the namespaces enrolled in the same controlplane. Cannot be null. | `string` | n/a | yes |
| <a name="input_network_policy_names_prefix"></a> [network\_policy\_names\_prefix](#input\_network\_policy\_names\_prefix) | The prefix to use for the network policies names. If set the network policies are named with this prefix. Default to null. | `string` | `null` | no |
| <a name="input_network_policy_namespace"></a> [network\_policy\_namespace](#input\_network\_policy\_namespace) | Namespace to use to deploy the network policies. Cannot be null. | `string` | n/a | yes |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
