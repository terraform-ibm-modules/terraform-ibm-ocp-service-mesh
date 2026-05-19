# Service Mesh Istio module for egress gateway

## Overview
This module deploys the Istio ingress gateway resources configured to leverage on Istio gateway injection, to set up the gateway's namespace labels according to user input for the expected controlplane's discovery selectors and to setup the expected istio selectors for the traffic routing configuration.

### Discovery selectors and sidecar injection configuration

This module allows to setup the gateway's namespace discovery selectors according to the desired controlplane attributes following the Red Hat Service Mesh [requirements](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-installing-service-mesh#ossm-scoping-service-mesh-with-discoveryselectors_ossm-installing-openshift-service-mesh)

- if the input parameter `var.ingress_discovery_custom_configuration` is left to its default value `null` the gateway's namespace discovery selector is configured with the following logic:
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
- if the input parameter `var.ingress_discovery_custom_configuration` is customised its values are configured into the gateways' labels

### Example: basic ingress gateway configuration

This configuration deploys a Istio ingress gateway with the default configurations for controlplane named `default` and discovery selectors
```
    {
      "istio-discovery" : "enabled",
      "istio-injection" : "enabled",
    }
```
The gateway is created in the `basic-ingress` namespace which is created at gateway deployment time, and opens the port TCP/80 (mapped internally to port 8000). Traffic routing selector is `"istio" : "ingress-gateway"`. Ingress Loadbalancer type is Application Load Balancer, its IP type is public.

```

module "default_workload_ingress" {
  source                 = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio-ingress"
  name                      = "basic-ingress"
  namespace                 = "basic-ingress"
  create_namespace          = true
  force_dataplane_update    = false
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
```

### Example: Advanced egress gateway configuration

This configuration deploys a Istio egress gateway to enroll in the controlplane named `mesh-1` with namespace labels set to

```
    {
      "istio-discovery" : "mesh-1",
      "istio.io/rev" : "mesh-1",
    }
```

The gateway is created in the `default-workload` namespace which is created at gateway deployment time, which is recreated if an update is identified by terraform, the ingress is attached to a LoadBalaner of type Application LoadBalancer, the traffic routing selector is `"istio" : "default-workload-ingress"`, opens the ports TCP/80 (mapped internally to port 8000), TCP/15021 (mapped internally to port 15021), disable egress deployment autoscaling, sets the replicas to 3 pods, sets the default pods disruption budget to minAvailable = 1, sets the resources configuration requests and limits for CPU and memory, the ingress pods termination grace period, enables the proxy protocol on ingress and LoadBalancer, enables the ingress and LoadBalancer to support requests with and without the proxy protocol, and the pods affinity and toleration to make the pods to run on the worker nodes with label `dedicated=edge` and the pods antiaffinity rule to have the 3 replicas to run on different nodes according to the pods label `"istio.io/gateway" = "def-workload-ingress.default-workload"` (set by the module at deployment definition time with the format `namespace.gatewayname`)

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
                  values : ["def-workload-ingress.default-workload"]
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

