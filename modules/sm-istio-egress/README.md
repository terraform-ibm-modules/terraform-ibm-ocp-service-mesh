# Service Mesh Istio module for egress gateway

## Overview
This module deploys the Istio egress gateway resources configured to leverage on Istio gateway injection, to set up the gateway's namespace labels according to user input for the expected controlplane's discovery selectors and to setup the expected istio selectors for the traffic routing configuration.

### Discovery selectors and sidecar injection configuration

This module allows to setup the gateway's namespace discovery selectors according to the desired controlplane attributes following the Red Hat Service Mesh [requirements](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-installing-service-mesh#ossm-scoping-service-mesh-with-discoveryselectors_ossm-installing-openshift-service-mesh)

- if the input parameter `var.egress_discovery_custom_configuration` is left to its default value `null` the gateway's namespace discovery selector is configured with the following logic:
  - if the Istio mesh name to enroll the gateway's namespace to (`var.istio_mesh_enrollment`) is left to its default value `default` the discovery selector and sidecar injection labels are configured with
  ```
    {
      "istio-discovery" : "enabled",
      "istio-injection" : "enabled",
    }
  ```
  - if the Istio mesh name to enroll the gateway's namespace to (`var.istio_mesh_enrollment`) is not left to its default value `default` the discovery selector and sidecar injection labels are configured with
  ```
    {
      "istio-discovery" : var.istio_mesh_enrollment,
      "istio.io/rev" : var.istio_mesh_enrollment,
    }
  ```
- if the input parameter `var.egress_discovery_custom_configuration` is customised its values are configured into the gateways' labels

### Example: basic egress gateway configuration

This configuration deploys a Istio egress gateway with the default configurations for controlplane named `default` and discovery selectors
```
    {
      "istio-discovery" : "enabled",
      "istio-injection" : "enabled",
    }
```
The gateway is created in the `basic-egress` namespace which is created at gateway deployment time, and opens the ports TCP/80 (mapped internally to port 8000) and TCP/443 (mapped internally to port 443). Traffic routing selector is `"istio" : "egress-gateway"`

```
module "default_workload_egress" {
  source                 = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio-egress"
  version                = "X.Y.Z"
  name                   = "basic-egress"
  namespace              = "basic-egress"
  create_namespace       = true
  istio_mesh_enrollment  = "default"
  egress_selectors = {
    "istio" : "egress-gateway",
  }
  egress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "proto" : "TCP"
    },
    {
      "name" : "https"
      "port" : "443"
      "targetPort" : "443"
      "proto" : "TCP"
    }
  ]
  cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}
```

### Example: Advanced egress gateway configuration

This configuration deploys a Istio egress gateway to enroll in the controlplane named `mesh-1` with namespace labels set to

```
    {
      "istio-discovery" : "mesh-1",
      "istio.io/rev" : "mesh-1",
    }
```

The gateway is created in the `default-workload` namespace which is NOT created at gateway deployment time, which is recreated if an update is identified by terraform, traffic routing selector is `"istio" : "default-workload-egress"`, opens the ports TCP/80 (mapped internally to port 8000), TCP/443 (mapped internally to port 443), TCP/5432 (mapped internally to port 5432), disable egress deployment autoscaling, sets the replicas to 3 pods, sets the resources configuration requests and limits for CPU and memory, the egress pods termination grace period, and the pods affinity and toleration to make the pods to run on the worker nodes with label `dedicated=edge` and the pods antiaffinity rule to have the 3 replicas to run on different nodes according to the pods label `"istio.io/gateway" = "def-workload-egress.default-workload"` (set by the module at deployment definition time with the format `namespace.gatewayname`)

