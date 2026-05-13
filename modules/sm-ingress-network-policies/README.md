# ServiceMesh Ingress Network policies

This module allows to create a set of [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) for a specific RedHat Openshift Service Mesh v3 ingress dataplane to implement a 'Secure by default' pattern: essentially it creates two network policies for ingress type traffic to
- allow only the Pods members of the same controlplane to reach the ingress pods. The name of the policy is in the format `[prefix-][control plane name]-np-cp`. The rule is implemented through the namespaceSelector condition on the label used to enroll the other namespaces in its same controlplane `"istio-injection" : "enabled"` or `"istio.io/rev" : "[control plane name]"`
- allow only the ingress dataplane pods to be reached. The name of the policy is in the format `[prefix-][control plane name]-np-ts`. The rule is implemented through the ingress traffic selectors used in the ingress definition.

The network policies are also labeled with the same controlplane label key and value.

In addiction to these the submodule allows to add custom ingress network policies that integrate with the default ones to customise the controlplane namespace network control.

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
| [helm_release.istio_custom_ingress_network_policies](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_default_ingress_network_policy_controlplane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_default_ingress_network_policy_traffic_selectors](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_default_istio_ingress_network_policies"></a> [add\_default\_istio\_ingress\_network\_policies](#input\_add\_default\_istio\_ingress\_network\_policies) | Flag to create the default ingress network policies to to limit the ingress traffic to the namespaces enrolled in the same controlplane and to limit the traffic on the ingress pods only. | `bool` | `true` | no |
| <a name="input_additional_custom_ingress_network_policies"></a> [additional\_custom\_ingress\_network\_policies](#input\_additional\_custom\_ingress\_network\_policies) | Custom ingress network policies to create along with the default one, if enabled, in the input namespace. Default to empty | <pre>list(object(<br/>    {<br/>      policyName : string,<br/>      isEgressPolicy : optional(bool, false),<br/>      isIngressPolicy : optional(bool, false),<br/>      ingressSelectors : optional(any, null),<br/>      egressSelectors : optional(any, null),<br/>      podSelector : optional(any, null),<br/>    }<br/>  ))</pre> | `[]` | no |
| <a name="input_force_ingress_network_policies_update"></a> [force\_ingress\_network\_policies\_update](#input\_force\_ingress\_network\_policies\_update) | Force ingress network policies to be recreated when updated. Default to false (may require to taint the resource to apply changes) | `bool` | `false` | no |
| <a name="input_ingress_network_policy_deployment_timeout"></a> [ingress\_network\_policy\_deployment\_timeout](#input\_ingress\_network\_policy\_deployment\_timeout) | Deployment timeout in seconds for the ingress network policy resources. Default to 120 seconds. | `number` | `120` | no |
| <a name="input_ingress_network_policy_istio_controlplane"></a> [ingress\_network\_policy\_istio\_controlplane](#input\_ingress\_network\_policy\_istio\_controlplane) | The controlplane name to use for the default ingress network policy to limit the ingress traffic to the namespaces enrolled in the same controlplane and to limit the traffic on the ingress pods only. Cannot be null. | `string` | n/a | yes |
| <a name="input_ingress_network_policy_istio_traffic_selectors"></a> [ingress\_network\_policy\_istio\_traffic\_selectors](#input\_ingress\_network\_policy\_istio\_traffic\_selectors) | Service Mesh ingress traffic selectors used to select the namespaces allowed to reach the ingress pods according to the enrollment controlplane. | `map(string)` | <pre>{<br/>  "app": "istio-ingress",<br/>  "istio": "istio-ingress"<br/>}</pre> | no |
| <a name="input_ingress_network_policy_names_prefix"></a> [ingress\_network\_policy\_names\_prefix](#input\_ingress\_network\_policy\_names\_prefix) | The prefix to use for the ingress network policies names. If set the network policies are named with this prefix. Default to null. | `string` | `null` | no |
| <a name="input_ingress_network_policy_namespace"></a> [ingress\_network\_policy\_namespace](#input\_ingress\_network\_policy\_namespace) | Namespace to use to deploy the ingress network policies. Cannot be null. | `string` | n/a | yes |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