module "default_workload_ingress" {
  source                 = "terraform-ibm-modules/ocp-service-mesh/ibm//modules/sm-istio-ingress"
  version                = "X.Y.Z"
  name                      = "def-workload-ingress"
  namespace                 = "default-workload"
  create_namespace          = true
  force_dataplane_update    = true
  ingress_loadbalancer_type = "alb"
  ingress_service_type      = "LoadBalancer"
  ingress_ip_type           = "public"
  istio_mesh_enrollment     = "default"
  ingress_selectors = {
    "istio" : "default-workload-ingress",
  }
  ingress_alb_subnets = [for subnet in module.vpc.subnets["edge"] : subnet["id"]]
  ingress_ports = [
    {
      "name" : "http2"
      "port" : "80"
      "targetPort" : "8000"
      "protocol" : "TCP"
    },
    {
      "name" : "istio-health"
      "port" : "15021"
      "targetPort" : "15021"
      "protocol" : "TCP"
    }
  ]
  ingress_autoscale_configuration = {
    "enabled" : false
  }
  ingress_pdb_configuration = {
    "minAvailable" = "1"
  }
  ingress_replicas = 3
  ingress_resources_configuration = {
    "limits" : {
      "cpu" : "200m"
      "memory" : "1024Mi"
    },
    "requests" : {
      "cpu" : "100m"
      "memory" : "128Mi"
    }
  }
  ingress_termination_grace_period = 30
  ingress_affinity = local.affinity
  ingress_tolerations = [
    {
      key : "dedicated"
      value : "edge"
      effect : "NoExecute"
    }
  ]
  ingress_enable_proxy_protocol = true
  ingress_proxy_protocol_allow_without = true
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
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 3.0.1, < 4.0.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1, < 4.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ingress_namespace"></a> [ingress\_namespace](#module\_ingress\_namespace) | terraform-ibm-modules/namespace/ibm | v2.0.1 |

### Resources

| Name | Type |
|------|------|
| [helm_release.istio_ingress](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_annotations.istio_namespace_annotations](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [kubernetes_labels.istio_namespace_labels](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/labels) | resource |
| [null_resource.confirm_ingress_operational_alb](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.confirm_ingress_operational_nlb](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.confirm_ingress_operational_other](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [kubernetes_service_v1.ingress_services](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service_v1) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_istio_labels_annotations_to_existing_namespace"></a> [add\_istio\_labels\_annotations\_to\_existing\_namespace](#input\_add\_istio\_labels\_annotations\_to\_existing\_namespace) | Flag to add istio labels and annotations like the discovery ones or the value of var.ingress\_discovery\_custom\_configuration to an existing namespace. Default to false. If var.create\_namespace is true this flag is ignored. | `bool` | `false` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Id of the target IBM Cloud OpenShift Cluster | `string` | n/a | yes |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Flag to create the namespace where to install istio ingress dataplane. Default to true | `bool` | `true` | no |
| <a name="input_force_dataplane_update"></a> [force\_dataplane\_update](#input\_force\_dataplane\_update) | Force dataplane to be updated | `bool` | `false` | no |
| <a name="input_ingress_affinity"></a> [ingress\_affinity](#input\_ingress\_affinity) | Istio ingress affinity configuration. For more details https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#affinity-v1-core. Ingress pods are provided of a label with key "istio.io/gateway" and value "[DEPLOYMENT NAME].[DEPLOYMENT NAMESPACE]" in order to allow to set them as antiAffinity labels. Default to empty configuration. | <pre>object({<br/>    podAntiAffinity : optional(any, null),<br/>    podAffinity : optional(any, null),<br/>    nodeAffinity : optional(any, null)<br/>  })</pre> | `{}` | no |
| <a name="input_ingress_alb_idle_timeout"></a> [ingress\_alb\_idle\_timeout](#input\_ingress\_alb\_idle\_timeout) | The idle connection timeout of the IBM Cloud Application Loadbalancer listener in seconds. Default to null to adopt platform default configuration. The value cannot be less than 50s and more than 7200s. For more details refer to https://cloud.ibm.com/docs/containers?topic=containers-setup_vpc_alb. | `number` | `null` | no |
| <a name="input_ingress_alb_subnets"></a> [ingress\_alb\_subnets](#input\_ingress\_alb\_subnets) | List of VPC subnets to attach to the IBM Cloud Application LoadBalancer bound to the cluster. Null value is not allowed. Default to empty list. | `list(string)` | `[]` | no |
| <a name="input_ingress_autoscale_configuration"></a> [ingress\_autoscale\_configuration](#input\_ingress\_autoscale\_configuration) | Ingress autoscale configuration defined through HPA. If enabled is set to true the HPA definition is deployed. Otherwise if false the HPA configuration is not deployed. Default to enabled=false. | <pre>object({<br/>    enabled : optional(bool, false),<br/>    autoscaleMin : optional(number, 1),<br/>    autoscaleMax : optional(number, 5),<br/>    cpu : optional(object(<br/>      {<br/>        targetavgutil : optional(number, 80)<br/>      }<br/>    ))<br/>    memory : optional(object(<br/>      {<br/>        targetavgutil : optional(number, 80)<br/>      }<br/>    ))<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_ingress_custom_annotations"></a> [ingress\_custom\_annotations](#input\_ingress\_custom\_annotations) | Istio ingress key-value map to customise your ingress LoadBalaner annotations set. Cannot be empty if var.ingress\_loadbalancer\_type = "other". Default to empty. Null not allowed | `map(string)` | `{}` | no |
| <a name="input_ingress_deployment_name"></a> [ingress\_deployment\_name](#input\_ingress\_deployment\_name) | Optional override for the ingress Deployment name. If null or empty, the value of var.name is used as default. | `string` | `null` | no |
| <a name="input_ingress_discovery_custom_configuration"></a> [ingress\_discovery\_custom\_configuration](#input\_ingress\_discovery\_custom\_configuration) | Map of key-value entries to set custom istio discovery labels. Default to null to autogenerate the labels according to var.istio\_mesh\_enrollment value. For more details about istio discovery configuration refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-sidecar-injection#ossm-about-sidecar-injection_ossm-sidecar-injection and https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.0/html/installing/ossm-deploying-multiple-service-meshes-on-single-cluster. | `map(string)` | `null` | no |
| <a name="input_ingress_enable_proxy_protocol"></a> [ingress\_enable\_proxy\_protocol](#input\_ingress\_enable\_proxy\_protocol) | Flag to enable Proxy Protocol on ingress LoadBalancer (only ALB type) and to enable the EnvoyFilter to implement Proxy Protocol on ingress gateway | `bool` | `false` | no |
| <a name="input_ingress_external_traffic_policy"></a> [ingress\_external\_traffic\_policy](#input\_ingress\_external\_traffic\_policy) | External traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Cluster. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/. | `string` | `"Cluster"` | no |
| <a name="input_ingress_extra_deployment_labels"></a> [ingress\_extra\_deployment\_labels](#input\_ingress\_extra\_deployment\_labels) | Llabel that defines an additional identity for the egress gateway.<br/>This label is applied to:<br/>  - Deployment metadata.labels | `map(string)` | `{}` | no |
| <a name="input_ingress_internal_traffic_policy"></a> [ingress\_internal\_traffic\_policy](#input\_ingress\_internal\_traffic\_policy) | Internal traffic policy configuration for the ingress. Allowed values are Cluster and Local. Default to Local. For more details refer to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/. | `string` | `"Local"` | no |
| <a name="input_ingress_ip_type"></a> [ingress\_ip\_type](#input\_ingress\_ip\_type) | IBM Cloud LoadBalancer IP type: valid values are public and private. Default to public. If var.ingress\_service\_type == "ClusterIP" this value hasn't effect. | `string` | `"public"` | no |
| <a name="input_ingress_loadbalancer_type"></a> [ingress\_loadbalancer\_type](#input\_ingress\_loadbalancer\_type) | IBM Cloud LoadBalancer type bound to the ingress: valid values are "alb" for Application Load Balancer, "nlb" for Network Load Balancer, and "other" to define your LoadBalancer with your custom annotations. If var.ingress\_service\_type == "ClusterIP" this value hasn't effect. For more details refer to https://cloud.ibm.com/docs/vpc?topic=vpc-nlb-vs-elb. Default to ALB. | `string` | `"alb"` | no |
| <a name="input_ingress_nlb_zones_subnets"></a> [ingress\_nlb\_zones\_subnets](#input\_ingress\_nlb\_zones\_subnets) | Map of tuples "subnetID": "VPC zone" to configure IBM Cloud Network LoadBalancer instances on the expected zone and subnet. Null value is not allowed. Default to empty map. | `map(string)` | `{}` | no |
| <a name="input_ingress_pdb_configuration"></a> [ingress\_pdb\_configuration](#input\_ingress\_pdb\_configuration) | Configuration of the PodDisruptionBudget for the istio ingress definition. Default to null to leverage on Istio default configuration. | <pre>object({<br/>    minAvailable   = optional(string, null)<br/>    maxUnavailable = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_ingress_ports"></a> [ingress\_ports](#input\_ingress\_ports) | List of ports to configured on ingress and LoadBalancer to list for inbound traffic. Default to port 443:8443 on TCP. | <pre>list(object(<br/>    {<br/>      port : number,<br/>      name : string,<br/>      protocol : string,<br/>      targetPort : number<br/>    }<br/>  ))</pre> | <pre>[<br/>  {<br/>    "name": "https",<br/>    "port": 443,<br/>    "protocol": "TCP",<br/>    "targetPort": 8443<br/>  }<br/>]</pre> | no |
| <a name="input_ingress_proxy_protocol_allow_without"></a> [ingress\_proxy\_protocol\_allow\_without](#input\_ingress\_proxy\_protocol\_allow\_without) | Flag to support traffic with or without Proxy Protocol on ingress LoadBalancer (only ALB type) and on the EnvoyFilter that implements Proxy Protocol on ingress gateway | `bool` | `false` | no |
| <a name="input_ingress_replicas"></a> [ingress\_replicas](#input\_ingress\_replicas) | Istio ingress deployment replicaset configuration. If the var.ingress\_autoscale\_configuration.enabled is true this value is ignored. Default to 3. | `number` | `3` | no |
| <a name="input_ingress_resources_configuration"></a> [ingress\_resources\_configuration](#input\_ingress\_resources\_configuration) | Istio ingress resources deployment configuration. Default configuration is null and leverages on Istio default setting. | <pre>object(<br/>    {<br/>      limits : optional(object(<br/>        {<br/>          cpu : optional(string, null),<br/>          memory : optional(string, null)<br/>      }), null),<br/>      requests : optional(object(<br/>        {<br/>          cpu : optional(string, null)<br/>          memory : optional(string, null)<br/>      }), null)<br/>    }<br/>  )</pre> | `null` | no |
| <a name="input_ingress_selectors"></a> [ingress\_selectors](#input\_ingress\_selectors) | Istio ingress selectors to route inbound ingress traffic to the expected istio gateway and to the expected workload. Default to "app": "istio-ingress" "istio": "istio-ingress". Null not allowed | `map(string)` | <pre>{<br/>  "app": "istio-ingress",<br/>  "istio": "istio-ingress"<br/>}</pre> | no |
| <a name="input_ingress_service_type"></a> [ingress\_service\_type](#input\_ingress\_service\_type) | Istio ingress type for the service (svc) resource definition: possible values are LoadBalancer and ClusterIP.  Default to LoadBalancer | `string` | `"LoadBalancer"` | no |
| <a name="input_ingress_termination_grace_period"></a> [ingress\_termination\_grace\_period](#input\_ingress\_termination\_grace\_period) | Number of seconds for the Istio ingress deployment for the grace period before terminating the pods and dropping the connections. Default to null to leverage on Istio default. | `number` | `null` | no |
| <a name="input_ingress_tolerations"></a> [ingress\_tolerations](#input\_ingress\_tolerations) | Istio ingress tolerations configuration. Default to tolerate 'dedicated: edge' taint. For more details # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#toleration-v1-core | `list(any)` | `[]` | no |
| <a name="input_ingress_topology_spread_constraints"></a> [ingress\_topology\_spread\_constraints](#input\_ingress\_topology\_spread\_constraints) | List of topologySpreadConstraints to apply to the ingress Deployment(s). See k8s apps/v1 TopologySpreadConstraint schema. | `any` | `null` | no |
| <a name="input_istio_ingress_deployment_timeout"></a> [istio\_ingress\_deployment\_timeout](#input\_istio\_ingress\_deployment\_timeout) | Timeout for the helm release deployment for the ingress gateway | `string` | `null` | no |
| <a name="input_istio_mesh_enrollment"></a> [istio\_mesh\_enrollment](#input\_istio\_mesh\_enrollment) | Name of the Istio mesh controlplane to enroll this dataplane with. Default value to "default". This value is used to generate discovery selectors, to override the computed values customise var.ingress\_discovery\_custom\_configuration. | `string` | `"default"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Istio ingress | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where to install istio ingress dataplane. | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix value to append to the name of the resources. The name of the ingress resources created with this module will be in format of <prefix>-<name>. | `string` | `null` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group for the OpenShift Cluster. | `string` | n/a | yes |
| <a name="input_rollback_on_failure"></a> [rollback\_on\_failure](#input\_rollback\_on\_failure) | Flag to automatically rollback the helm chart on installation failure. | `bool` | `true` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_ingress_loadbalancer_hostname"></a> [ingress\_loadbalancer\_hostname](#output\_ingress\_loadbalancer\_hostname) | Load balancer hostname(s). For ALB: returns map with single hostname. For NLB: returns map of service name to hostname per zone. For other types: returns empty map. |
| <a name="output_ingress_loadbalancer_ips"></a> [ingress\_loadbalancer\_ips](#output\_ingress\_loadbalancer\_ips) | Load balancer IP addresses. For NLB: returns map of service name to IP. For other types: returns map with indexed keys (ip-0, ip-1, etc). Returns empty map for ALB. |
| <a name="output_istio_ingress_metadata"></a> [istio\_ingress\_metadata](#output\_istio\_ingress\_metadata) | Istio ingress helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Understanding Load Balancer Outputs

The module outputs differ based on the `ingress_loadbalancer_type` configuration. This section explains the output format for each load balancer type.

### Application Load Balancer (ALB)

When `ingress_loadbalancer_type = "alb"`, a single Application Load Balancer is created and only the hostname is returned.

**Input Configuration:**
```hcl
ingress_loadbalancer_type = "alb"
ingress_alb_subnets = [
  "0717-efe5c9b5-37e9-48c8-9d2e-a0a0a0a0a0a0",
  "0727-b1f2c3d4-48e9-59d9-0e1f-b1b1b1b1b1b1",
  "0737-c2g3d4e5-59f0-60e0-1f2g-c2c2c2c2c2c2"
]
```

**Output Example:**
```hcl
ingress_loadbalancer_hostname = {
  "public-ingress" = "04a736c5-us-south.lb.appdomain.cloud"
}

ingress_loadbalancer_ips = {}
```

### Network Load Balancer (NLB)

When `ingress_loadbalancer_type = "nlb"`, one Network Load Balancer is created per zone specified in `ingress_nlb_zones_subnets`. Both hostnames and IP addresses are returned for each zone.

**Input Configuration:**
```hcl
ingress_loadbalancer_type = "nlb"
ingress_nlb_zones_subnets = {
  "0717-efe5c9b5-37e9-48c8-9d2e-a0a0a0a0a0a0" = "us-south-1"
  "0727-b1f2c3d4-48e9-59d9-0e1f-b1b1b1b1b1b1" = "us-south-2"
  "0737-c2g3d4e5-59f0-60e0-1f2g-c2c2c2c2c2c2" = "us-south-3"
}
```

**Output Example:**
```hcl
ingress_loadbalancer_hostname = {
  "public-ingress-us-south-1" = "b363a563-us-south.lb.appdomain.cloud"
  "public-ingress-us-south-2" = "e84cfa58-us-south.lb.appdomain.cloud"
  "public-ingress-us-south-3" = "7185448c-us-south.lb.appdomain.cloud"
}

ingress_loadbalancer_ips = {
  "public-ingress-us-south-1" = "52.118.188.140"
  "public-ingress-us-south-2" = "52.118.205.19"
  "public-ingress-us-south-3" = "52.118.102.88"
}
```

### Custom Load Balancer (other)

When `ingress_loadbalancer_type = "other"`, you provide custom annotations via `ingress_custom_annotations`. The module reserves IP addresses in each zone, but does not create hostnames. IPs are indexed sequentially.

**Input Configuration:**
```hcl
ingress_loadbalancer_type = "other"
ingress_custom_annotations = {
  "service.kubernetes.io/ibm-load-balancer-cloud-provider-enable-features" = "service-dnlb"
  "service.kubernetes.io/ibm-load-balancer-cloud-provider-ip-type"         = "private"
  "service.kubernetes.io/ibm-load-balancer-cloud-provider-vpc-node-selector" = "transit"
}
```

**Output Example:**
```hcl
ingress_loadbalancer_hostname = {}

ingress_loadbalancer_ips = {
  "ip-0" = "10.119.60.25"
  "ip-1" = "10.12.129.159"
  "ip-2" = "10.12.130.48"
  "ip-3" = "10.51.208.41"
}
```

**Note:** The number of IPs reserved corresponds to the number of zones used in the cluster. The IPs are not necessarily returned in zone order.
