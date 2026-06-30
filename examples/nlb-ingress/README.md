# NLB Ingress Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=ocp-service-mesh-nlb-ingress-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-ocp-service-mesh/tree/main/examples/nlb-ingress">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example demonstrates deploying an OpenShift cluster with Istio Service Mesh using **NLB (Network Load Balancer)** for ingress traffic across multiple availability zones.

## Key Features

- **Multi-zone NLB deployment**: Creates separate NLB instances in each availability zone
- **Zone-specific HPAs**: Horizontal Pod Autoscalers for each zone's deployment
- **External VPC resources**: Uses pre-existing VPC, subnets, and public gateways
- **Service Mesh**: Full Istio service mesh with ingress and egress gateways
- **Sample application**: Deploys httpbin sample app to test the setup

## Architecture

This example differs from the `advanced` example by:
1. Using **NLB** instead of ALB for load balancing
2. Creating **multiple deployments** (one per zone) for the ingress gateway
3. Creating **multiple services** (one per zone) for the ingress gateway
4. Creating **multiple HPAs** (one per zone) for proper autoscaling
5. Using **external VPC resources** instead of creating them

## Prerequisites

Before running this example, you need to:

1. Create VPC infrastructure using `tests/existing-resources`:
   ```bash
   cd tests/existing-resources
   terraform init
   terraform apply
   ```

2. Capture the outputs:
   ```bash
   terraform output resource_group_id
   terraform output vpc_id
   terraform output cluster_vpc_subnets
   terraform output nlb_zones_subnets
   ```

## Usage

1. Create a `terraform.tfvars` file:
   ```hcl
   ibmcloud_api_key = "your-api-key" # pragma: allowlist secret
   region           = "us-south"
   prefix           = "nlb-test"

   # From tests/existing-resources outputs
   resource_group_id = "abc123def456" # pragma: allowlist secret
   vpc_id            = "r006-xxxxx"

   cluster_vpc_subnets = {
     subnet-1 = [{
       id         = "0717-xxxxx"
       cidr_block = "10.240.0.0/24"
       zone       = "us-south-1"
     }]
     subnet-2 = [{
       id         = "0717-yyyyy"
       cidr_block = "10.240.1.0/24"
       zone       = "us-south-2"
     }]
     subnet-3 = [{
       id         = "0717-zzzzz"
       cidr_block = "10.240.2.0/24"
       zone       = "us-south-3"
     }]
   }

   ingress_nlb_zones_subnets = {
     "0717-xxxxx" = "us-south-1"
     "0717-yyyyy" = "us-south-2"
     "0717-zzzzz" = "us-south-3"
   }
   ```

2. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Access the cluster:
   ```bash
   ibmcloud ks cluster config --cluster $(terraform output -raw cluster_id)
   ```

4. Test the ingress:
   ```bash
   # Get NLB IPs
   terraform output ingress_loadbalancer_ips

   # Test the httpbin service
   curl http://<nlb-ip>/headers
   ```

## What Gets Deployed

### Infrastructure
- OpenShift cluster across 3 zones
- 3 worker pools (one per zone)

### Service Mesh Components
- Istio control plane
- Istio CNI
- **NLB Ingress Gateway** (3 deployments, 3 services, 3 HPAs - one per zone)
- Egress Gateway
- Network policies

### Sample Application
- httpbin application in `httpbin` namespace
- Gateway and VirtualService for routing

## NLB Configuration

The NLB ingress creates:
- **3 Deployments**: `nlb-ingress-us-south-1`, `nlb-ingress-us-south-2`, `nlb-ingress-us-south-3`
- **3 Services**: `nlb-ingress-us-south-1`, `nlb-ingress-us-south-2`, `nlb-ingress-us-south-3`
- **3 HPAs**: `nlb-ingress-us-south-1`, `nlb-ingress-us-south-2`, `nlb-ingress-us-south-3`

Each deployment is pinned to its respective zone using node selectors, ensuring high availability and zone isolation.

## Outputs

- `cluster_id`: OpenShift cluster ID
- `vpc_id`: VPC ID
- `ingress_loadbalancer_hostname`: Map of NLB service names to hostnames
- `ingress_loadbalancer_ips`: Map of NLB service names to IP addresses

## Clean Up

1. Destroy the cluster and service mesh:
   ```bash
   terraform destroy
   ```

2. Optionally destroy the VPC infrastructure:
   ```bash
   cd tests/existing-resources
   terraform destroy
   ```

## Variables

| Name | Description | Type | Required |
|------|-------------|------|----------|
| ibmcloud_api_key | IBM Cloud API key | string | yes |
| region | IBM Cloud region | string | yes |
| resource_group_id | Resource group ID | string | yes |
| vpc_id | Existing VPC ID | string | yes |
| cluster_vpc_subnets | Map of subnet lists | map(list(object)) | yes |
| ingress_nlb_zones_subnets | Map of subnet IDs to zones | map(string) | yes |
| prefix | Resource name prefix | string | no |
| resource_tags | List of tags | list(string) | no |

## Notes

- This example uses NLB which provides better performance and lower latency compared to ALB
- Each zone gets its own NLB instance for better fault isolation
- The cluster spans 3 zones for high availability
- Minimum 1 worker per zone is configured (can be increased for production)