```

locals {
  affinity = {
    nodeAffinity : {
      requiredDuringSchedulingIgnoredDuringExecution : {
        nodeSelectorTerms : [
          {
            matchExpressions : [
              {
                key : "ibm-cloud.kubernetes.io/worker-pool-name",
                operator : "In",
                values : ["edge"]
              }
            ]
          }
        ]
      }
    },
    podAntiAffinity : {
      preferredDuringSchedulingIgnoredDuringExecution : [
        {
          podAffinityTerm : {
            labelSelector : {
              matchExpressions : [
                {
                  key : "istio.io/gateway",
                  operator : "In",
                  values : ["def-workload-egress.default-workload"]
                }
              ]
            }
            topologyKey : "topology.kubernetes.io/zone"
          }
          weight : 100
        }
      ]
    }
  }
}

module "default_workload_egress" {
  source                 = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio-egress"
  version                = "X.Y.Z"
  name                   = "def-workload-egress"
  namespace              = "default-workload"
  create_namespace       = false
  force_dataplane_update = true
  istio_mesh_enrollment  = "mesh-1"
  egress_selectors = {
    "istio" : "default-workload-egress",
  }

  egress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "proto" : "TCP"
    },
    {
      "name" : "https"
      "port" : "443"
      "targetPort" : "443"
      "proto" : "TCP"
    },
    {
      "name" : "tcp"
      "port" : "5432"
      "targetPort" : "5432"
      "proto" : "TCP"
    }
  ]
  egress_autoscale_configuration = {
    "enabled" : false
  }
  egress_replicas          = 3
  egress_resources_configuration = {
    "limits" : {
      "cpu" : "200m"
      "memory" : "1024Mi"
    },
    "requests" : {
      "cpu" : "100m"
      "memory" : "128Mi"
    }
  }
  egress_termination_grace_period = 30
  egress_affinity                 = local.affinity
  egress_tolerations = [
    {
      key : "dedicated"
      value : "edge"
      effect : "NoExecute"
    }
  ]
  cluster_config_file_path = data.ibm_container_cluster_config.cluster_config.config_file_path
}
```

For all the configuration parameters details refer to the section below

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0, <4.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, < 2.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 3.0.1, < 4.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_egress_namespace"></a> [egress\_namespace](#module\_egress\_namespace) | terraform-ibm-modules/namespace/ibm | v2.0.1 |

### Resources

| Name | Type |
|------|------|
| [helm_release.istio_egress](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.confirm_egress_operational](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Id of the target IBM Cloud OpenShift Cluster | `string` | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Flag to create the namespace where to install istio egress dataplane. Default to true | `bool` | `true` | no |
| <a name="input_egress_affinity"></a> [egress\_affinity](#input\_egress\_affinity) | Istio egress affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Egress pods are provided of a label with key "istio.io/gateway" and value "[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]" in order to allow to set them as antiAffinity labels. Default to empty configuration. | <pre>object({<br/>    podAntiAffinity : optional(any, null),<br/>    podAffinity : optional(any, null),<br/>    nodeAffinity : optional(any, null)<br/>  })</pre> | `{}` | no |
| <a name="input_egress_autoscale_configuration"></a> [egress\_autoscale\_configuration](#input\_egress\_autoscale\_configuration) | egress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false. | <pre>object({<br/>    enabled : optional(bool, false),<br/>    autoscaleMin : optional(number, 1),<br/>    autoscaleMax : optional(number, 5),<br/>    cpu : optional(object(<br/>      {<br/>        targetavgutil : optional(number, 80)<br/>      }<br/>    ))<br/>    memory : optional(object(<br/>      {<br/>        targetavgutil : optional(number, 80)<br/>      }<br/>    ))<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_egress_discovery_custom_configuration"></a> [egress\_discovery\_custom\_configuration](#input\_egress\_discovery\_custom\_configuration) | Map of key-value entries to set custom istio discovery labels. Default to null to autogenerate the labels according to var.istio\_mesh\_enrollment value. For more details about istio discovery configuration refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-about-sidecar-injection_ossm-sidecar-injection and https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-deploying-multiple-service-meshes-on-single-cluster. | `map(string)` | `null` | no |
| <a name="input_egress_internal_traffic_policy"></a> [egress\_internal\_traffic\_policy](#input\_egress\_internal\_traffic\_policy) | Internal traffic policy configuration for the egress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-egress/. | `string` | `"Cluster"` | no |
| <a name="input_egress_pdb_configuration"></a> [egress\_pdb\_configuration](#input\_egress\_pdb\_configuration) | Configuration of the PodDisruptionBudget for the istio egress definition. Default to null to leverage on Istio default configuration. | <pre>object({<br/>    minAvailable   = optional(string, null)<br/>    maxUnavailable = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_egress_ports"></a> [egress\_ports](#input\_egress\_ports) | List of ports to configured on egress for outbound traffic. Default to port 443:443 on TCP. | <pre>list(object(<br/>    {<br/>      port : number,<br/>      name : string<br/>      proto : string,<br/>      targetPort : number<br/>    }<br/>  ))</pre> | <pre>[<br/>  {<br/>    "name": "https",<br/>    "port": 443,<br/>    "proto": "TCP",<br/>    "targetPort": 443<br/>  }<br/>]</pre> | no |
| <a name="input_egress_replicas"></a> [egress\_replicas](#input\_egress\_replicas) | Istio egress deployment replicaset configuration. If the var.egress\_autoscale\_configuration.enabled is true this value is ignored. Default to 3. | `number` | `3` | no |
| <a name="input_egress_resources_configuration"></a> [egress\_resources\_configuration](#input\_egress\_resources\_configuration) | Istio egress resources deployment configuration. Default configuration is null and leverages on Istio default setting. | <pre>object(<br/>    {<br/>      limits : optional(object(<br/>        {<br/>          cpu : optional(string, null),<br/>          memory : optional(string, null)<br/>      }), null),<br/>      requests : optional(object(<br/>        {<br/>          cpu : optional(string, null)<br/>          memory : optional(string, null)<br/>      }), null)<br/>    }<br/>  )</pre> | `null` | no |
| <a name="input_egress_selectors"></a> [egress\_selectors](#input\_egress\_selectors) | Istio egress selectors to route outbound egress traffic to the expected istio gateway and to the expected workload. Default to "app": "istio-egress" "istio": "istio-egress" "gateway-instance": "istio-egressgateway". Null not allowed | `map(string)` | <pre>{<br/>  "app": "istio-egress",<br/>  "istio": "istio-egress"<br/>}</pre> | no |
| <a name="input_egress_termination_grace_period"></a> [egress\_termination\_grace\_period](#input\_egress\_termination\_grace\_period) | Number of seconds for the Istio egress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default. | `number` | `null` | no |
| <a name="input_egress_tolerations"></a> [egress\_tolerations](#input\_egress\_tolerations) | Istio egress tolerations configuration. Default to tolerate 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core | `list(any)` | `[]` | no |
| <a name="input_force_dataplane_update"></a> [force\_dataplane\_update](#input\_force\_dataplane\_update) | Force dataplane to be updated | `bool` | `false` | no |
| <a name="input_istio_egress_deployment_timeout"></a> [istio\_egress\_deployment\_timeout](#input\_istio\_egress\_deployment\_timeout) | Timeout for the helm release deployment for the egress gateway | `string` | `null` | no |
| <a name="input_istio_mesh_enrollment"></a> [istio\_mesh\_enrollment](#input\_istio\_mesh\_enrollment) | Name of the Istio mesh controlplane to enroll this dataplane with. Default value to default. This value is used to generate discovery selectors, to override the computed values customise var.egress\_discovery\_custom\_configuration. | `string` | `"default"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Istio egress deployment | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where to install istio egress dataplane. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group for the OpenShift Cluster. | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_istio_egress_metadata"></a> [istio\_egress\_metadata](#output\_istio\_egress\_metadata) | istio\_egress definition metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
